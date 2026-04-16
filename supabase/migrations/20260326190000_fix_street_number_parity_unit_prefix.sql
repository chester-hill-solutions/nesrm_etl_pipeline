-- Follow-up: parity regex should ignore optional unit prefix (e.g. 2/15 Main St -> 15).

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
    '^[[:space:]]*#?[[:space:]]*[0-9]*[02468]([^0-9]|$)',
    '^[[:space:]]*#?[[:space:]]*(?:[0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[02468]([^0-9]|$)'
  );

  function_definition := replace(
    function_definition,
    '^[[:space:]]*#?[[:space:]]*[0-9]*[13579]([^0-9]|$)',
    '^[[:space:]]*#?[[:space:]]*(?:[0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[13579]([^0-9]|$)'
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION
      'Failed to patch resolve_filter_node parity regex; expected patterns were not found.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
