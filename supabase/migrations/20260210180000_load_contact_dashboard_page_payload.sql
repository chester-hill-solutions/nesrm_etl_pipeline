-- Single-trip contact dashboard page payload RPC.
-- Scope + filter_group + search + sort + pagination in SQL; returns contacts,
-- total_count, and aux maps.
-- Filter semantics mirror app/lib/filter-query-builder.server.ts; sort mirrors
-- load_contact_list_page_ids.

-- Escape search term for ILIKE: \ % _ (so they match literally)
CREATE OR REPLACE FUNCTION public.escape_search_for_ilike(p_val text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT regexp_replace(
    regexp_replace(
      regexp_replace(COALESCE(p_val, ''), E'\\\\', E'\\\\\\\\', 'g'),
      '%',
      E'\\\\%',
      'g'
    ),
    '_',
    E'\\\\_',
    'g'
  );
$$;

-- Resolve a single filter node to contact IDs (standard or custom column).
-- Node: { "kind": "filter", "column": "...", "operator": "...", "value": "..." }
-- Custom columns matched by custom_columns.name; standard columns use contact
-- table with column mapping.
CREATE OR REPLACE FUNCTION public.resolve_filter_node(p_node jsonb)
RETURNS SETOF bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_col text;
  v_op text;
  v_val text;

  v_custom_id bigint;
  v_custom_type text;
  v_val_col text;

  v_db_col text;

  v_esc_ilike text;
  v_sql_op text;
BEGIN
  IF p_node IS NULL OR (p_node->>'kind') <> 'filter' THEN
    RETURN;
  END IF;

  v_col := NULLIF(TRIM(p_node->>'column'), '');
  v_op := NULLIF(LOWER(TRIM(COALESCE(p_node->>'operator', ''))), '');
  v_val := p_node->>'value';
  IF v_val IS NOT NULL THEN
    v_val := TRIM(v_val);
  END IF;

  IF v_col IS NULL OR v_op IS NULL THEN
    RETURN;
  END IF;

  -- Custom column lookup by name
  SELECT cc.id, cc.data_type
  INTO v_custom_id, v_custom_type
  FROM public.custom_columns cc
  WHERE cc.name = v_col
  LIMIT 1;

  IF v_custom_id IS NOT NULL THEN
    -- Custom column filter (contact_custom_fields)
    v_val_col := CASE v_custom_type
      WHEN 'select' THEN 'value_text'
      ELSE 'value_' || v_custom_type
    END;

    -- Special semantics: eq "any" / empty = has any non-empty value
    IF v_op = 'eq'
      AND (v_val IS NULL OR v_val = '' OR LOWER(v_val) = 'any')
    THEN
      RETURN QUERY EXECUTE format(
        'SELECT ccf.contact_id
         FROM public.contact_custom_fields ccf
         WHERE ccf.column_id = $1
           AND ccf.%I IS NOT NULL
           AND TRIM(COALESCE(ccf.%I::text, '''')) <> ''''',
        v_val_col,
        v_val_col
      )
      USING v_custom_id;
      RETURN;
    END IF;

    -- neq "any" for select = has no value (missing row or null/empty)
    IF v_op = 'neq'
      AND (v_val IS NULL OR v_val = '' OR LOWER(v_val) = 'any')
      AND v_custom_type = 'select'
    THEN
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND NOT EXISTS (
          SELECT 1
          FROM public.contact_custom_fields ccf
          WHERE ccf.contact_id = c.id
            AND ccf.column_id = v_custom_id
            AND ccf.value_text IS NOT NULL
            AND TRIM(ccf.value_text) <> ''
        );
      RETURN;
    END IF;

    -- is_null for custom: include contacts with missing row or null/empty value
    IF v_op = 'is_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND NOT EXISTS (
             SELECT 1
             FROM public.contact_custom_fields ccf
             WHERE ccf.contact_id = c.id
               AND ccf.column_id = $1
               AND ccf.%I IS NOT NULL
               AND TRIM(COALESCE(ccf.%I::text, '''')) <> ''''
           )',
        v_val_col,
        v_val_col
      )
      USING v_custom_id;
      RETURN;
    END IF;

    -- Other operators on custom column
    CASE v_op
      WHEN 'is_not_null' THEN
        RETURN QUERY EXECUTE format(
          'SELECT ccf.contact_id
           FROM public.contact_custom_fields ccf
           WHERE ccf.column_id = $1
             AND ccf.%I IS NOT NULL',
          v_val_col
        )
        USING v_custom_id;

      WHEN 'eq' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2',
            v_val_col
          )
          USING v_custom_id, v_val;
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2',
            v_val_col
          )
          USING v_custom_id, (v_val::numeric);
        ELSIF v_custom_type = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2',
            v_val_col
          )
          USING v_custom_id, (v_val IN ('true', '1'));
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
        END IF;

      WHEN 'neq' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, v_val;
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, (v_val::numeric);
        ELSIF v_custom_type = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, (v_val IN ('true', '1'));
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2::date)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, v_val;
        END IF;

      WHEN 'contains' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike || '%';
        END IF;

      WHEN 'not_contains' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I NOT ILIKE $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike || '%';
        END IF;

      WHEN 'starts_with' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, v_esc_ilike || '%';
        END IF;

      WHEN 'ends_with' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike;
        END IF;

      WHEN 'gt', 'gte', 'lt', 'lte' THEN
        v_sql_op := CASE v_op
          WHEN 'gt' THEN '>'
          WHEN 'gte' THEN '>='
          WHEN 'lt' THEN '<'
          WHEN 'lte' THEN '<='
        END;

        IF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I %s $2',
            v_val_col,
            v_sql_op
          )
          USING v_custom_id, (v_val::numeric);
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I %s $2::date',
            v_val_col,
            v_sql_op
          )
          USING v_custom_id, v_val;
        ELSIF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I %s $2',
            v_val_col,
            v_sql_op
          )
          USING v_custom_id, v_val;
        END IF;

      WHEN 'in' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = ANY($2::text[])',
            v_val_col
          )
          USING v_custom_id,
            (
              SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
            );
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = ANY($2::numeric[])',
            v_val_col
          )
          USING v_custom_id,
            (
              SELECT COALESCE(array_agg((TRIM(t))::numeric), ARRAY[]::numeric[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
                AND TRIM(t) ~ '^-?[0-9]+(\.[0-9]+)?$'
            );
        END IF;

      ELSE
        NULL;
    END CASE;

    RETURN;
  END IF;

  -- Standard contact column: map display key to db column
  v_db_col := CASE v_col
    WHEN 'riding' THEN 'division_electoral_district'
    WHEN 'campusClub' THEN 'campus_club'
    WHEN 'rideRequest' THEN 'ride_request_status'
    WHEN 'contactStatus' THEN 'contact_status'
    WHEN 'postal_code' THEN 'postcode'
    ELSE v_col
  END;

  -- Validate v_db_col exists on contact (allowlist for safety)
  IF v_db_col NOT IN (
    'id',
    'firstname',
    'surname',
    'email',
    'phone',
    'division_electoral_district',
    'campus_club',
    'organizer',
    'ride_request_status',
    'contact_status',
    'postcode',
    'street_address',
    'municipality',
    'birthyear',
    'birthmonth',
    'birthdate',
    'tags',
    'member',
    'olp23_member',
    'region',
    'comms_consent',
    'signup_consent',
    'research_status',
    'research_updated_at'
  ) THEN
    RETURN;
  END IF;

  -- Special: "name" column (firstname + surname)
  IF v_col = 'name' AND v_val IS NOT NULL AND v_val <> '' THEN
    v_esc_ilike := public.escape_search_for_ilike(v_val);

    IF v_op IN ('contains', 'eq', 'starts_with', 'ends_with') THEN
      RETURN QUERY EXECUTE
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.firstname ILIKE $1 OR c.surname ILIKE $1)'
      USING
        CASE v_op
          WHEN 'starts_with' THEN v_esc_ilike || '%'
          WHEN 'ends_with' THEN '%' || v_esc_ilike
          WHEN 'eq' THEN v_esc_ilike
          ELSE '%' || v_esc_ilike || '%'
        END;
    END IF;

    RETURN;
  END IF;

  -- Standard column operators
  v_esc_ilike := public.escape_search_for_ilike(v_val);

  CASE v_op
    WHEN 'eq' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I = $1',
        v_db_col
      )
      USING v_val;

    WHEN 'neq' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.%I IS NULL OR c.%I <> $1)',
        v_db_col,
        v_db_col
      )
      USING v_val;

    WHEN 'contains' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';

    WHEN 'not_contains' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.%I IS NULL OR c.%I NOT ILIKE $1)',
        v_db_col,
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';

    WHEN 'starts_with' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING v_esc_ilike || '%';

    WHEN 'ends_with' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike;

    WHEN 'gt' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I > $1',
        v_db_col
      )
      USING v_val;

    WHEN 'gte' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I >= $1',
        v_db_col
      )
      USING v_val;

    WHEN 'lt' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I < $1',
        v_db_col
      )
      USING v_val;

    WHEN 'lte' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I <= $1',
        v_db_col
      )
      USING v_val;

    WHEN 'is_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I IS NULL',
        v_db_col
      );

    WHEN 'is_not_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I IS NOT NULL',
        v_db_col
      );

    WHEN 'in' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I = ANY($1::text[])',
        v_db_col
      )
      USING
        (
          SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
          FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
          WHERE TRIM(t) <> ''
        );

    ELSE
      NULL;
  END CASE;
