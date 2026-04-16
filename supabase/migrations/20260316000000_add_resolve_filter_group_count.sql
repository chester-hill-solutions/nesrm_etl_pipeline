-- Add count-only RPC for filter groups (avoids max_rows cap on rowset RPCs).

CREATE OR REPLACE FUNCTION public.resolve_filter_group_count(p_group jsonb)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_count bigint;
BEGIN
  IF p_group IS NULL OR jsonb_typeof(p_group) <> 'object' THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.resolve_filter_group(p_group);

  RETURN COALESCE(v_count, 0);
END;
$$;

COMMENT ON FUNCTION public.resolve_filter_group_count(jsonb)
IS 'Returns total contacts matching a filter group without rowset limits.';
