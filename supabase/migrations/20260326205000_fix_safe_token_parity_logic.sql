-- Fix parity logic for safe tokens in resolve_filter_node:
-- 1) map __street_number_even__ to even regex branch
-- 2) compute parity from value token ($2) instead of regex text ($1)
-- 3) ensure regexp_replace backreference uses '\2' not '\\2'

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
    $$CASE WHEN strpos($1, ''02468'') > 0 THEN 0 ELSE 1 END$$,
    $$CASE WHEN LOWER($2) IN (''street # even'', ''__street_number_even__'') THEN 0 ELSE 1 END$$
  );

  function_definition := replace(
    function_definition,
    $$USING CASE
          WHEN LOWER(v_val) = 'street # even' THEN '^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[02468]([^0-9]|$)'
          ELSE '^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[13579]([^0-9]|$)'
        END;$$,
    $$USING CASE
          WHEN LOWER(v_val) IN ('street # even', '__street_number_even__') THEN '^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[02468]([^0-9]|$)'
          ELSE '^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?[0-9]*[13579]([^0-9]|$)'
        END,
        v_val;$$
  );

  function_definition := replace(function_definition, '''\\2''', '''\2''');

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'Failed to patch resolve_filter_node safe token parity logic.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
