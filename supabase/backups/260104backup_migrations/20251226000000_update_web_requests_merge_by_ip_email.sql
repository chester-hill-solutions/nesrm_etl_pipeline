-- Update get_web_requests function to merge requests by IP + email within 10 minutes
-- Instead of email + category within 1 hour
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
        COALESCE(r.ip, ''no-ip'') as ip_key,
        COALESCE(r.email, ''no-email'') as email_key
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
    grouped_requests AS (
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
        ip_key,
        email_key,
        length(payload::text) as payload_length,
        MIN(created_at) OVER (
          PARTITION BY ip_key, email_key
        ) as first_in_group
      FROM filtered_requests
    ),
    requests_in_window AS (
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
        ip_key,
        email_key,
        payload_length,
        first_in_group
      FROM grouped_requests
      WHERE (created_at - first_in_group) <= INTERVAL ''10 minutes''
    ),
    requests_outside_window AS (
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
        ip_key,
        email_key,
        payload_length,
        first_in_group
      FROM grouped_requests
      WHERE (created_at - first_in_group) > INTERVAL ''10 minutes''
    ),
    ranked_requests_in_window AS (
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
        ROW_NUMBER() OVER (
          PARTITION BY ip_key, email_key
          ORDER BY payload_length DESC, created_at ASC
        ) as rn
      FROM requests_in_window
    ),
    merged_requests AS (
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
        notes
      FROM ranked_requests_in_window
      WHERE rn = 1
      UNION ALL
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
        notes
      FROM requests_outside_window
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
      FROM merged_requests
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

