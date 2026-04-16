-- Support URL-safe street parity quick-filter token values in resolve_filter_node.
-- Keep backward compatibility with legacy label values.

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
    $$LOWER(COALESCE(v_val, '')) IN ('street # even', 'street # odd')$$,
    $$LOWER(COALESCE(v_val, '')) IN ('street # even', 'street # odd', '__street_number_even__', '__street_number_odd__')$$
  );

  function_definition := replace(
    function_definition,
    $$CASE WHEN strpos($1, '02468') > 0 THEN 0 ELSE 1 END$$,
    $$CASE WHEN LOWER(v_val) IN ('street # even', '__street_number_even__') THEN 0 ELSE 1 END$$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'Failed to patch resolve_filter_node for safe street parity tokens.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
