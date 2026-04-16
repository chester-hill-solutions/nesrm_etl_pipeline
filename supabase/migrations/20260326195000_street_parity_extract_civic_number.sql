-- Make street parity filtering compute parity from extracted civic number
-- (instead of relying on regex match parity classes only).

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
    $$AND c.%I ~* $1$$,
    $$AND regexp_match(
             c.%1$I::text,
             ''^[[:space:]]*#?[[:space:]]*([0-9]+[[:space:]]*[/-][[:space:]]*)?([0-9]+)([^0-9]|$)''
           ) IS NOT NULL
           AND (
             regexp_replace(
               c.%1$I::text,
               ''^[[:space:]#]*([0-9]+[[:space:]]*[/-][[:space:]]*)?([0-9]+).*$'',
               ''\2''
             ) ~ ''^[0-9]+$''
           )
           AND (
             (
               regexp_replace(
                 c.%1$I::text,
                 ''^[[:space:]#]*([0-9]+[[:space:]]*[/-][[:space:]]*)?([0-9]+).*$'',
                 ''\2''
               )::bigint %% 2
             )
           ) = CASE WHEN strpos($1, ''02468'') > 0 THEN 0 ELSE 1 END$$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION 'Failed to patch resolve_filter_node civic parity extraction.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
