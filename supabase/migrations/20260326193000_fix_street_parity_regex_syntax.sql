-- Fix Postgres regex syntax for street-number parity quick-filter.
-- Postgres uses POSIX regex; non-capturing groups (?:...) are not supported.

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

  function_definition := replace(
    function_definition,
    '^[[:space:]]*#?[[:space:]]*(?:[0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[02468]([^0-9]|$)',
    '^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[02468]([^0-9]|$)'
  );

  function_definition := replace(
    function_definition,
    '^[[:space:]]*#?[[:space:]]*(?:[0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[13579]([^0-9]|$)',
    '^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[13579]([^0-9]|$)'
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'Failed to patch resolve_filter_node parity regex syntax.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
