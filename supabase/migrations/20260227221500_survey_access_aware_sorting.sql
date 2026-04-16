-- Make survey_status sorting respect survey visibility + contact restrictions.
-- This ensures survey-derived status/sorting only applies when the user can access the survey.

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

    IF v_column LIKE 'custom_%' THEN
      v_custom_id := NULLIF(regexp_replace(v_column, '^custom_', ''), '')::integer;
      IF v_custom_id IS NULL OR v_custom_id <= 0 THEN
        CONTINUE;
      END IF;

      SELECT c.data_type
      INTO v_custom_type
      FROM public.custom_columns c
      WHERE c.id = v_custom_id
      LIMIT 1;

      IF v_custom_type IS NULL THEN
        CONTINUE;
      END IF;

      v_joins := v_joins || format(
        ' LEFT JOIN LATERAL (
            SELECT
              COALESCE(value_text, value_number::text, value_boolean::text, value_date::text) AS value
            FROM public.contact_custom_fields cf
            WHERE cf.contact_id = b.id
              AND cf.column_id = %s
            LIMIT 1
          ) cf_%s ON true',
        v_custom_id,
        v_idx
      );

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'cf_%s.value %s NULLS %s',
        v_idx,
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
    END IF;

    SELECT EXISTS (
      SELECT 1
      FROM information_schema.columns c
      WHERE c.table_schema = 'public'
        AND c.table_name = 'contact'
        AND c.column_name = v_db_column
    )
    INTO v_col_exists;

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
  'Returns ordered contact IDs and total_count for a pre-filtered contact ID set using server-side sort rules (survey_status, custom columns, last_request by FK request.created_at, and standard columns). Survey visibility and contact restrictions are applied when p_role is provided.';

