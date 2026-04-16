-- Scoped filter count and full id materialization: same candidate selection as
-- load_contact_dashboard_page_payload_optimized (scoped_ids + filter), without search/swipe/pagination.

CREATE OR REPLACE FUNCTION public.resolve_scoped_filter_group_count(
  p_scope_type text,
  p_scope_values text[],
  p_filter_group jsonb
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_has_filter boolean;
  v_count bigint;
BEGIN
  v_has_filter :=
    p_filter_group IS NOT NULL
    AND jsonb_typeof(p_filter_group) = 'object'
    AND (p_filter_group->'children') IS NOT NULL
    AND jsonb_array_length(p_filter_group->'children') > 0;

  WITH scoped_ids AS (
    SELECT c.id
    FROM public.contact c
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        (
          COALESCE(TRIM(p_scope_type), 'all_contacts') = 'all_contacts'
          AND (p_scope_values IS NULL OR cardinality(p_scope_values) = 0)
        )
        OR (
          p_scope_type = 'riding'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND c.division_electoral_district = ANY(p_scope_values)
        )
        OR (
          p_scope_type = 'campus'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND c.campus_club = ANY(p_scope_values)
        )
        OR (
          p_scope_type = 'signups'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND (
            EXISTS (
              SELECT 1
              FROM unnest(regexp_split_to_array(lower(COALESCE(c.organizer, '')), '[^a-z0-9_-]+')) AS t(token)
              WHERE TRIM(t.token) <> ''
                AND TRIM(t.token) IN (
                  SELECT lower(TRIM(x)) FROM unnest(p_scope_values) AS x WHERE TRIM(x) <> ''
                )
            )
          )
        )
      )
  ),
  filtered_ids AS (
    SELECT s.id
    FROM scoped_ids s
    WHERE NOT v_has_filter
      OR EXISTS (
        SELECT 1
        FROM public.resolve_filter_group(p_filter_group) AS f(id)
        WHERE f.id = s.id
      )
  )
  SELECT COUNT(*)::bigint INTO v_count FROM filtered_ids;

  RETURN COALESCE(v_count, 0);
END;
$$;

COMMENT ON FUNCTION public.resolve_scoped_filter_group_count(text, text[], jsonb) IS
  'Count contacts matching p_filter_group within riding/campus/signups/all_contacts scope (dashboard-aligned).';

CREATE OR REPLACE FUNCTION public.resolve_scoped_filter_group_id_array(
  p_scope_type text,
  p_scope_values text[],
  p_filter_group jsonb
)
RETURNS bigint[]
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_has_filter boolean;
  v_ids bigint[];
BEGIN
  v_has_filter :=
    p_filter_group IS NOT NULL
    AND jsonb_typeof(p_filter_group) = 'object'
    AND (p_filter_group->'children') IS NOT NULL
    AND jsonb_array_length(p_filter_group->'children') > 0;

  WITH scoped_ids AS (
    SELECT c.id
    FROM public.contact c
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        (
          COALESCE(TRIM(p_scope_type), 'all_contacts') = 'all_contacts'
          AND (p_scope_values IS NULL OR cardinality(p_scope_values) = 0)
        )
        OR (
          p_scope_type = 'riding'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND c.division_electoral_district = ANY(p_scope_values)
        )
        OR (
          p_scope_type = 'campus'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND c.campus_club = ANY(p_scope_values)
        )
        OR (
          p_scope_type = 'signups'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND (
            EXISTS (
              SELECT 1
              FROM unnest(regexp_split_to_array(lower(COALESCE(c.organizer, '')), '[^a-z0-9_-]+')) AS t(token)
              WHERE TRIM(t.token) <> ''
                AND TRIM(t.token) IN (
                  SELECT lower(TRIM(x)) FROM unnest(p_scope_values) AS x WHERE TRIM(x) <> ''
                )
            )
          )
        )
      )
  ),
  filtered_ids AS (
    SELECT s.id
    FROM scoped_ids s
    WHERE NOT v_has_filter
      OR EXISTS (
        SELECT 1
        FROM public.resolve_filter_group(p_filter_group) AS f(id)
        WHERE f.id = s.id
      )
  )
  SELECT COALESCE(array_agg(id ORDER BY id), ARRAY[]::bigint[]) INTO v_ids FROM filtered_ids;

  RETURN COALESCE(v_ids, ARRAY[]::bigint[]);
END;
$$;

COMMENT ON FUNCTION public.resolve_scoped_filter_group_id_array(text, text[], jsonb) IS
  'All contact ids matching p_filter_group within scope (single array row; not subject to PostgREST max_rows on SETOF).';

GRANT EXECUTE ON FUNCTION public.resolve_scoped_filter_group_count(text, text[], jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_scoped_filter_group_count(text, text[], jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.resolve_scoped_filter_group_id_array(text, text[], jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_scoped_filter_group_id_array(text, text[], jsonb) TO service_role;
