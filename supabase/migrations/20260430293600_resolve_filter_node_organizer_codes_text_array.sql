-- contact.organizer_codes is text[]. resolve_filter_node must not use ILIKE on it (42883: text[] ~~* text).
-- Semantics align with CRM buildTextArrayFilterString: eq/contains -> @>, neq/not_contains -> null or NOT @>,
-- in -> &&, not_in -> null or NOT &&, is_null / is_not_null on the array column.

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

  -- 07103000+ already added this; 08180000 rewrites eq/contains so @>/organizer_codes_lower literals
  -- may be gone while v_org_codes_tokens remains — do not inject a second DECLARE line.
  IF function_definition LIKE '%v_org_codes_tokens text[]%' THEN
    RAISE NOTICE 'resolve_filter_node already declares v_org_codes_tokens; skipping';
    RETURN;
  END IF;

  -- Already patched with array semantics but unusual definition shape (no DECLARE line match above).
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
    RAISE EXCEPTION 'resolve_filter_node patch: DECLARE v_esc_ilike anchor not found';
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
    RAISE EXCEPTION 'resolve_filter_node patch: name-column anchor not found';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