END;
$$;

-- Recursive filter group: AND = intersection, OR = union of child result sets.
CREATE OR REPLACE FUNCTION public.resolve_filter_group(p_group jsonb)
RETURNS SETOF bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_kind text;
  v_mode text;
  v_child jsonb;

  v_ids bigint[];
  v_all bigint[] := ARRAY[]::bigint[];
  v_first boolean := true;
BEGIN
  IF p_group IS NULL OR jsonb_typeof(p_group) <> 'object' THEN
    RETURN;
  END IF;

  v_kind := p_group->>'kind';

  IF v_kind = 'filter' THEN
    RETURN QUERY
    SELECT *
    FROM public.resolve_filter_node(p_group);
    RETURN;
  END IF;

  IF v_kind <> 'group' THEN
    RETURN;
  END IF;

  v_mode := LOWER(COALESCE(p_group->>'mode', 'and'));
  IF v_mode NOT IN ('and', 'or') THEN
    v_mode := 'and';
  END IF;

  FOR v_child IN
    SELECT *
    FROM jsonb_array_elements(COALESCE(p_group->'children', '[]'::jsonb))
  LOOP
    IF v_mode = 'and' THEN
      IF v_first THEN
        v_all := COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group(v_child)),
          ARRAY[]::bigint[]
        );
        v_first := false;
      ELSE
        v_ids := COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group(v_child)),
          ARRAY[]::bigint[]
        );

        v_all := ARRAY(
          SELECT unnest(v_all)
          INTERSECT
          SELECT unnest(v_ids)
        );
      END IF;
    ELSE
      v_all :=
        v_all
        || COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group(v_child)),
          ARRAY[]::bigint[]
        );
      v_first := false;
    END IF;
  END LOOP;

  -- No children => empty result
  IF v_first THEN
    RETURN;
  END IF;

  IF v_mode = 'or' THEN
    v_all := ARRAY(SELECT DISTINCT unnest(v_all));
  END IF;

  RETURN QUERY
  SELECT unnest(v_all);
