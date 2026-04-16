-- Add street-number parity quick-filter support to resolve_filter_node.
-- This keeps RPC filter behavior aligned with TS quick-filter translation.

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
    $old$
    WHEN 'contains' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';
      RETURN;
$old$,
    $new$
    WHEN 'contains' THEN
      IF v_db_col = 'street_address' AND LOWER(COALESCE(v_val, '')) IN ('street # even', 'street # odd') THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I ~* $1',
          v_db_col
        )
        USING CASE
          WHEN LOWER(v_val) = 'street # even' THEN '^[[:space:]]*#?[[:space:]]*[0-9]*[02468]([^0-9]|$)'
          ELSE '^[[:space:]]*#?[[:space:]]*[0-9]*[13579]([^0-9]|$)'
        END;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';
      RETURN;
$new$
  );

  IF function_definition = original_definition THEN
    RAISE EXCEPTION
      'Failed to patch resolve_filter_node contains branch; expected snippet was not found.';
  END IF;

  EXECUTE function_definition;
END;
$migration$;
