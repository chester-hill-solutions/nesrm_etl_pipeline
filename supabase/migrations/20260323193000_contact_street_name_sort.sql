-- Street Address column sorts by street name: strip leading civic number (incl. fractions and ranges).
-- Adds generated column for PostgREST ORDER BY and reuses the same expression in load_contact_list_page_ids.

CREATE OR REPLACE FUNCTION public.contact_street_name_sort_key(p_street text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
PARALLEL SAFE
SET search_path = public
AS $func$
  SELECT CASE
    WHEN trim(p_street) = ''::text THEN NULL::text
    ELSE (
      SELECT CASE
        WHEN s.r = ''::text OR s.r ~ '^[0-9]+$'::text THEN NULL::text
        ELSE s.r
      END
      FROM (
        SELECT trim(
          regexp_replace(
            trim(p_street),
            '^(?:[0-9]+[[:space:]]*/[[:space:]]*[0-9]+|[0-9]+[A-Za-z]?(?:[[:space:]]*-[[:space:]]*[0-9]+)?)[[:space:]]+'::text,
            ''::text,
            ''::text
          )
        ) AS r
      ) s
    )
  END;
$func$;

COMMENT ON FUNCTION public.contact_street_name_sort_key(text) IS
  'Sort key derived from street_address: trims leading civic number (e.g. 123, 12-14, 1/2) so lists order by street name.';

ALTER TABLE public.contact
ADD COLUMN IF NOT EXISTS street_name_sort_key text
GENERATED ALWAYS AS (public.contact_street_name_sort_key(street_address)) STORED;

COMMENT ON COLUMN public.contact.street_name_sort_key IS
  'Generated: street_address with leading civic number removed; used for contact table sorting.';

CREATE OR REPLACE FUNCTION public.load_contact_list_page_ids(
  p_contact_ids bigint[],
  p_sort_rules jsonb,
  p_page integer,
  p_page_size integer,
  p_role text DEFAULT NULL
)
RETURNS TABLE(contact_id bigint, total_count bigint)
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
  v_offset integer := GREATEST((COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 25), 0);
  v_limit integer := GREATEST(COALESCE(p_page_size, 25), 1);
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
    SELECT o.contact_id, o.total_count
    FROM ordered o
    LIMIT $2
    OFFSET $3
  ';

  RETURN QUERY EXECUTE v_sql USING p_contact_ids, v_limit, v_offset, p_role;
END;
$$;

COMMENT ON FUNCTION public.load_contact_list_page_ids(bigint[], jsonb, integer, integer, text) IS
  'Returns ordered contact IDs and total_count for a pre-filtered contact ID set using server-side sort rules (survey_status, standard columns, stored custom columns, and queryable computed custom columns). Survey visibility and contact restrictions are applied when p_role is provided.';
