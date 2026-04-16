-- Fix capture-group replacement in resolve_filter_node parity extraction branch.
-- Previous patch used '\\2' and returned literal text instead of captured civic number.

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

  function_definition := replace(function_definition, '''\\2''', '''\2''');

  IF function_definition = original_definition THEN
    RETURN;
  END IF;

  EXECUTE function_definition;
END;
$migration$;
