-- Feature: support survey pseudo-columns in resolve_filter_node (contact dashboard RPC).
-- Adds support for:
-- - survey_status (derived; not_started when no responses)
-- - disposition (most recent non-null)
-- - answers.<questionId> (most recent non-null answer for that question)
-- - disposition_count.<value> (count of responses with that disposition)
--
-- Semantics: "most recent non-null" means we walk back through responses until the value exists.

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
  v_param_cast text;

  v_esc_ilike text;

  v_question_id int;
  v_disp_value text;
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

    v_esc_ilike := public.escape_search_for_ilike(v_val);

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
        RETURN;

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
          RETURN;
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2::numeric',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        ELSIF v_custom_type = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2::boolean',
            v_val_col
          )
          USING v_custom_id, (v_val IN ('true', '1'));
          RETURN;
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
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
          RETURN;
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2::numeric)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        ELSIF v_custom_type = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2::boolean)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, (v_val IN ('true', '1'));
          RETURN;
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
          RETURN;
        END IF;

      WHEN 'contains' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike || '%';
          RETURN;
        END IF;

      WHEN 'not_contains' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I NOT ILIKE $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike || '%';
          RETURN;
        END IF;

      WHEN 'starts_with' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, v_esc_ilike || '%';
          RETURN;
        END IF;

      WHEN 'ends_with' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike;
          RETURN;
        END IF;

      WHEN 'gt' THEN
        IF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I > $2::numeric',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I > $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        END IF;

      WHEN 'gte' THEN
        IF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I >= $2::numeric',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I >= $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        END IF;

      WHEN 'lt' THEN
        IF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I < $2::numeric',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I < $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        END IF;

      WHEN 'lte' THEN
        IF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I <= $2::numeric',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I <= $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
          RETURN;
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
          RETURN;
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
                AND TRIM(t) ~ '^-?[0-9]+(\\.[0-9]+)?$'
            );
          RETURN;
        END IF;

      ELSE
        NULL;
    END CASE;

    RETURN;
  END IF;

  -- Survey pseudo-columns (must run before standard contact allowlist).
  v_esc_ilike := public.escape_search_for_ilike(v_val);

  IF v_col = 'survey_status' THEN
    RETURN QUERY
    WITH latest AS (
      SELECT DISTINCT ON (sr.contact_id)
        sr.contact_id,
        sr.status
      FROM public.survey_responses sr
      WHERE sr.contact_id IS NOT NULL
        AND sr.status IN ('completed', 'in_progress')
      ORDER BY sr.contact_id, sr.created_at DESC, sr.id DESC
    )
    SELECT c.id
    FROM public.contact c
    LEFT JOIN latest l ON l.contact_id = c.id
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        CASE v_op
          WHEN 'eq' THEN COALESCE(l.status, 'not_started') = v_val
          WHEN 'neq' THEN COALESCE(l.status, 'not_started') <> v_val
          WHEN 'contains' THEN COALESCE(l.status, 'not_started') ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN COALESCE(l.status, 'not_started') NOT ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'starts_with' THEN COALESCE(l.status, 'not_started') ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN COALESCE(l.status, 'not_started') ILIKE ('%' || v_esc_ilike)
          WHEN 'is_null' THEN l.status IS NULL
          WHEN 'is_not_null' THEN l.status IS NOT NULL
          WHEN 'in' THEN COALESCE(l.status, 'not_started') = ANY(
            (
              SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
            )
          )
          ELSE false
        END
      );
    RETURN;
  END IF;

  IF v_col = 'disposition' THEN
    RETURN QUERY
    WITH latest AS (
      SELECT DISTINCT ON (sr.contact_id)
        sr.contact_id,
        sr.disposition
      FROM public.survey_responses sr
      WHERE sr.contact_id IS NOT NULL
        AND sr.status IN ('completed', 'in_progress')
        AND sr.disposition IS NOT NULL
        AND TRIM(sr.disposition) <> ''
      ORDER BY sr.contact_id, sr.created_at DESC, sr.id DESC
    )
    SELECT c.id
    FROM public.contact c
    LEFT JOIN latest l ON l.contact_id = c.id
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        CASE v_op
          WHEN 'eq' THEN l.disposition = v_val
          WHEN 'neq' THEN (l.disposition IS NULL OR l.disposition <> v_val)
          WHEN 'contains' THEN l.disposition ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN (l.disposition IS NULL OR l.disposition NOT ILIKE ('%' || v_esc_ilike || '%'))
          WHEN 'starts_with' THEN l.disposition ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN l.disposition ILIKE ('%' || v_esc_ilike)
          WHEN 'is_null' THEN l.disposition IS NULL
          WHEN 'is_not_null' THEN l.disposition IS NOT NULL
          WHEN 'in' THEN l.disposition = ANY(
            (
              SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
            )
          )
          ELSE false
        END
      );
    RETURN;
  END IF;

  IF v_col ~ '^answers\\.[0-9]+$' THEN
    v_question_id := (substring(v_col from '^answers\\.([0-9]+)$'))::int;

    IF v_op = 'is_not_null' THEN
      RETURN QUERY
      SELECT DISTINCT sr.contact_id
      FROM public.survey_responses sr
      JOIN public.survey_response_answers sra
        ON sra.response_id = sr.id
       AND sra.question_id = v_question_id
      WHERE sr.contact_id IS NOT NULL
        AND sr.status IN ('completed', 'in_progress')
        AND (
          (sra.answer_text IS NOT NULL AND TRIM(sra.answer_text) <> '') OR
          sra.answer_number IS NOT NULL OR
          sra.answer_boolean IS NOT NULL OR
          sra.answer_date IS NOT NULL OR
          sra.answer_json IS NOT NULL
        );
      RETURN;
    END IF;

    IF v_op = 'is_null' THEN
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND NOT EXISTS (
          SELECT 1
          FROM public.survey_responses sr
          JOIN public.survey_response_answers sra
            ON sra.response_id = sr.id
           AND sra.question_id = v_question_id
          WHERE sr.contact_id = c.id
            AND sr.status IN ('completed', 'in_progress')
            AND (
              (sra.answer_text IS NOT NULL AND TRIM(sra.answer_text) <> '') OR
              sra.answer_number IS NOT NULL OR
              sra.answer_boolean IS NOT NULL OR
              sra.answer_date IS NOT NULL OR
              sra.answer_json IS NOT NULL
            )
        );
      RETURN;
    END IF;

    RETURN QUERY
    WITH latest_answer AS (
      SELECT DISTINCT ON (sr.contact_id)
        sr.contact_id,
        COALESCE(
          NULLIF(TRIM(sra.answer_text), ''),
          CASE WHEN sra.answer_number IS NOT NULL THEN sra.answer_number::text END,
          CASE
            WHEN sra.answer_boolean IS NOT NULL THEN (CASE WHEN sra.answer_boolean THEN 'true' ELSE 'false' END)
          END,
          sra.answer_date,
          CASE
            WHEN sra.answer_json IS NULL THEN NULL
            WHEN jsonb_typeof(sra.answer_json::jsonb) = 'array' THEN (
              SELECT array_to_string(array_agg(e), ',')
              FROM jsonb_array_elements_text(sra.answer_json::jsonb) e
            )
            ELSE sra.answer_json::text
          END
        ) AS answer_value
      FROM public.survey_responses sr
      JOIN public.survey_response_answers sra
        ON sra.response_id = sr.id
       AND sra.question_id = v_question_id
      WHERE sr.contact_id IS NOT NULL
        AND sr.status IN ('completed', 'in_progress')
        AND (
          (sra.answer_text IS NOT NULL AND TRIM(sra.answer_text) <> '') OR
          sra.answer_number IS NOT NULL OR
          sra.answer_boolean IS NOT NULL OR
          sra.answer_date IS NOT NULL OR
          sra.answer_json IS NOT NULL
        )
      ORDER BY sr.contact_id, sr.created_at DESC, sr.id DESC
    )
    SELECT c.id
    FROM public.contact c
    LEFT JOIN latest_answer la ON la.contact_id = c.id
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        CASE v_op
          WHEN 'eq' THEN la.answer_value = v_val
          WHEN 'neq' THEN (la.answer_value IS NULL OR la.answer_value <> v_val)
          WHEN 'contains' THEN la.answer_value ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN (la.answer_value IS NULL OR la.answer_value NOT ILIKE ('%' || v_esc_ilike || '%'))
          WHEN 'starts_with' THEN la.answer_value ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN la.answer_value ILIKE ('%' || v_esc_ilike)
          WHEN 'in' THEN la.answer_value = ANY(
            (
              SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
            )
          )
          WHEN 'gt' THEN (
            (v_val ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value::date > v_val::date) OR
            (v_val ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value::numeric > v_val::numeric)
          )
          WHEN 'gte' THEN (
            (v_val ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value::date >= v_val::date) OR
            (v_val ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value::numeric >= v_val::numeric)
          )
          WHEN 'lt' THEN (
            (v_val ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value::date < v_val::date) OR
            (v_val ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value::numeric < v_val::numeric)
          )
          WHEN 'lte' THEN (
            (v_val ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND la.answer_value::date <= v_val::date) OR
            (v_val ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value ~ '^-?[0-9]+(\\.[0-9]+)?$' AND la.answer_value::numeric <= v_val::numeric)
          )
          ELSE false
        END
      );
    RETURN;
  END IF;

  IF v_col ~ '^disposition_count\\.' THEN
    v_disp_value := substring(v_col from '^disposition_count\\.(.*)$');
    RETURN QUERY
    WITH counts AS (
      SELECT sr.contact_id, COUNT(*) FILTER (WHERE sr.disposition = v_disp_value) AS cnt
      FROM public.survey_responses sr
      WHERE sr.contact_id IS NOT NULL
        AND sr.status IN ('completed', 'in_progress')
      GROUP BY sr.contact_id
    )
    SELECT c.id
    FROM public.contact c
    LEFT JOIN counts ct ON ct.contact_id = c.id
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        CASE v_op
          WHEN 'eq' THEN COALESCE(ct.cnt, 0) = COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'neq' THEN COALESCE(ct.cnt, 0) <> COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'gt' THEN COALESCE(ct.cnt, 0) > COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'gte' THEN COALESCE(ct.cnt, 0) >= COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'lt' THEN COALESCE(ct.cnt, 0) < COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'lte' THEN COALESCE(ct.cnt, 0) <= COALESCE(NULLIF(v_val, ''), '0')::int
          ELSE false
        END
      );
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
    'signup_submitted',
    'submission_confirmed',
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

  -- Cast filter values for non-text columns (avoids bigint = text errors)
  v_param_cast := CASE v_db_col
    WHEN 'id' THEN 'bigint'
    WHEN 'birthyear' THEN 'smallint'
    WHEN 'birthmonth' THEN 'smallint'
    WHEN 'birthdate' THEN 'smallint'
    WHEN 'comms_consent' THEN 'boolean'
    WHEN 'signup_consent' THEN 'boolean'
    WHEN 'signup_submitted' THEN 'boolean'
    WHEN 'submission_confirmed' THEN 'boolean'
    WHEN 'member' THEN 'boolean'
    WHEN 'research_updated_at' THEN 'timestamptz'
    ELSE NULL
  END;

  IF v_param_cast IS NOT NULL
    AND v_op IN ('eq', 'neq', 'gt', 'gte', 'lt', 'lte')
    AND (v_val IS NULL OR v_val = '')
  THEN
    RETURN;
  END IF;

  -- Standard column operators
  v_esc_ilike := public.escape_search_for_ilike(v_val);

  CASE v_op
    WHEN 'eq' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I = $1::%s',
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I = $1',
        v_db_col
      )
      USING v_val;
      RETURN;

    WHEN 'neq' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND (c.%I IS NULL OR c.%I <> $1::%s)',
          v_db_col,
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.%I IS NULL OR c.%I <> $1)',
        v_db_col,
        v_db_col
      )
      USING v_val;
      RETURN;

    WHEN 'contains' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';
      RETURN;

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
      RETURN;

    WHEN 'starts_with' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING v_esc_ilike || '%';
      RETURN;

    WHEN 'ends_with' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike;
      RETURN;

    WHEN 'gt' THEN
      IF v_param_cast IS NULL THEN RETURN; END IF;
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I > $1::%s',
        v_db_col,
        v_param_cast
      )
      USING v_val;
      RETURN;

    WHEN 'gte' THEN
      IF v_param_cast IS NULL THEN RETURN; END IF;
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I >= $1::%s',
        v_db_col,
        v_param_cast
      )
      USING v_val;
      RETURN;

    WHEN 'lt' THEN
      IF v_param_cast IS NULL THEN RETURN; END IF;
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I < $1::%s',
        v_db_col,
        v_param_cast
      )
      USING v_val;
      RETURN;

    WHEN 'lte' THEN
      IF v_param_cast IS NULL THEN RETURN; END IF;
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I <= $1::%s',
        v_db_col,
        v_param_cast
      )
      USING v_val;
      RETURN;

    WHEN 'is_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.%I IS NULL OR TRIM(COALESCE(c.%I::text, '''')) = '''')',
        v_db_col,
        v_db_col
      );
      RETURN;

    WHEN 'is_not_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I IS NOT NULL
           AND TRIM(COALESCE(c.%I::text, '''')) <> ''''',
        v_db_col,
        v_db_col
      );
      RETURN;

    WHEN 'in' THEN
      IF v_param_cast IS NOT NULL THEN
        -- Numeric + boolean support; for other casts, fall back to text array compare.
        IF v_param_cast = 'bigint' THEN
          RETURN QUERY EXECUTE format(
            'SELECT c.id
             FROM public.contact c
             WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
               AND c.%I = ANY($1::bigint[])',
            v_db_col
          )
          USING (
            SELECT COALESCE(array_agg((TRIM(t))::bigint), ARRAY[]::bigint[])
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
            WHERE TRIM(t) <> ''
              AND TRIM(t) ~ '^-?[0-9]+$'
          );
          RETURN;
        ELSIF v_param_cast = 'smallint' THEN
          RETURN QUERY EXECUTE format(
            'SELECT c.id
             FROM public.contact c
             WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
               AND c.%I = ANY($1::smallint[])',
            v_db_col
          )
          USING (
            SELECT COALESCE(array_agg((TRIM(t))::smallint), ARRAY[]::smallint[])
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
            WHERE TRIM(t) <> ''
              AND TRIM(t) ~ '^-?[0-9]+$'
          );
          RETURN;
        ELSIF v_param_cast = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT c.id
             FROM public.contact c
             WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
               AND c.%I = ANY($1::boolean[])',
            v_db_col
          )
          USING (
            SELECT COALESCE(array_agg((TRIM(t))::boolean), ARRAY[]::boolean[])
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
            WHERE TRIM(t) IN ('true','false','1','0')
          );
          RETURN;
        END IF;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I::text = ANY($1::text[])',
        v_db_col
      )
      USING (
        SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
        FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
        WHERE TRIM(t) <> ''
      );
      RETURN;

    ELSE
      RETURN;
  END CASE;
END;
$$;