END;
$$;

-- Main RPC: single-trip contact dashboard page payload.
-- Scope (all_contacts|signups|riding|campus) + filter_group + search + sort +
-- pagination; returns contacts + total_count + aux maps.
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

  -- 1) Base candidate set: scope filter + archived
  SELECT array_agg(c.id)
  INTO v_candidate_ids
  FROM public.contact c
  WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
    AND (
      (
        COALESCE(TRIM(p_scope_type), 'all_contacts') = 'all_contacts'
        AND (p_scope_values IS NULL OR cardinality(p_scope_values) = 0)
      )
      OR (
        p_scope_type = 'riding'
        AND p_scope_values IS NOT NULL
        AND cardinality(p_scope_values) > 0
        AND c.division_electoral_district = ANY(p_scope_values)
      )
      OR (
        p_scope_type = 'campus'
        AND p_scope_values IS NOT NULL
        AND cardinality(p_scope_values) > 0
        AND c.campus_club = ANY(p_scope_values)
      )
      OR (
        p_scope_type = 'signups'
        AND p_scope_values IS NOT NULL
        AND cardinality(p_scope_values) > 0
        AND (
          EXISTS (
            SELECT 1
            FROM unnest(
              string_to_array(
                regexp_replace(
                  lower(COALESCE(c.organizer, '')),
                  '[,;\n]+',
                  ',',
                  'g'
                ),
                ','
              )
            ) AS t(token)
            WHERE TRIM(t.token) <> ''
              AND TRIM(t.token) IN (
                SELECT TRIM(x)
                FROM unnest(p_scope_values) AS x
                WHERE TRIM(x) <> ''
              )
          )
          OR EXISTS (
            SELECT 1
            FROM unnest(p_scope_values) AS s(val)
            WHERE TRIM(s.val) <> ''
              AND lower(COALESCE(c.organizer, ''))
                LIKE '%' || lower(TRIM(s.val)) || '%'
          )
        )
      )
    );

  IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
    RETURN jsonb_build_object(
      'contacts',
      '[]'::jsonb,
      'total_count',
      0,
      'unanswered_status',
      v_unanswered,
      'contact_survey_button_colour',
      v_button_colour,
      'contact_survey_button_survey_id',
      v_button_survey_id,
      'pending_suggestions_by_contact',
      v_pending_suggestions
    );
  END IF;

  -- 2) Apply filter_group if present
  v_has_filter :=
    p_filter_group IS NOT NULL
    AND jsonb_typeof(p_filter_group) = 'object'
    AND (p_filter_group->'children') IS NOT NULL
    AND jsonb_array_length(p_filter_group->'children') > 0;

  IF v_has_filter THEN
    v_filtered_ids := ARRAY(
      SELECT unnest(v_candidate_ids)
      INTERSECT
      SELECT *
      FROM public.resolve_filter_group_scoped(p_filter_group, v_candidate_ids)
    );

    v_candidate_ids := v_filtered_ids;

    IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
      RETURN jsonb_build_object(
        'contacts',
        '[]'::jsonb,
        'total_count',
        0,
        'unanswered_status',
        v_unanswered,
        'contact_survey_button_colour',
        v_button_colour,
        'contact_survey_button_survey_id',
        v_button_survey_id,
        'pending_suggestions_by_contact',
        v_pending_suggestions
      );
    END IF;
  END IF;

  -- 3) Apply search (email vs name, same as app)
  IF p_search_term IS NOT NULL AND TRIM(p_search_term) <> '' THEN
    v_search_esc := public.escape_search_for_ilike(TRIM(p_search_term));
    v_email_mode := (position('@' IN TRIM(p_search_term)) > 0);

    v_filtered_ids := (
      SELECT array_agg(c.id)
      FROM public.contact c
      WHERE c.id = ANY(v_candidate_ids)
        AND (
          (v_email_mode AND c.email ILIKE '%' || v_search_esc || '%')
          OR (
            NOT v_email_mode
            AND position(' ' IN v_search_esc) > 0
            AND c.firstname ILIKE '%' || TRIM(split_part(v_search_esc, ' ', 1)) || '%'
            AND c.surname ILIKE '%' || TRIM(
              substring(v_search_esc FROM position(' ' IN v_search_esc))
            ) || '%'
          )
          OR (
            NOT v_email_mode
            AND (
              position(' ' IN v_search_esc) = 0
              OR position(' ' IN v_search_esc) IS NULL
            )
            AND (
              c.firstname ILIKE '%' || v_search_esc || '%'
              OR c.surname ILIKE '%' || v_search_esc || '%'
            )
          )
        )
    );

    v_candidate_ids := v_filtered_ids;

    IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
      RETURN jsonb_build_object(
        'contacts',
        '[]'::jsonb,
        'total_count',
        0,
        'unanswered_status',
        v_unanswered,
        'contact_survey_button_colour',
        v_button_colour,
        'contact_survey_button_survey_id',
        v_button_survey_id,
        'pending_suggestions_by_contact',
        v_pending_suggestions
      );
    END IF;
  END IF;

  -- 4) Sort + paginate via existing RPC (cap candidate set for sort to avoid
  -- huge IN)
  IF cardinality(v_candidate_ids) > 10000 THEN
    SELECT array_agg(id ORDER BY id)
    INTO v_candidate_ids
    FROM (
      SELECT unnest(v_candidate_ids) AS id
      ORDER BY id
      LIMIT 10000
    ) sub;
  END IF;

  WITH ordered AS (
    SELECT
      o.contact_id,
      o.total_count,
      row_number() OVER () AS rn
    FROM public.load_contact_list_page_ids(
      v_candidate_ids,
      COALESCE(p_sort_rules, '[]'::jsonb),
      v_page_num,
      v_limit
    ) o
  ),
  page_ids AS (
    SELECT ordered.contact_id, ordered.rn
    FROM ordered
  ),
  tot AS (
    SELECT ordered.total_count
    FROM ordered
    LIMIT 1
  ),
  agg_ids AS (
    SELECT array_agg(contact_id ORDER BY rn) AS ids
    FROM page_ids
  )
  SELECT a.ids, t.total_count
  INTO v_page_rec
  FROM agg_ids a, tot t;

  v_page_ids := v_page_rec.ids;
  v_total_count := v_page_rec.total_count;

  IF v_total_count IS NULL THEN
    v_total_count := 0;
  END IF;

  IF v_page_ids IS NULL THEN
    v_page_ids := ARRAY[]::bigint[];
  END IF;

  -- 5) Contact rows as JSON (preserve order by array_position)
  SELECT COALESCE(
    jsonb_agg(
      row_to_json(c)::jsonb
      ORDER BY array_position(v_page_ids, c.id)
    ),
    '[]'::jsonb
  )
  INTO v_contacts
  FROM public.contact c
  WHERE c.id = ANY(v_page_ids);

  IF v_contacts IS NULL THEN
    v_contacts := '[]'::jsonb;
  END IF;

  -- 6) Aux maps (only for page IDs)
  IF cardinality(v_page_ids) > 0 THEN
    -- Unanswered status: latest active survey response per contact
    IF p_include_unanswered_status THEN
      SELECT s.id
      INTO v_latest_survey_id
      FROM public.surveys s
      WHERE s.status = 'active' AND s.archived = false
      ORDER BY s.id DESC
      LIMIT 1;

      IF v_latest_survey_id IS NOT NULL THEN
        SELECT jsonb_object_agg(sub.contact_id::text, sub.status)
        INTO v_unanswered
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

        -- Fill missing contacts as not_started
        v_unanswered := (
          SELECT jsonb_object_agg(
            n::text,
            COALESCE(v_unanswered->>n::text, 'not_started')
          )
          FROM unnest(v_page_ids) n
        );

        IF v_unanswered IS NULL THEN
          v_unanswered := '{}'::jsonb;
        END IF;
      END IF;
    END IF;

    -- Button state: first active survey with coloursButton (or latest active)
    IF p_include_button_state THEN
      WITH colour_survey AS (
        SELECT
          s.id,
          COALESCE((s.settings->'buttonDisplay'->>'colour'), 'pink') AS colour
        FROM public.surveys s
        WHERE s.status = 'active'
          AND s.archived = false
          AND COALESCE(
            (s.settings->'buttonDisplay'->>'coloursButton')::boolean,
            false
          ) = true
        ORDER BY
          COALESCE((s.settings->'buttonDisplay'->>'priority')::int, 0),
          s.id
        LIMIT 1
      ),
      latest_survey AS (
        SELECT id
        FROM public.surveys
        WHERE status = 'active' AND archived = false
        ORDER BY id DESC
        LIMIT 1
      ),
      survey_to_use AS (
        SELECT id, colour
        FROM colour_survey
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

    -- Pending suggestions: entity_type = 'contact', entity_id in page_ids,
    -- status = 'pending'
    IF p_include_pending_suggestions THEN
      SELECT jsonb_object_agg(entity_id::text, field_names)
      INTO v_pending_suggestions
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
    'contacts',
    v_contacts,
    'total_count',
    v_total_count,
    'unanswered_status',
    v_unanswered,
    'contact_survey_button_colour',
    v_button_colour,
    'contact_survey_button_survey_id',
    v_button_survey_id,
    'pending_suggestions_by_contact',
    v_pending_suggestions
  );
END;
$$;

COMMENT ON FUNCTION public.escape_search_for_ilike(text) IS
  'Escape value for ILIKE so % _ \ match literally.';

COMMENT ON FUNCTION public.resolve_filter_node(jsonb) IS
  'Resolve a single filter node (standard or custom column) to contact IDs; parity with filter-query-builder.';

COMMENT ON FUNCTION public.resolve_filter_group(jsonb) IS
  'Recursively resolve filter group (AND/OR) to contact IDs.';

COMMENT ON FUNCTION public.load_contact_dashboard_page_payload(
  text,
  text[],
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  integer,
  boolean,
  boolean,
  boolean
) IS
  'Single-trip contact dashboard payload: scope + filter + search + sort + pagination; returns contacts, total_count, unanswered_status, button state, pending_suggestions.';