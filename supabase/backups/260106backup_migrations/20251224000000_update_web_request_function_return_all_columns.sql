-- Update function to return all columns needed and handle sorting/pagination
-- This eliminates the need for multiple queries
-- Renamed from get_non_duplicate_request_ids to get_web_requests to reflect that it returns full data
CREATE OR REPLACE FUNCTION public.get_web_requests(
  filter_success boolean DEFAULT NULL,
  filter_status text DEFAULT NULL,
  filter_category text DEFAULT NULL,
  date_from timestamp with time zone DEFAULT NULL,
  date_to timestamp with time zone DEFAULT NULL,
  search_term text DEFAULT NULL,
  sort_by text DEFAULT 'created_at',
  sort_order text DEFAULT 'desc',
  page_offset integer DEFAULT 0,
  page_limit integer DEFAULT 25
)
RETURNS TABLE(
  id bigint,
  created_at timestamp with time zone,
  origin text,
  payload jsonb,
  ip text,
  email text,
  success boolean,
  status text,
  category text,
  notes text,
  total_count bigint
)
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
        r.created_at,
        r.origin,
        r.payload,
        r.ip,
        r.email,
        r.success,
        r.status::text,
        r.category::text,
        r.notes,
        COALESCE(r.email, ''no-email'') as email_key,
        COALESCE(r.category, ''no-category'') as category_key
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
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        email_key,
        category_key,
        ROW_NUMBER() OVER (
          PARTITION BY email_key, category_key
          ORDER BY created_at ASC
        ) as rn,
        MIN(created_at) OVER (
          PARTITION BY email_key, category_key
        ) as first_in_group
      FROM filtered_requests
    ),
    non_duplicate_requests AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        COUNT(*) OVER () as total_count
      FROM ranked_requests
      WHERE rn = 1 
         OR (created_at - first_in_group) > INTERVAL ''1 hour''
    )
    SELECT 
      id,
      created_at,
      origin,
      payload,
      ip,
      email,
      success,
      status::text,
      category::text,
      notes,
      MAX(total_count) OVER () as total_count
    FROM non_duplicate_requests';
  
  -- Add sorting
  IF sort_by IS NOT NULL AND sort_by != '' THEN
    -- Validate sort_by to prevent SQL injection
    IF sort_by IN ('id', 'created_at', 'email', 'success', 'status', 'category') THEN
      IF sort_order = 'asc' THEN
        base_query := base_query || format(' ORDER BY %I ASC', sort_by);
      ELSE
        base_query := base_query || format(' ORDER BY %I DESC', sort_by);
      END IF;
    ELSE
      base_query := base_query || ' ORDER BY created_at DESC';
    END IF;
  ELSE
    base_query := base_query || ' ORDER BY created_at DESC';
  END IF;
  
  -- Add pagination
  IF page_limit > 0 THEN
    base_query := base_query || ' LIMIT ' || page_limit::text;
    IF page_offset > 0 THEN
      base_query := base_query || ' OFFSET ' || page_offset::text;
    END IF;
  END IF;
  
  base_query := base_query || ';';
  
  RETURN QUERY EXECUTE base_query;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_web_requests TO authenticated;
GRANT EXECUTE ON FUNCTION get_web_requests TO service_role;

-- Drop old function if it exists (from previous migration)
DROP FUNCTION IF EXISTS public.get_non_duplicate_request_ids(
  filter_success boolean,
  filter_status text,
  filter_category text,
  date_from timestamp with time zone,
  date_to timestamp with time zone,
  search_term text
);

