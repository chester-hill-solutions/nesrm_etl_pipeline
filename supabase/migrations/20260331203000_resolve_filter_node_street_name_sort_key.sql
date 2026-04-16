-- Quick filters use column key `street_name_sort_key`; resolve_filter_node must filter `street_address`.

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
    $$WHEN 'postal_code' THEN 'postcode'
    ELSE v_col$$,
    $$WHEN 'postal_code' THEN 'postcode'
    WHEN 'street_name_sort_key' THEN 'street_address'
    ELSE v_col$$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION
      'Failed to patch resolve_filter_node: street_name_sort_key mapping snippet not found.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
