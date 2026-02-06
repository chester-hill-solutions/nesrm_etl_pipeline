-- Function to get non-duplicate web request IDs
-- Duplicates are identified as: same email + same category within 1 hour
-- The first request in each group is kept, others within 1 hour are considered duplicates
CREATE OR REPLACE FUNCTION public.get_non_duplicate_request_ids(
  filter_success boolean DEFAULT NULL,
  filter_status text DEFAULT NULL,
  filter_category text DEFAULT NULL,
  date_from timestamp with time zone DEFAULT NULL,
  date_to timestamp with time zone DEFAULT NULL,
  search_term text DEFAULT NULL
)
RETURNS TABLE(id integer)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  base_query text;
BEGIN
  -- Build base query with filters
  base_query := '
    WITH filtered_requests AS (
      SELECT 
        r.id,
        COALESCE(r.email, ''no-email'') as email_key,
        COALESCE(r.category, ''no-category'') as category_key,
        r.created_at
      FROM request r
      WHERE 1=1';
  
  IF filter_success IS NOT NULL THEN
    base_query := base_query || format(' AND r.success = %L', filter_success);
  END IF;
  
  IF filter_status IS NOT NULL THEN
    base_query := base_query || format(' AND r.status = %L', filter_status);
  END IF;
  
  IF filter_category IS NOT NULL THEN
    base_query := base_query || format(' AND r.category = %L', filter_category);
  END IF;
  
  IF date_from IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at >= %L', date_from);
  END IF;
  
  IF date_to IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at <= %L', date_to);
  END IF;
  
  IF search_term IS NOT NULL AND search_term != '' THEN
    base_query := base_query || format(' AND r.email ILIKE %L', '%' || search_term || '%');
  END IF;
  
  base_query := base_query || '
    ),
    ranked_requests AS (
      SELECT 
        id,
        email_key,
        category_key,
        created_at,
        ROW_NUMBER() OVER (
          PARTITION BY email_key, category_key
          ORDER BY created_at ASC
        ) as rn,
        MIN(created_at) OVER (
          PARTITION BY email_key, category_key
        ) as first_in_group
      FROM filtered_requests
    )
    SELECT id
    FROM ranked_requests
    WHERE rn = 1 
       OR (created_at - first_in_group) > INTERVAL ''1 hour'';
  ';
  
  RETURN QUERY EXECUTE base_query;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_non_duplicate_request_ids TO authenticated;
GRANT EXECUTE ON FUNCTION get_non_duplicate_request_ids TO service_role;

