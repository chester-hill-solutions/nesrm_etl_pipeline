-- RPC temp tables: unique names per call + ON COMMIT DROP only (no DROP TABLE).
-- Synced with amended 20260326120000_contact_household_grouping.sql.
CREATE OR REPLACE FUNCTION public.load_contact_list_page_ids(
  p_contact_ids bigint[],
  p_sort_rules jsonb,
  p_page integer,
  p_page_size integer,
  p_role text DEFAULT NULL,
  p_group_by_household boolean DEFAULT false
)
RETURNS TABLE(contact_id bigint, total_count bigint, household_group_id bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sql text;
  v_joins text := '';
  v_order text := '';
  v_rule jsonb;
  v_idx integer := 0;
  v_column text;
  v_db_column text;
  v_order_dir text;
  v_survey_order text;
  v_survey_id integer;
  v_latest_active_survey_id integer := NULL;
  v_custom_id integer;
  v_custom_type text;
  v_col_exists boolean;
  v_sort_expr text;
  v_sql_full text;
  v_root_id bigint;
  v_uid bigint;
  v_cur bigint;
  v_par bigint;
  v_root_uid bigint;
  v_root_root bigint;
  v_email_bucket record;
  v_phone_bucket record;
  v_addr_bucket record;
  v_licp_uf_id bigint;
  v_offset integer := GREATEST((COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 25), 0);
  v_limit integer := GREATEST(COALESCE(p_page_size, 25), 1);
  v_sfx text;
  v_t_ord text;
  v_t_keys text;
  v_t_uf text;
  v_t_gm text;
BEGIN
  IF p_contact_ids IS NULL OR cardinality(p_contact_ids) = 0 THEN
    RETURN;
  END IF;

  FOR v_rule IN
    SELECT value
    FROM jsonb_array_elements(COALESCE(p_sort_rules, '[]'::jsonb))
  LOOP
    v_idx := v_idx + 1;
    v_column := COALESCE(v_rule->>'column', '');
    v_order_dir := lower(COALESCE(v_rule->>'order', 'asc'));
    IF v_order_dir NOT IN ('asc', 'desc') THEN
      v_order_dir := 'asc';
    END IF;

    IF v_column = 'survey_status' THEN
      v_survey_order := v_rule->>'surveyStatusOrder';
      IF v_survey_order NOT IN ('completed_first', 'in_progress_first', 'not_started_first') THEN
        v_survey_order := NULL;
      END IF;

      v_survey_id := NULLIF(v_rule->>'surveyId', '')::integer;
      IF v_survey_id IS NULL OR v_survey_id <= 0 THEN
        IF v_latest_active_survey_id IS NULL THEN
          SELECT s.id
          INTO v_latest_active_survey_id
          FROM public.surveys s
          WHERE s.status = 'active'
            AND s.archived = false
          ORDER BY s.id DESC
          LIMIT 1;
        END IF;
        v_survey_id := COALESCE(v_latest_active_survey_id, 0);
      END IF;

      v_joins := v_joins || format(
        ' LEFT JOIN LATERAL (
            SELECT
              CASE
                WHEN $4 IS NOT NULL
                  AND NOT (
                    s.visible_to_roles IS NULL
                    OR jsonb_typeof(s.visible_to_roles) <> ''array''
                    OR jsonb_array_length(s.visible_to_roles) = 0
                    OR s.visible_to_roles ? $4
                  )
                  THEN ''completed''
                WHEN $4 IS NOT NULL
                  AND s.contact_restrictions IS NOT NULL
                  AND jsonb_typeof(s.contact_restrictions) = ''object''
                  AND EXISTS (
                    SELECT 1
                    FROM jsonb_each(s.contact_restrictions) AS e(field_name, restriction)
                    WHERE (to_jsonb(b)->>e.field_name) = (restriction->>''value'')
                      AND NOT (COALESCE(restriction->''allowedRoles'', ''[]''::jsonb) ? $4)
                  )
                  THEN ''completed''
                ELSE COALESCE((
                  SELECT sr.status
                  FROM public.survey_responses sr
                  WHERE sr.contact_id = b.id
                    AND sr.survey_id = %s
                    AND sr.status IN (''in_progress'', ''completed'')
                  ORDER BY sr.created_at DESC
                  LIMIT 1
                ), ''not_started'')
              END AS status
            FROM public.surveys s
            WHERE s.id = %s
          ) ss_%s ON true',
        v_survey_id,
        v_survey_id,
        v_idx
      );

      v_sort_expr := CASE COALESCE(v_survey_order, 'completed_first')
        WHEN 'not_started_first' THEN
          format(
            '(CASE ss_%s.status
               WHEN ''not_started'' THEN 0
               WHEN ''in_progress'' THEN 1
               ELSE 2
             END)',
            v_idx
          )
        WHEN 'in_progress_first' THEN
          format(
            '(CASE ss_%s.status
               WHEN ''in_progress'' THEN 0
               WHEN ''completed'' THEN 1
               ELSE 2
             END)',
            v_idx
          )
        ELSE
          format(
            '(CASE ss_%s.status
               WHEN ''completed'' THEN 0
               WHEN ''not_started'' THEN 1
               ELSE 2
             END)',
            v_idx
          )
      END;

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;

      IF v_survey_order IS NOT NULL THEN
        v_order := v_order || v_sort_expr || ' ASC';
      ELSE
        v_order := v_order || v_sort_expr || ' ' || upper(v_order_dir);
      END IF;

      CONTINUE;
    END IF;

    IF v_column = 'last_request' THEN
      v_joins := v_joins || format(
        ' LEFT JOIN LATERAL (
            SELECT r.created_at
            FROM public.request r
            WHERE r.id = b.last_request
            LIMIT 1
          ) lr_%s ON true',
        v_idx
      );

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'lr_%s.created_at %s NULLS %s',
        v_idx,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    END IF;

    v_custom_id := NULL;
    v_custom_type := NULL;

    IF v_column LIKE 'custom_%' THEN
      v_custom_id := NULLIF(regexp_replace(v_column, '^custom_', ''), '')::integer;
      IF v_custom_id IS NOT NULL AND v_custom_id > 0 THEN
        SELECT c.data_type
        INTO v_custom_type
        FROM public.custom_columns c
        WHERE c.id = v_custom_id
        LIMIT 1;
      END IF;
    ELSE
      SELECT c.id, c.data_type
      INTO v_custom_id, v_custom_type
      FROM public.custom_columns c
      WHERE c.name = v_column
      LIMIT 1;
    END IF;

    IF v_custom_id IS NOT NULL AND v_custom_type IS NOT NULL THEN
      v_joins := v_joins || format(
        ' LEFT JOIN LATERAL (
            SELECT
              qcf.value_text,
              qcf.value_number,
              qcf.value_boolean,
              qcf.value_date
            FROM public.contact_queryable_custom_fields qcf
            WHERE qcf.contact_id = b.id
              AND qcf.column_id = %s
            LIMIT 1
          ) cf_%s ON true',
        v_custom_id,
        v_idx
      );

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;

      v_sort_expr := CASE v_custom_type
        WHEN 'number' THEN format('cf_%s.value_number', v_idx)
        WHEN 'boolean' THEN format('cf_%s.value_boolean', v_idx)
        WHEN 'date' THEN format('cf_%s.value_date', v_idx)
        ELSE format('cf_%s.value_text', v_idx)
      END;

      v_order := v_order || format(
        '%s %s NULLS %s',
        v_sort_expr,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    END IF;

    v_db_column := v_column;
    IF v_column = 'name' THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'b.surname %s NULLS %s, b.firstname %s NULLS %s',
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    ELSIF v_column = 'dob' THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'b.birthyear %s NULLS %s, b.birthmonth %s NULLS %s, b.birthdate %s NULLS %s',
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    ELSIF v_column = 'street_address' THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'b.street_name_sort_key %s NULLS %s',
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    END IF;

    v_col_exists := v_db_column = ANY(
      ARRAY[
        'id',
        'created_at',
        'updated_at',
        'firstname',
        'surname',
        'email',
        'phone',
        'birthdate',
        'birthmonth',
        'birthyear',
        'street_address',
        'municipality',
        'division',
        'region',
        'country',
        'postcode',
        'federal_electoral_district',
        'division_electoral_district',
        'municipal_electoral_district',
        'ballot1',
        'ballot2',
        'ballot3',
        'ballot4',
        'comms_consent',
        'signup_consent',
        'signup_submitted',
        'member',
        'organizer',
        'language',
        'olp23_ballot1',
        'olp23_ballot2',
        'olp23_ballot3',
        'olp23_ballot4',
        'olp23_comms_consent',
        'olp23_signup_consent',
        'olp23_volunteer_status',
        'olp23_donor_status',
        'olp23_donation_amount',
        'olp23_signup_submitted',
        'olp23_organizer',
        'olp23_source',
        'olp23_member',
        'olp23_voted',
        'olp23_voting_group',
        'olp23_voting_location',
        'olp23_voting_period',
        'olp23_voting_association',
        'olp23_nate_signup',
        'olp23_campus_club',
        'olp23_callhub_notes',
        'olp23_nes_support_level',
        'olp23_gender',
        'olp23_riding',
        'olp23_organizer_ref_id',
        'olp23_membership_status',
        'olp_van_id',
        'lpc_van_id',
        'last_request',
        'tags',
        'gender',
        'mailerlite_id',
        'campus_club',
        'ride_request_status',
        'contact_status',
        'latitude',
        'longitude',
        'location',
        'research_data',
        'research_updated_at',
        'research_status',
        'organizer_codes',
        'submission_confirmed',
        'womens_club',
        'ssw_ballot1'
      ]::text[]
    );

    IF v_col_exists THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'b.%I %s NULLS %s',
        v_db_column,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
    END IF;
  END LOOP;

  IF v_order = '' THEN
    v_order := 'b.id ASC';
  ELSE
    v_order := v_order || ', b.id ASC';
  END IF;

  IF NOT COALESCE(p_group_by_household, false) THEN
    v_sql := '
    WITH base AS (
      SELECT c.*
      FROM public.contact c
      WHERE c.id = ANY($1::bigint[])
        AND (c.contact_status IS NULL OR c.contact_status <> ''archived'')
    ),
    ordered AS (
      SELECT
        b.id AS contact_id,
        COUNT(*) OVER() AS total_count
      FROM base b
      ' || v_joins || '
      ORDER BY ' || v_order || '
    )
    SELECT o.contact_id, o.total_count, NULL::bigint AS household_group_id
    FROM ordered o
    LIMIT $2
    OFFSET $3
  ';

    RETURN QUERY EXECUTE v_sql USING p_contact_ids, v_limit, v_offset, p_role;
    RETURN;
  END IF;

  -- Household grouping: full sorted candidate list, cluster by email/phone/address keys, then paginate.
  v_sql_full := replace(
    '
    WITH base AS (
      SELECT c.*
      FROM public.contact c
      WHERE c.id = ANY($1::bigint[])
        AND (c.contact_status IS NULL OR c.contact_status <> ''archived'')
    ),
    ordered AS (
      SELECT
        b.id AS contact_id,
        COUNT(*) OVER() AS total_count,
        ROW_NUMBER() OVER (ORDER BY ' || v_order || ') AS seq
      FROM base b
      ' || v_joins || '
    )
    SELECT contact_id, total_count, seq FROM ordered
  ',
    '$4',
    '$2'
  );

  -- Unique names per call avoid DROP TABLE (same txn can invoke this RPC more than once).
  v_sfx := replace(gen_random_uuid()::text, '-', '_');
  v_t_ord := 'licp_ord_' || v_sfx;
  v_t_keys := 'licp_keys_' || v_sfx;
  v_t_uf := 'licp_uf_' || v_sfx;
  v_t_gm := 'licp_gm_' || v_sfx;

  EXECUTE format('CREATE TEMP TABLE %I ON COMMIT DROP AS %s', v_t_ord, v_sql_full)
  USING p_contact_ids, p_role;

  EXECUTE format(
    'CREATE TEMP TABLE %I ON COMMIT DROP AS '
    'SELECT o.contact_id, '
    'public.contact_household_email_key(c.email) AS email_k, '
    'public.contact_household_phone_key(c.phone) AS phone_k, '
    'public.contact_household_address_key(c.street_address, c.municipality, c.postcode) AS addr_k, '
    'o.seq, o.total_count '
    'FROM %I o '
    'JOIN public.contact c ON c.id = o.contact_id',
    v_t_keys,
    v_t_ord
  );

  EXECUTE format(
    'CREATE TEMP TABLE %I (id bigint PRIMARY KEY, parent bigint) ON COMMIT DROP',
    v_t_uf
  );
  EXECUTE format(
    'INSERT INTO %I SELECT contact_id, contact_id FROM %I',
    v_t_uf,
    v_t_keys
  );

  -- Union by shared email key (transitive via repeated bucket passes for phone/address).
  FOR v_email_bucket IN
    EXECUTE format(
      'SELECT k.email_k AS ek FROM %I k WHERE k.email_k IS NOT NULL GROUP BY k.email_k HAVING COUNT(*) > 1',
      v_t_keys
    )
  LOOP
    EXECUTE format('SELECT MIN(k2.contact_id) FROM %I k2 WHERE k2.email_k = $1', v_t_keys)
    INTO v_root_id
    USING v_email_bucket.ek;

    FOR v_uid IN
      EXECUTE format(
        'SELECT k3.contact_id FROM %I k3 WHERE k3.email_k = $1',
        v_t_keys
      )
      USING v_email_bucket.ek
    LOOP
      v_cur := v_uid;
      LOOP
        EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
        EXIT WHEN v_par = v_cur;
        v_cur := v_par;
      END LOOP;
      v_root_uid := v_cur;

      v_cur := v_root_id;
      LOOP
        EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
        EXIT WHEN v_par = v_cur;
        v_cur := v_par;
      END LOOP;
      v_root_root := v_cur;

      IF v_root_uid = v_root_root THEN
        CONTINUE;
      END IF;

      IF v_root_uid < v_root_root THEN
        EXECUTE format('UPDATE %I SET parent = $1 WHERE id = $2', v_t_uf) USING v_root_uid, v_root_root;
      ELSE
        EXECUTE format('UPDATE %I SET parent = $1 WHERE id = $2', v_t_uf) USING v_root_root, v_root_uid;
      END IF;
    END LOOP;
  END LOOP;

  FOR v_phone_bucket IN
    EXECUTE format(
      'SELECT k.phone_k AS pk FROM %I k WHERE k.phone_k IS NOT NULL GROUP BY k.phone_k HAVING COUNT(*) > 1',
      v_t_keys
    )
  LOOP
    EXECUTE format('SELECT MIN(k2.contact_id) FROM %I k2 WHERE k2.phone_k = $1', v_t_keys)
    INTO v_root_id
    USING v_phone_bucket.pk;

    FOR v_uid IN
      EXECUTE format(
        'SELECT k3.contact_id FROM %I k3 WHERE k3.phone_k = $1',
        v_t_keys
      )
      USING v_phone_bucket.pk
    LOOP
      v_cur := v_uid;
      LOOP
        EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
        EXIT WHEN v_par = v_cur;
        v_cur := v_par;
      END LOOP;
      v_root_uid := v_cur;

      v_cur := v_root_id;
      LOOP
        EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
        EXIT WHEN v_par = v_cur;
        v_cur := v_par;
      END LOOP;
      v_root_root := v_cur;

      IF v_root_uid = v_root_root THEN
        CONTINUE;
      END IF;

      IF v_root_uid < v_root_root THEN
        EXECUTE format('UPDATE %I SET parent = $1 WHERE id = $2', v_t_uf) USING v_root_uid, v_root_root;
      ELSE
        EXECUTE format('UPDATE %I SET parent = $1 WHERE id = $2', v_t_uf) USING v_root_root, v_root_uid;
      END IF;
    END LOOP;
  END LOOP;

  FOR v_addr_bucket IN
    EXECUTE format(
      'SELECT k.addr_k AS ak FROM %I k WHERE k.addr_k IS NOT NULL GROUP BY k.addr_k HAVING COUNT(*) > 1',
      v_t_keys
    )
  LOOP
    EXECUTE format('SELECT MIN(k2.contact_id) FROM %I k2 WHERE k2.addr_k = $1', v_t_keys)
    INTO v_root_id
    USING v_addr_bucket.ak;

    FOR v_uid IN
      EXECUTE format(
        'SELECT k3.contact_id FROM %I k3 WHERE k3.addr_k = $1',
        v_t_keys
      )
      USING v_addr_bucket.ak
    LOOP
      v_cur := v_uid;
      LOOP
        EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
        EXIT WHEN v_par = v_cur;
        v_cur := v_par;
      END LOOP;
      v_root_uid := v_cur;

      v_cur := v_root_id;
      LOOP
        EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
        EXIT WHEN v_par = v_cur;
        v_cur := v_par;
      END LOOP;
      v_root_root := v_cur;

      IF v_root_uid = v_root_root THEN
        CONTINUE;
      END IF;

      IF v_root_uid < v_root_root THEN
        EXECUTE format('UPDATE %I SET parent = $1 WHERE id = $2', v_t_uf) USING v_root_uid, v_root_root;
      ELSE
        EXECUTE format('UPDATE %I SET parent = $1 WHERE id = $2', v_t_uf) USING v_root_root, v_root_uid;
      END IF;
    END LOOP;
  END LOOP;

  EXECUTE format('ALTER TABLE %I ADD COLUMN root_key bigint', v_t_uf);

  FOR v_licp_uf_id IN EXECUTE format('SELECT id FROM %I ORDER BY id', v_t_uf)
  LOOP
    v_cur := v_licp_uf_id;
    LOOP
      EXECUTE format('SELECT parent FROM %I WHERE id = $1', v_t_uf) INTO v_par USING v_cur;
      EXIT WHEN v_par = v_cur;
      v_cur := v_par;
    END LOOP;
    EXECUTE format('UPDATE %I SET root_key = $1 WHERE id = $2', v_t_uf) USING v_cur, v_licp_uf_id;
  END LOOP;

  EXECUTE format(
    'CREATE TEMP TABLE %I ON COMMIT DROP AS '
    'SELECT u.root_key AS rk, MIN(k.seq) AS min_seq '
    'FROM %I k JOIN %I u ON u.id = k.contact_id GROUP BY u.root_key',
    v_t_gm,
    v_t_keys,
    v_t_uf
  );

  RETURN QUERY EXECUTE format(
    'SELECT k.contact_id, k.total_count, u.root_key AS household_group_id '
    'FROM %I k JOIN %I u ON u.id = k.contact_id JOIN %I g ON g.rk = u.root_key '
    'ORDER BY g.min_seq, k.seq LIMIT $1 OFFSET $2',
    v_t_keys,
    v_t_uf,
    v_t_gm
  ) USING v_limit, v_offset;
END;
$$;

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_page_payload_optimized(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_sort_rules jsonb,
  p_search_term text,
  p_page integer,
  p_page_size integer,
  p_include_unanswered_status boolean DEFAULT true,
  p_include_button_state boolean DEFAULT true,
  p_include_pending_suggestions boolean DEFAULT true,
  p_group_by_household boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
VOLATILE
SET search_path = public
AS $$
DECLARE
  v_has_filter boolean;
  v_search_esc text;
  v_email_mode boolean;
  v_page_num integer;
  v_limit integer;
  v_candidate_ids bigint[];
  v_page_ids bigint[];
  v_total_count bigint := 0;
  v_contacts jsonb;
  v_unanswered jsonb := '{}'::jsonb;
  v_button_colour jsonb := '{}'::jsonb;
  v_button_survey_id jsonb := '{}'::jsonb;
  v_pending_suggestions jsonb := '{}'::jsonb;
  v_latest_survey_id integer;
  v_t_dash_ord text;
BEGIN
  v_page_num := GREATEST(COALESCE(p_page, 1), 1);
  v_limit := GREATEST(COALESCE(p_page_size, 25), 1);
  v_has_filter :=
    p_filter_group IS NOT NULL
    AND jsonb_typeof(p_filter_group) = 'object'
    AND (p_filter_group->'children') IS NOT NULL
    AND jsonb_array_length(p_filter_group->'children') > 0;

  IF p_search_term IS NOT NULL AND TRIM(p_search_term) <> '' THEN
    v_search_esc := public.escape_search_for_ilike(TRIM(p_search_term));
    v_email_mode := (position('@' IN TRIM(p_search_term)) > 0);
  ELSE
    v_search_esc := NULL;
    v_email_mode := false;
  END IF;

  WITH scoped_ids AS (
    SELECT c.id
    FROM public.contact c
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        (COALESCE(TRIM(p_scope_type), 'all_contacts') = 'all_contacts' AND (p_scope_values IS NULL OR cardinality(p_scope_values) = 0))
        OR (p_scope_type = 'riding' AND p_scope_values IS NOT NULL AND cardinality(p_scope_values) > 0 AND c.division_electoral_district = ANY(p_scope_values))
        OR (p_scope_type = 'campus' AND p_scope_values IS NOT NULL AND cardinality(p_scope_values) > 0 AND c.campus_club = ANY(p_scope_values))
        OR (p_scope_type = 'signups' AND p_scope_values IS NOT NULL AND cardinality(p_scope_values) > 0 AND (
          EXISTS (
            SELECT 1
            FROM unnest(regexp_split_to_array(lower(COALESCE(c.organizer, '')), '[^a-z0-9_-]+')) AS t(token)
            WHERE TRIM(t.token) <> ''
              AND TRIM(t.token) IN (
                SELECT lower(TRIM(x)) FROM unnest(p_scope_values) AS x WHERE TRIM(x) <> ''
              )
          )
        ))
      )
  ),
  filtered_ids AS (
    SELECT s.id
    FROM scoped_ids s
    WHERE NOT v_has_filter
      OR EXISTS (
        SELECT 1
        FROM public.resolve_filter_group(p_filter_group) AS f(id)
        WHERE f.id = s.id
      )
  ),
  searched_ids AS (
    SELECT f.id
    FROM filtered_ids f
    JOIN public.contact c ON c.id = f.id
    WHERE p_search_term IS NULL
      OR TRIM(p_search_term) = ''
      OR (
        (v_email_mode AND c.email ILIKE '%' || v_search_esc || '%')
        OR (
          NOT v_email_mode
          AND (
            (
              position(' ' IN v_search_esc) > 0
              AND c.firstname ILIKE '%' || TRIM(split_part(v_search_esc, ' ', 1)) || '%'
              AND c.surname ILIKE '%' || TRIM(
                substring(v_search_esc FROM position(' ' IN v_search_esc))
              ) || '%'
            )
            OR c.phone ILIKE '%' || v_search_esc || '%'
            OR c.street_address ILIKE '%' || v_search_esc || '%'
            OR c.municipality ILIKE '%' || v_search_esc || '%'
            OR c.division ILIKE '%' || v_search_esc || '%'
            OR c.region ILIKE '%' || v_search_esc || '%'
            OR c.country ILIKE '%' || v_search_esc || '%'
            OR c.postcode ILIKE '%' || v_search_esc || '%'
            OR (
              (position(' ' IN v_search_esc) = 0 OR position(' ' IN v_search_esc) IS NULL)
              AND (
                c.firstname ILIKE '%' || v_search_esc || '%'
                OR c.surname ILIKE '%' || v_search_esc || '%'
              )
            )
          )
        )
      )
  ),
  total_count AS (
    SELECT COUNT(*)::bigint AS count
    FROM searched_ids
  ),
  limited_ids AS (
    SELECT s.id
    FROM searched_ids s
    ORDER BY s.id
    LIMIT 10000
  )
  SELECT
    (SELECT array_agg(id ORDER BY id) FROM limited_ids),
    (SELECT count FROM total_count)
  INTO v_candidate_ids, v_total_count;

  IF v_total_count IS NULL THEN
    v_total_count := 0;
  END IF;

  IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
    RETURN jsonb_build_object(
      'contacts', '[]'::jsonb,
      'total_count', v_total_count,
      'unanswered_status', v_unanswered,
      'contact_survey_button_colour', v_button_colour,
      'contact_survey_button_survey_id', v_button_survey_id,
      'pending_suggestions_by_contact', v_pending_suggestions
    );
  END IF;

  v_t_dash_ord := 'dash_ord_' || replace(gen_random_uuid()::text, '-', '_');
  EXECUTE format(
    'CREATE TEMP TABLE %I ON COMMIT DROP AS '
    'SELECT o.contact_id, o.household_group_id, row_number() OVER () AS rn '
    'FROM public.load_contact_list_page_ids($1, $2, $3, $4, $5, $6) o',
    v_t_dash_ord
  ) USING v_candidate_ids, COALESCE(p_sort_rules, '[]'::jsonb), v_page_num, v_limit, p_role, COALESCE(p_group_by_household, false);

  EXECUTE format(
    'SELECT COALESCE(array_agg(contact_id ORDER BY rn), ARRAY[]::bigint[]) FROM %I',
    v_t_dash_ord
  ) INTO v_page_ids;

  IF v_page_ids IS NULL THEN
    v_page_ids := ARRAY[]::bigint[];
  END IF;

  EXECUTE format(
    'SELECT COALESCE('
    'jsonb_agg('
    '(row_to_json(c)::jsonb) '
    '|| CASE '
    'WHEN p.household_group_id IS NULL THEN ''{}''::jsonb '
    'ELSE jsonb_build_object(''household_group_id'', to_jsonb(p.household_group_id)) '
    'END '
    'ORDER BY p.rn'
    '), ''[]''::jsonb) '
    'FROM %I p JOIN public.contact c ON c.id = p.contact_id',
    v_t_dash_ord
  ) INTO v_contacts;
  IF v_contacts IS NULL THEN
    v_contacts := '[]'::jsonb;
  END IF;

  IF cardinality(v_page_ids) > 0 THEN
    IF p_include_unanswered_status THEN
      SELECT s.id
      INTO v_latest_survey_id
      FROM public.surveys s
      WHERE s.status = 'active'
        AND s.archived = false
      ORDER BY s.id DESC
      LIMIT 1;

      IF v_latest_survey_id IS NOT NULL THEN
        SELECT jsonb_object_agg(sub.contact_id::text, sub.status) INTO v_unanswered
        FROM (
          SELECT DISTINCT ON (sr.contact_id)
            sr.contact_id,
            CASE
              WHEN sr.status = 'in_progress' THEN 'in_progress'
              WHEN sr.status = 'completed' THEN 'completed'
              ELSE 'not_started'
            END AS status
          FROM public.survey_responses sr
          WHERE sr.contact_id = ANY(v_page_ids)
            AND sr.survey_id = v_latest_survey_id
            AND sr.status IN ('in_progress', 'completed')
          ORDER BY sr.contact_id, sr.created_at DESC
        ) sub;
        IF v_unanswered IS NULL THEN
          v_unanswered := '{}'::jsonb;
        END IF;
        v_unanswered := (
          SELECT jsonb_object_agg(n::text, COALESCE(v_unanswered->>n::text, 'not_started'))
          FROM unnest(v_page_ids) n
        );
        IF v_unanswered IS NULL THEN
          v_unanswered := '{}'::jsonb;
        END IF;
      END IF;
    END IF;

    IF p_include_button_state THEN
      WITH colour_survey AS (
        SELECT
          s.id,
          COALESCE((s.settings->'buttonDisplay'->>'colour'), 'pink') AS colour
        FROM public.surveys s
        WHERE s.status = 'active'
          AND s.archived = false
          AND COALESCE((s.settings->'buttonDisplay'->>'coloursButton')::boolean, false) = true
        ORDER BY COALESCE((s.settings->'buttonDisplay'->>'priority')::int, 0), s.id
        LIMIT 1
      ),
      latest_survey AS (
        SELECT id
        FROM public.surveys
        WHERE status = 'active'
          AND archived = false
        ORDER BY id DESC
        LIMIT 1
      ),
      survey_to_use AS (
        SELECT id, colour FROM colour_survey
        UNION ALL
        SELECT l.id, 'pink'
        FROM latest_survey l
        WHERE NOT EXISTS (SELECT 1 FROM colour_survey)
      )
      SELECT
        (
          SELECT jsonb_object_agg(x.cid::text, y.colour)
          FROM (SELECT unnest(v_page_ids) AS cid) x,
               (SELECT colour FROM survey_to_use LIMIT 1) y
        ),
        (
          SELECT jsonb_object_agg(x.cid::text, y.id)
          FROM (SELECT unnest(v_page_ids) AS cid) x,
               (SELECT id FROM survey_to_use LIMIT 1) y
        )
      INTO v_button_colour, v_button_survey_id;

      IF v_button_colour IS NULL THEN
        v_button_colour := '{}'::jsonb;
      END IF;
      IF v_button_survey_id IS NULL THEN
        v_button_survey_id := '{}'::jsonb;
      END IF;
    END IF;

    IF p_include_pending_suggestions THEN
      SELECT jsonb_object_agg(entity_id::text, field_names) INTO v_pending_suggestions
      FROM (
        SELECT fs.entity_id, jsonb_agg(fs.field_name) AS field_names
        FROM public.field_suggestions fs
        WHERE fs.entity_type = 'contact'
          AND fs.entity_id = ANY(v_page_ids)
          AND fs.status = 'pending'
        GROUP BY fs.entity_id
      ) sub;
      IF v_pending_suggestions IS NULL THEN
        v_pending_suggestions := '{}'::jsonb;
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'contacts', v_contacts,
    'total_count', v_total_count,
    'unanswered_status', v_unanswered,
    'contact_survey_button_colour', v_button_colour,
    'contact_survey_button_survey_id', v_button_survey_id,
    'pending_suggestions_by_contact', v_pending_suggestions
  );
END;
$$;
