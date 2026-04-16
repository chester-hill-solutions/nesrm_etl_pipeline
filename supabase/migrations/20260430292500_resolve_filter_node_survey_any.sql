-- Select filter UI "Any" uses value ""; treat as no constraint for survey pseudo-columns in
-- resolve_filter_node (RPC path). Matches expandSurveyFilters + normalizeSurveyPseudoColumnFilter in CRM.

DO $migration$
DECLARE
  function_definition text;
  original_definition text;
BEGIN
  SELECT pg_get_functiondef('public.resolve_filter_node(jsonb)'::regprocedure)
  INTO function_definition;

  IF function_definition IS NULL THEN
    RAISE EXCEPTION 'public.resolve_filter_node(jsonb) not found';
  END IF;

  original_definition := function_definition;

  -- survey_status (scoped + legacy blocks share identical CASE arms)
  function_definition := replace(
    function_definition,
    $old$
          WHEN 'eq' THEN COALESCE(l.status, 'not_started') = v_val
          WHEN 'neq' THEN COALESCE(l.status, 'not_started') <> v_val
          WHEN 'contains' THEN COALESCE(l.status, 'not_started') ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN COALESCE(l.status, 'not_started') NOT ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'starts_with' THEN COALESCE(l.status, 'not_started') ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN COALESCE(l.status, 'not_started') ILIKE ('%' || v_esc_ilike)
          WHEN 'is_null' THEN l.status IS NULL
          WHEN 'is_not_null' THEN l.status IS NOT NULL
          WHEN 'in' THEN COALESCE(l.status, 'not_started') IN (
            SELECT TRIM(t)
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t
            WHERE TRIM(t) <> ''
          )
$old$,
    $new$
          WHEN 'eq' THEN (
            v_val IS NULL
            OR TRIM(COALESCE(v_val, '')) = ''
            OR lower(TRIM(COALESCE(v_val, ''))) = 'any'
            OR COALESCE(l.status, 'not_started') = v_val
          )
          WHEN 'neq' THEN COALESCE(l.status, 'not_started') <> v_val
          WHEN 'contains' THEN COALESCE(l.status, 'not_started') ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN COALESCE(l.status, 'not_started') NOT ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'starts_with' THEN COALESCE(l.status, 'not_started') ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN COALESCE(l.status, 'not_started') ILIKE ('%' || v_esc_ilike)
          WHEN 'is_null' THEN l.status IS NULL
          WHEN 'is_not_null' THEN l.status IS NOT NULL
          WHEN 'in' THEN (
            NOT EXISTS (
              SELECT 1
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t0
              WHERE TRIM(t0) <> ''
                AND lower(TRIM(t0)) <> 'any'
            )
            OR COALESCE(l.status, 'not_started') IN (
              SELECT DISTINCT e
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS tok,
              LATERAL unnest(
                CASE
                  WHEN TRIM(tok) = '' THEN ARRAY[]::text[]
                  WHEN lower(TRIM(tok)) = 'any' THEN ARRAY['not_started', 'in_progress', 'completed']::text[]
                  ELSE ARRAY[TRIM(tok)]::text[]
                END
              ) AS e
            )
          )
$new$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node patch failed: survey_status CASE not found';
  END IF;

  original_definition := function_definition;

  -- disposition (scoped + legacy)
  function_definition := replace(
    function_definition,
    $old$
          WHEN 'eq' THEN l.disposition = v_val
          WHEN 'neq' THEN (l.disposition IS NULL OR l.disposition <> v_val)
          WHEN 'contains' THEN l.disposition ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN (l.disposition IS NULL OR l.disposition NOT ILIKE ('%' || v_esc_ilike || '%'))
          WHEN 'starts_with' THEN l.disposition ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN l.disposition ILIKE ('%' || v_esc_ilike)
          WHEN 'is_null' THEN l.disposition IS NULL
          WHEN 'is_not_null' THEN l.disposition IS NOT NULL
          WHEN 'in' THEN l.disposition IN (
            SELECT TRIM(t)
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t
            WHERE TRIM(t) <> ''
          )
$old$,
    $new$
          WHEN 'eq' THEN (
            v_val IS NULL
            OR TRIM(COALESCE(v_val, '')) = ''
            OR lower(TRIM(COALESCE(v_val, ''))) = 'any'
            OR l.disposition = v_val
          )
          WHEN 'neq' THEN (l.disposition IS NULL OR l.disposition <> v_val)
          WHEN 'contains' THEN l.disposition ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN (l.disposition IS NULL OR l.disposition NOT ILIKE ('%' || v_esc_ilike || '%'))
          WHEN 'starts_with' THEN l.disposition ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN l.disposition ILIKE ('%' || v_esc_ilike)
          WHEN 'is_null' THEN l.disposition IS NULL
          WHEN 'is_not_null' THEN l.disposition IS NOT NULL
          WHEN 'in' THEN (
            NOT EXISTS (
              SELECT 1
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t0
              WHERE TRIM(t0) <> ''
                AND lower(TRIM(t0)) <> 'any'
            )
            OR EXISTS (
              SELECT 1
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t1
              WHERE TRIM(t1) <> ''
                AND lower(TRIM(t1)) = 'any'
            )
            OR l.disposition IN (
              SELECT TRIM(t)
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t
              WHERE TRIM(t) <> ''
                AND lower(TRIM(t)) <> 'any'
            )
          )
$new$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node patch failed: disposition CASE not found';
  END IF;

  original_definition := function_definition;

  -- answers.* (scoped + legacy)
  function_definition := replace(
    function_definition,
    $old$
          WHEN 'eq' THEN la.answer_value = v_val
          WHEN 'neq' THEN (la.answer_value IS NULL OR la.answer_value <> v_val)
          WHEN 'contains' THEN la.answer_value ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN (la.answer_value IS NULL OR la.answer_value NOT ILIKE ('%' || v_esc_ilike || '%'))
          WHEN 'starts_with' THEN la.answer_value ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN la.answer_value ILIKE ('%' || v_esc_ilike)
          WHEN 'in' THEN la.answer_value IN (
            SELECT TRIM(t)
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t
            WHERE TRIM(t) <> ''
          )
$old$,
    $new$
          WHEN 'eq' THEN (
            v_val IS NULL
            OR TRIM(COALESCE(v_val, '')) = ''
            OR lower(TRIM(COALESCE(v_val, ''))) = 'any'
            OR la.answer_value = v_val
          )
          WHEN 'neq' THEN (la.answer_value IS NULL OR la.answer_value <> v_val)
          WHEN 'contains' THEN la.answer_value ILIKE ('%' || v_esc_ilike || '%')
          WHEN 'not_contains' THEN (la.answer_value IS NULL OR la.answer_value NOT ILIKE ('%' || v_esc_ilike || '%'))
          WHEN 'starts_with' THEN la.answer_value ILIKE (v_esc_ilike || '%')
          WHEN 'ends_with' THEN la.answer_value ILIKE ('%' || v_esc_ilike)
          WHEN 'in' THEN (
            NOT EXISTS (
              SELECT 1
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t0
              WHERE TRIM(t0) <> ''
                AND lower(TRIM(t0)) <> 'any'
            )
            OR EXISTS (
              SELECT 1
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t1
              WHERE TRIM(t1) <> ''
                AND lower(TRIM(t1)) = 'any'
            )
            OR la.answer_value IN (
              SELECT TRIM(t)
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) AS t
              WHERE TRIM(t) <> ''
                AND lower(TRIM(t)) <> 'any'
            )
          )
$new$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node patch failed: answers.* CASE not found';
  END IF;

  original_definition := function_definition;

  -- disposition_count.* (scoped + legacy): empty / any must match all, not count = 0
  function_definition := replace(
    function_definition,
    $old$
        CASE v_op
          WHEN 'eq' THEN COALESCE(ct.cnt, 0) = COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'neq' THEN COALESCE(ct.cnt, 0) <> COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'gt' THEN COALESCE(ct.cnt, 0) > COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'gte' THEN COALESCE(ct.cnt, 0) >= COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'lt' THEN COALESCE(ct.cnt, 0) < COALESCE(NULLIF(v_val, ''), '0')::int
          WHEN 'lte' THEN COALESCE(ct.cnt, 0) <= COALESCE(NULLIF(v_val, ''), '0')::int
          ELSE false
        END
$old$,
    $new$
        CASE v_op
          WHEN 'eq' THEN (
            (v_val IS NULL OR TRIM(COALESCE(v_val, '')) = '' OR lower(TRIM(COALESCE(v_val, ''))) = 'any')
            OR COALESCE(ct.cnt, 0) = COALESCE(NULLIF(TRIM(COALESCE(v_val, '')), ''), '0')::int
          )
          WHEN 'neq' THEN (
            (v_val IS NULL OR TRIM(COALESCE(v_val, '')) = '' OR lower(TRIM(COALESCE(v_val, ''))) = 'any')
            OR COALESCE(ct.cnt, 0) <> COALESCE(NULLIF(TRIM(COALESCE(v_val, '')), ''), '0')::int
          )
          WHEN 'gt' THEN (
            (v_val IS NULL OR TRIM(COALESCE(v_val, '')) = '' OR lower(TRIM(COALESCE(v_val, ''))) = 'any')
            OR COALESCE(ct.cnt, 0) > COALESCE(NULLIF(TRIM(COALESCE(v_val, '')), ''), '0')::int
          )
          WHEN 'gte' THEN (
            (v_val IS NULL OR TRIM(COALESCE(v_val, '')) = '' OR lower(TRIM(COALESCE(v_val, ''))) = 'any')
            OR COALESCE(ct.cnt, 0) >= COALESCE(NULLIF(TRIM(COALESCE(v_val, '')), ''), '0')::int
          )
          WHEN 'lt' THEN (
            (v_val IS NULL OR TRIM(COALESCE(v_val, '')) = '' OR lower(TRIM(COALESCE(v_val, ''))) = 'any')
            OR COALESCE(ct.cnt, 0) < COALESCE(NULLIF(TRIM(COALESCE(v_val, '')), ''), '0')::int
          )
          WHEN 'lte' THEN (
            (v_val IS NULL OR TRIM(COALESCE(v_val, '')) = '' OR lower(TRIM(COALESCE(v_val, ''))) = 'any')
            OR COALESCE(ct.cnt, 0) <= COALESCE(NULLIF(TRIM(COALESCE(v_val, '')), ''), '0')::int
          )
          ELSE false
        END
$new$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node patch failed: disposition_count CASE not found';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
