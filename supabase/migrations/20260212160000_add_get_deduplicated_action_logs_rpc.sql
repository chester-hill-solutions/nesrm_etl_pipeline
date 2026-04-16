-- Create RPC function to fetch deduplicated action logs
-- Removes consecutive duplicate entries based on action_type, entity_type, entity_id, route, and success
-- Depends on: public.action_logs table

CREATE OR REPLACE FUNCTION public.get_deduplicated_action_logs(
  p_profile_id uuid DEFAULT NULL,
  p_entity_type text DEFAULT NULL,
  p_entity_id text DEFAULT NULL,
  p_action_type text DEFAULT NULL,
  p_date_from timestamp with time zone DEFAULT NULL,
  p_date_to timestamp with time zone DEFAULT NULL,
  p_sort_by text DEFAULT 'created_at',
  p_sort_order text DEFAULT 'desc',
  p_page_offset integer DEFAULT 0,
  p_page_limit integer DEFAULT 25
)
RETURNS TABLE(
  id uuid,
  profile_id uuid,
  action_type text,
  entity_type text,
  entity_id text,
  route text,
  success boolean,
  created_at timestamp with time zone,
  metadata jsonb,
  total_count bigint
)
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_sort_by text;
  v_sort_order text;
BEGIN
  -- Validate and normalize sort parameters
  v_sort_by := CASE
    WHEN p_sort_by IS NOT NULL AND LOWER(TRIM(p_sort_by)) IN ('created_at', 'action_type', 'entity_type')
    THEN LOWER(TRIM(p_sort_by))
    ELSE 'created_at'
  END;
  
  v_sort_order := CASE
    WHEN p_sort_order IS NOT NULL AND LOWER(TRIM(p_sort_order)) = 'asc' THEN 'ASC'
    ELSE 'DESC'
  END;

  -- Return deduplicated logs with total count
  RETURN QUERY
  WITH filtered_logs AS (
    SELECT
      al.id,
      al.profile_id,
      al.action_type,
      al.entity_type,
      al.entity_id,
      al.route,
      al.success,
      al.created_at,
      al.metadata
    FROM action_logs al
    WHERE
      (p_profile_id IS NULL OR al.profile_id = p_profile_id)
      AND (p_entity_type IS NULL OR al.entity_type = p_entity_type)
      AND (p_entity_id IS NULL OR al.entity_id = p_entity_id)
      AND (p_action_type IS NULL OR al.action_type = p_action_type)
      AND (p_date_from IS NULL OR al.created_at >= p_date_from)
      AND (p_date_to IS NULL OR al.created_at <= p_date_to)
  ),
  sorted_logs AS (
    SELECT
      fl.*,
      ROW_NUMBER() OVER (
        ORDER BY
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'DESC' THEN fl.created_at END DESC,
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'ASC' THEN fl.created_at END ASC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'DESC' THEN fl.action_type END DESC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'ASC' THEN fl.action_type END ASC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'DESC' THEN fl.entity_type END DESC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'ASC' THEN fl.entity_type END ASC,
          fl.id
      ) as row_num,
      LAG(fl.action_type) OVER (
        ORDER BY
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'DESC' THEN fl.created_at END DESC,
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'ASC' THEN fl.created_at END ASC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'DESC' THEN fl.action_type END DESC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'ASC' THEN fl.action_type END ASC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'DESC' THEN fl.entity_type END DESC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'ASC' THEN fl.entity_type END ASC,
          fl.id
      ) as prev_action_type,
      LAG(fl.entity_type) OVER (
        ORDER BY
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'DESC' THEN fl.created_at END DESC,
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'ASC' THEN fl.created_at END ASC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'DESC' THEN fl.action_type END DESC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'ASC' THEN fl.action_type END ASC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'DESC' THEN fl.entity_type END DESC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'ASC' THEN fl.entity_type END ASC,
          fl.id
      ) as prev_entity_type,
      LAG(fl.entity_id) OVER (
        ORDER BY
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'DESC' THEN fl.created_at END DESC,
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'ASC' THEN fl.created_at END ASC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'DESC' THEN fl.action_type END DESC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'ASC' THEN fl.action_type END ASC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'DESC' THEN fl.entity_type END DESC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'ASC' THEN fl.entity_type END ASC,
          fl.id
      ) as prev_entity_id,
      LAG(fl.route) OVER (
        ORDER BY
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'DESC' THEN fl.created_at END DESC,
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'ASC' THEN fl.created_at END ASC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'DESC' THEN fl.action_type END DESC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'ASC' THEN fl.action_type END ASC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'DESC' THEN fl.entity_type END DESC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'ASC' THEN fl.entity_type END ASC,
          fl.id
      ) as prev_route,
      LAG(fl.success) OVER (
        ORDER BY
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'DESC' THEN fl.created_at END DESC,
          CASE WHEN v_sort_by = 'created_at' AND v_sort_order = 'ASC' THEN fl.created_at END ASC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'DESC' THEN fl.action_type END DESC,
          CASE WHEN v_sort_by = 'action_type' AND v_sort_order = 'ASC' THEN fl.action_type END ASC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'DESC' THEN fl.entity_type END DESC,
          CASE WHEN v_sort_by = 'entity_type' AND v_sort_order = 'ASC' THEN fl.entity_type END ASC,
          fl.id
      ) as prev_success
    FROM filtered_logs fl
  ),
  deduplicated_logs AS (
    SELECT
      sl.id,
      sl.profile_id,
      sl.action_type,
      sl.entity_type,
      sl.entity_id,
      sl.route,
      sl.success,
      sl.created_at,
      sl.metadata,
      sl.row_num
    FROM sorted_logs sl
    WHERE
      -- Keep first row or rows that differ from previous
      sl.prev_action_type IS NULL
      OR sl.action_type != sl.prev_action_type
      OR sl.entity_type != sl.prev_entity_type
      OR COALESCE(sl.entity_id, '') != COALESCE(sl.prev_entity_id, '')
      OR sl.route != sl.prev_route
      OR sl.success != sl.prev_success
  ),
  paginated_logs AS (
    SELECT
      dl.*,
      COUNT(*) OVER () as total_count
    FROM deduplicated_logs dl
    ORDER BY dl.row_num
    LIMIT p_page_limit
    OFFSET p_page_offset
  )
  SELECT
    pl.id,
    pl.profile_id,
    pl.action_type,
    pl.entity_type,
    pl.entity_id,
    pl.route,
    pl.success,
    pl.created_at,
    pl.metadata,
    pl.total_count
  FROM paginated_logs pl;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_deduplicated_action_logs TO authenticated;

COMMENT ON FUNCTION public.get_deduplicated_action_logs IS 
'Fetches action logs with consecutive duplicates removed. Two entries are considered duplicates if they have the same action_type, entity_type, entity_id, route, and success status in sequence.';
