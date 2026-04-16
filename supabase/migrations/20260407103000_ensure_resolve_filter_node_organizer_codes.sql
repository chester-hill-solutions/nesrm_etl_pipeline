-- Idempotent: ensure resolve_filter_node handles contact.organizer_codes (text[]) without ILIKE.
-- If 20260430293600 was never applied to this database (or the function was recreated), RPC
-- load_contact_dashboard_page_payload still errors with: operator does not exist: text[] ~~* text.

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

  IF function_definition LIKE '%c.organizer_codes @>%'
    OR function_definition LIKE '%c.organizer_codes_lower @>%' THEN
    RAISE NOTICE 'resolve_filter_node already includes organizer_codes array semantics; skipping';
    RETURN;
  END IF;

  original_definition := function_definition;

  function_definition := replace(
    function_definition,
    E'  v_esc_ilike text;\n',
    E'  v_esc_ilike text;\n  v_org_codes_tokens text[];\n'
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node ensure organizer_codes: DECLARE v_esc_ilike anchor not found';
  END IF;

  original_definition := function_definition;

  function_definition := replace(
    function_definition,
    '  -- Special: "name" column (firstname + surname)',
    $oc$
  -- organizer_codes (text[]): ILIKE is invalid on text[]
  IF v_db_col = 'organizer_codes' THEN
    SELECT coalesce(array_agg(lower(trim(t))), ARRAY[]::text[])
    INTO v_org_codes_tokens
    FROM unnest(string_to_array(coalesce(v_val, ''), ',')) t
    WHERE trim(t) <> '';

    IF v_op IN ('contains', 'eq') THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND c.organizer_codes @> v_org_codes_tokens;
      RETURN;
    ELSIF v_op IN ('not_contains', 'neq') THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR NOT (c.organizer_codes @> v_org_codes_tokens)
        );
      RETURN;
    ELSIF v_op = 'in' THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND c.organizer_codes && v_org_codes_tokens;
      RETURN;
    ELSIF v_op = 'not_in' THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR NOT (c.organizer_codes && v_org_codes_tokens)
        );
      RETURN;
    ELSIF v_op = 'is_null' THEN
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR cardinality(c.organizer_codes) = 0
        );
      RETURN;
    ELSIF v_op = 'is_not_null' THEN
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND c.organizer_codes IS NOT NULL
        AND cardinality(c.organizer_codes) > 0;
      RETURN;
    ELSE
      RETURN;
    END IF;
  END IF;

  -- Special: "name" column (firstname + surname)
$oc$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node ensure organizer_codes: name-column anchor not found';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