-- Fix: signups scope organizer matching must be token-exact (no substring match).
-- Prevents collisions like `MariahB` matching `MariahBrown`.
-- Updated: pass p_role into load_contact_list_page_ids for access-aware survey_status sorting.

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_page_payload(
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
  p_include_pending_suggestions boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_candidate_ids bigint[];
  v_filtered_ids bigint[];
  v_has_filter boolean;
  v_search_esc text;
  v_email_mode boolean;
  v_page_num integer;
  v_limit integer;
  v_page_ids bigint[];
  v_total_count bigint := 0;
  v_contacts jsonb;
  v_unanswered jsonb := '{}'::jsonb;
  v_button_colour jsonb := '{}'::jsonb;
  v_button_survey_id jsonb := '{}'::jsonb;
  v_pending_suggestions jsonb := '{}'::jsonb;
  v_latest_survey_id integer;
  v_page_rec record;
BEGIN
  v_page_num := GREATEST(COALESCE(p_page, 1), 1);
  v_limit := GREATEST(COALESCE(p_page_size, 25), 1);

  SELECT array_agg(c.id)
  INTO v_candidate_ids
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
    );

  IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
    RETURN jsonb_build_object('contacts', '[]'::jsonb, 'total_count', 0, 'unanswered_status', v_unanswered, 'contact_survey_button_colour', v_button_colour, 'contact_survey_button_survey_id', v_button_survey_id, 'pending_suggestions_by_contact', v_pending_suggestions);
  END IF;

  v_has_filter := p_filter_group IS NOT NULL AND jsonb_typeof(p_filter_group) = 'object' AND (p_filter_group->'children') IS NOT NULL AND jsonb_array_length(p_filter_group->'children') > 0;
  IF v_has_filter THEN
    v_filtered_ids := ARRAY(SELECT unnest(v_candidate_ids) INTERSECT SELECT * FROM public.resolve_filter_group(p_filter_group));
    v_candidate_ids := v_filtered_ids;
    IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
      RETURN jsonb_build_object('contacts', '[]'::jsonb, 'total_count', 0, 'unanswered_status', v_unanswered, 'contact_survey_button_colour', v_button_colour, 'contact_survey_button_survey_id', v_button_survey_id, 'pending_suggestions_by_contact', v_pending_suggestions);
    END IF;
  END IF;

  IF p_search_term IS NOT NULL AND TRIM(p_search_term) <> '' THEN
    v_search_esc := public.escape_search_for_ilike(TRIM(p_search_term));
    v_email_mode := (position('@' IN TRIM(p_search_term)) > 0);
    v_filtered_ids := (
      SELECT array_agg(c.id)
      FROM public.contact c
      WHERE c.id = ANY(v_candidate_ids)
        AND (
          (v_email_mode AND c.email ILIKE '%' || v_search_esc || '%')
          OR (NOT v_email_mode AND position(' ' IN v_search_esc) > 0 AND c.firstname ILIKE '%' || TRIM(split_part(v_search_esc, ' ', 1)) || '%' AND c.surname ILIKE '%' || TRIM(substring(v_search_esc FROM position(' ' IN v_search_esc))) || '%')
          OR (NOT v_email_mode AND (position(' ' IN v_search_esc) = 0 OR position(' ' IN v_search_esc) IS NULL) AND (c.firstname ILIKE '%' || v_search_esc || '%' OR c.surname ILIKE '%' || v_search_esc || '%'))
        )
    );
    v_candidate_ids := v_filtered_ids;
    IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
      RETURN jsonb_build_object('contacts', '[]'::jsonb, 'total_count', 0, 'unanswered_status', v_unanswered, 'contact_survey_button_colour', v_button_colour, 'contact_survey_button_survey_id', v_button_survey_id, 'pending_suggestions_by_contact', v_pending_suggestions);
    END IF;
  END IF;

  IF cardinality(v_candidate_ids) > 10000 THEN
    SELECT array_agg(id ORDER BY id) INTO v_candidate_ids FROM (SELECT unnest(v_candidate_ids) AS id ORDER BY id LIMIT 10000) sub;
  END IF;

  WITH ordered AS (
    SELECT o.contact_id, o.total_count, row_number() OVER () AS rn
    FROM public.load_contact_list_page_ids(v_candidate_ids, COALESCE(p_sort_rules, '[]'::jsonb), v_page_num, v_limit, p_role) o
  ),
  page_ids AS (SELECT ordered.contact_id, ordered.rn FROM ordered),
  tot AS (SELECT ordered.total_count FROM ordered LIMIT 1),
  agg_ids AS (SELECT array_agg(contact_id ORDER BY rn) AS ids FROM page_ids)
  SELECT a.ids, t.total_count INTO v_page_rec FROM agg_ids a, tot t;

  v_page_ids := v_page_rec.ids;
  v_total_count := v_page_rec.total_count;

  IF v_total_count IS NULL THEN v_total_count := 0; END IF;
  IF v_page_ids IS NULL THEN v_page_ids := ARRAY[]::bigint[]; END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(c)::jsonb ORDER BY array_position(v_page_ids, c.id)), '[]'::jsonb)
  INTO v_contacts
  FROM public.contact c
  WHERE c.id = ANY(v_page_ids);
  IF v_contacts IS NULL THEN v_contacts := '[]'::jsonb; END IF;

  IF cardinality(v_page_ids) > 0 THEN
    IF p_include_unanswered_status THEN
      SELECT s.id INTO v_latest_survey_id FROM public.surveys s WHERE s.status = 'active' AND s.archived = false ORDER BY s.id DESC LIMIT 1;
      IF v_latest_survey_id IS NOT NULL THEN
        SELECT jsonb_object_agg(sub.contact_id::text, sub.status) INTO v_unanswered
        FROM (
          SELECT DISTINCT ON (sr.contact_id) sr.contact_id,
            CASE WHEN sr.status = 'in_progress' THEN 'in_progress' WHEN sr.status = 'completed' THEN 'completed' ELSE 'not_started' END AS status
          FROM public.survey_responses sr
          WHERE sr.contact_id = ANY(v_page_ids) AND sr.survey_id = v_latest_survey_id AND sr.status IN ('in_progress', 'completed')
          ORDER BY sr.contact_id, sr.created_at DESC
        ) sub;
        IF v_unanswered IS NULL THEN v_unanswered := '{}'::jsonb; END IF;
        v_unanswered := (SELECT jsonb_object_agg(n::text, COALESCE(v_unanswered->>n::text, 'not_started')) FROM unnest(v_page_ids) n);
        IF v_unanswered IS NULL THEN v_unanswered := '{}'::jsonb; END IF;
      END IF;
    END IF;

    IF p_include_button_state THEN
      WITH colour_survey AS (SELECT s.id, COALESCE((s.settings->'buttonDisplay'->>'colour'), 'pink') AS colour FROM public.surveys s WHERE s.status = 'active' AND s.archived = false AND COALESCE((s.settings->'buttonDisplay'->>'coloursButton')::boolean, false) = true ORDER BY COALESCE((s.settings->'buttonDisplay'->>'priority')::int, 0), s.id LIMIT 1),
      latest_survey AS (SELECT id FROM public.surveys WHERE status = 'active' AND archived = false ORDER BY id DESC LIMIT 1),
      survey_to_use AS (SELECT id, colour FROM colour_survey UNION ALL SELECT l.id, 'pink' FROM latest_survey l WHERE NOT EXISTS (SELECT 1 FROM colour_survey))
      SELECT (SELECT jsonb_object_agg(x.cid::text, y.colour) FROM (SELECT unnest(v_page_ids) AS cid) x, (SELECT colour FROM survey_to_use LIMIT 1) y),
             (SELECT jsonb_object_agg(x.cid::text, y.id) FROM (SELECT unnest(v_page_ids) AS cid) x, (SELECT id FROM survey_to_use LIMIT 1) y)
      INTO v_button_colour, v_button_survey_id;
      IF v_button_colour IS NULL THEN v_button_colour := '{}'::jsonb; END IF;
      IF v_button_survey_id IS NULL THEN v_button_survey_id := '{}'::jsonb; END IF;
    END IF;

    IF p_include_pending_suggestions THEN
      SELECT jsonb_object_agg(entity_id::text, field_names) INTO v_pending_suggestions
      FROM (SELECT fs.entity_id, jsonb_agg(fs.field_name) AS field_names FROM public.field_suggestions fs WHERE fs.entity_type = 'contact' AND fs.entity_id = ANY(v_page_ids) AND fs.status = 'pending' GROUP BY fs.entity_id) sub;
      IF v_pending_suggestions IS NULL THEN v_pending_suggestions := '{}'::jsonb; END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object('contacts', v_contacts, 'total_count', v_total_count, 'unanswered_status', v_unanswered, 'contact_survey_button_colour', v_button_colour, 'contact_survey_button_survey_id', v_button_survey_id, 'pending_suggestions_by_contact', v_pending_suggestions);
END;
$$;
