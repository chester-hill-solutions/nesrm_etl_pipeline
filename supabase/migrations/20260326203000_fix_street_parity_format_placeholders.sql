-- Repair resolve_filter_node parity branch after %I placeholder expansion
-- introduced multiple format placeholders with only one format argument.

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

  -- Keep one format argument and reuse it by positional placeholder.
  function_definition := replace(function_definition, 'c.%I::text', 'c.%1$I::text');

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'Failed to patch resolve_filter_node format placeholders.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
