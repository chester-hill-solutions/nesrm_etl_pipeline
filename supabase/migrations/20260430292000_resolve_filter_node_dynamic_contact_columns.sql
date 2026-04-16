-- Replace fixed resolve_filter_node column allowlist with a catalog check against
-- public.contact so any real table column (e.g. ssw_ballot1, future fields) filters
-- without a new migration per column.

DO $migration$
DECLARE
  function_definition text;
  original_definition text;
  v_pos int;
  v_pos2 int;
  v_anchor text := '  -- Validate v_db_col exists on contact (allowlist for safety)';
  v_anchor2 text := '  -- Special: "name" column (firstname + surname)';
  v_replacement text := $repl$
  -- Validate v_db_col is a column on public.contact (catalog; no fixed allowlist)
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute a
    INNER JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    INNER JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'contact'
      AND a.attname = v_db_col
      AND a.attnum > 0
      AND NOT a.attisdropped
  ) THEN
    RETURN;
  END IF;
$repl$;
BEGIN
  SELECT pg_get_functiondef('public.resolve_filter_node(jsonb)'::regprocedure)
  INTO function_definition;

  IF function_definition IS NULL THEN
    RAISE EXCEPTION 'public.resolve_filter_node(jsonb) not found';
  END IF;

  original_definition := function_definition;

  v_pos := strpos(function_definition, v_anchor);
  IF v_pos = 0 THEN
    RAISE EXCEPTION 'resolve_filter_node patch: allowlist anchor not found';
  END IF;

  v_pos2 := strpos(function_definition, v_anchor2);
  IF v_pos2 = 0 OR v_pos2 <= v_pos THEN
    RAISE EXCEPTION 'resolve_filter_node patch: name-column anchor not found';
  END IF;

  function_definition :=
    substring(function_definition FROM 1 FOR v_pos - 1)
    || v_replacement
    || E'\n'
    || substring(function_definition FROM v_pos2);

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'resolve_filter_node patch: definition unchanged';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
