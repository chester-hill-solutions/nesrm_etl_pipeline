-- Batch feature permission checks for default dashboard routing (one round-trip).
-- Semantics match public.check_feature_permission (optimized join version in 20260210140000).

CREATE OR REPLACE FUNCTION public.check_feature_permissions_batch(
  p_feature_ids text[],
  p_role_id text
)
RETURNS TABLE(feature_id text, allowed boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.fid::text AS feature_id,
         COALESCE(sub.allowed, false) AS allowed
  FROM unnest(p_feature_ids) AS u(fid)
  LEFT JOIN LATERAL (
    SELECT fp.allowed
    FROM public.feature_permissions fp
    INNER JOIN public.features f ON f.id = fp.feature_id AND f.enabled = true
    INNER JOIN public.roles r ON r.id = fp.role_id
    WHERE fp.feature_id = u.fid::text
      AND fp.role_id = p_role_id
    LIMIT 1
  ) sub ON true;
$$;

ALTER FUNCTION public.check_feature_permissions_batch(text[], text) OWNER TO postgres;

COMMENT ON FUNCTION public.check_feature_permissions_batch(text[], text) IS
  'Returns allowed flag per feature id for a role, matching check_feature_permission semantics.';

GRANT EXECUTE ON FUNCTION public.check_feature_permissions_batch(text[], text) TO anon;
GRANT EXECUTE ON FUNCTION public.check_feature_permissions_batch(text[], text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_feature_permissions_batch(text[], text) TO service_role;
