-- PostgREST api.max_rows applies per row for SETOF-returning RPCs, so resolve_filter_group
-- returns at most N rows (e.g. 1000 locally). Segment exclude rules materialize id not_in from
-- that RPC and would miss members beyond the cap. This wrapper aggregates the same ids into
-- one bigint[] row so the full set is returned (subject to HTTP payload limits).

CREATE OR REPLACE FUNCTION public.resolve_filter_group_id_array(p_group jsonb)
RETURNS bigint[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    ARRAY(
      SELECT * FROM resolve_filter_group(p_group)
    ),
    ARRAY[]::bigint[]
  );
$$;

COMMENT ON FUNCTION public.resolve_filter_group_id_array(jsonb) IS
  'All contact ids matching p_group as a single array (avoids PostgREST row limits on SETOF resolve_filter_group).';

GRANT EXECUTE ON FUNCTION public.resolve_filter_group_id_array(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_filter_group_id_array(jsonb) TO service_role;
