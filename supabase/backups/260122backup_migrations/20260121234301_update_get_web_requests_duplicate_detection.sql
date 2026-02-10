-- Update get_web_requests RPC to implement full duplicate detection logic
-- This moves duplicate detection from TypeScript to SQL so pagination works correctly

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
  page_limit integer DEFAULT 25,
  show_duplicates boolean DEFAULT false
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
  total_count bigint,
  is_duplicate boolean
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  base_query text;
BEGIN
  -- Build base query with filters and duplicate detection
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
        -- Extract first IP from comma-separated string
        COALESCE(
          CASE 
            WHEN r.ip IS NOT NULL AND r.ip LIKE ''%,%'' THEN
              TRIM(SPLIT_PART(r.ip, '','', 1))
            ELSE r.ip
          END,
          ''no-ip''
        ) as ip_key,
        -- Normalize origin (scheme + host, lowercase, no trailing slash)
        LOWER(
          TRIM(TRAILING ''/'' FROM
            COALESCE(
              CASE 
                WHEN r.origin IS NOT NULL AND (r.origin LIKE ''http://%'' OR r.origin LIKE ''https://%'') THEN
                  regexp_replace(r.origin, ''(https?://[^/]+).*'', ''\1'')
                ELSE r.origin
              END,
              CASE 
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL 
                  AND (r.payload->''_meta''->>''referer'' LIKE ''http://%'' OR r.payload->''_meta''->>''referer'' LIKE ''https://%'') THEN
                  regexp_replace(r.payload->''_meta''->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL THEN
                  r.payload->''_meta''->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL 
                  AND (r.payload->>''referer'' LIKE ''http://%'' OR r.payload->>''referer'' LIKE ''https://%'') THEN
                  regexp_replace(r.payload->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL THEN
                  r.payload->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''origin'' IS NOT NULL THEN
                  r.payload->>''origin''
                ELSE ''no-origin''
              END
            )
          )
        ) as origin_key,
        -- Normalize email to lowercase
        LOWER(TRIM(COALESCE(r.email, ''''))) as email_key,
        -- Extract step index from payload (try body._meta.step.index first, then _meta.step.index)
        COALESCE(
          CASE 
            WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
              AND r.payload->''body'' IS NOT NULL THEN
              CASE
                WHEN jsonb_typeof(r.payload->''body'') = ''string'' THEN
                  -- body is a JSON string, try to parse it
                  CASE
                    WHEN (r.payload->''body'')::text::jsonb->''_meta''->''step''->>''index'' IS NOT NULL THEN
                      ((r.payload->''body'')::text::jsonb->''_meta''->''step''->>''index'')::integer
                    ELSE NULL
                  END
                WHEN jsonb_typeof(r.payload->''body'') = ''object'' THEN
                  -- body is a JSON object
                  CASE
                    WHEN r.payload->''body''->''_meta''->''step''->>''index'' IS NOT NULL THEN
                      (r.payload->''body''->''_meta''->''step''->>''index'')::integer
                    ELSE NULL
                  END
                ELSE NULL
              END
            ELSE NULL
          END,
          CASE
            WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
              AND r.payload->''_meta''->''step''->>''index'' IS NOT NULL THEN
              (r.payload->''_meta''->''step''->>''index'')::integer
            ELSE NULL
          END
        ) as step_index,
        -- Extract name (firstname + surname) from payload
        -- Try body.firstname + body.surname first, then root-level
        CASE
          WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
            AND r.payload->''body'' IS NOT NULL THEN
            CASE
              WHEN jsonb_typeof(r.payload->''body'') = ''string'' THEN
                -- body is a JSON string, try to parse it
                CASE
                  WHEN (r.payload->''body'')::text::jsonb->>''firstname'' IS NOT NULL
                    AND (r.payload->''body'')::text::jsonb->>''surname'' IS NOT NULL THEN
                    LOWER(TRIM((r.payload->''body'')::text::jsonb->>''firstname'')) || ''|'' || 
                    LOWER(TRIM((r.payload->''body'')::text::jsonb->>''surname''))
                  ELSE NULL
                END
              WHEN jsonb_typeof(r.payload->''body'') = ''object'' THEN
                -- body is a JSON object
                CASE
                  WHEN r.payload->''body''->>''firstname'' IS NOT NULL
                    AND r.payload->''body''->>''surname'' IS NOT NULL THEN
                    LOWER(TRIM(r.payload->''body''->>''firstname'')) || ''|'' || 
                    LOWER(TRIM(r.payload->''body''->>''surname''))
                  ELSE NULL
                END
              ELSE NULL
            END
          WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
            AND r.payload->>''firstname'' IS NOT NULL
            AND r.payload->>''surname'' IS NOT NULL THEN
            LOWER(TRIM(r.payload->>''firstname'')) || ''|'' || LOWER(TRIM(r.payload->>''surname''))
          ELSE NULL
        END as name_key,
        -- Payload length for ranking
        length(r.payload::text) as payload_length
      FROM request r
      WHERE 1=1';
  
  -- Add filters
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
  
  -- Continue with grouping and duplicate detection
  base_query := base_query || '
    ),
    -- Group by email+origin (or ip+origin if no email)
    grouped_by_email_origin AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        ip_key,
        origin_key,
        email_key,
        step_index,
        name_key,
        payload_length,
        -- Create session key: email|origin or ip|origin
        CASE
          WHEN email_key IS NOT NULL AND email_key != '''' THEN
            email_key || ''|'' || origin_key
          ELSE
            ip_key || ''|'' || origin_key
        END as session_key
      FROM filtered_requests
    ),
    -- Split groups by name if different names exist
    split_by_name AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        ip_key,
        origin_key,
        email_key,
        step_index,
        name_key,
        payload_length,
        session_key,
        -- Create final group key: session_key_name_<name> or session_key_no_name
        CASE
          WHEN name_key IS NOT NULL THEN
            session_key || ''_name_'' || name_key
          ELSE
            session_key || ''_no_name''
        END as group_key,
        -- Count distinct names per session to determine if splitting is needed
        (SELECT COUNT(DISTINCT s2.name_key) 
         FROM grouped_by_email_origin s2 
         WHERE s2.session_key = grouped_by_email_origin.session_key 
           AND s2.name_key IS NOT NULL) as name_count,
        -- Count of no-name requests per session
        COUNT(*) FILTER (WHERE name_key IS NULL) OVER (PARTITION BY session_key) as no_name_count,
        -- Count of named requests per session
        COUNT(*) FILTER (WHERE name_key IS NOT NULL) OVER (PARTITION BY session_key) as named_count
      FROM grouped_by_email_origin
    ),
    -- Merge no-name requests with single named group (step 0 with later steps)
    merged_name_groups AS (
      SELECT 
        sbn.id,
        sbn.created_at,
        sbn.origin,
        sbn.payload,
        sbn.ip,
        sbn.email,
        sbn.success,
        sbn.status,
        sbn.category,
        sbn.notes,
        sbn.ip_key,
        sbn.origin_key,
        sbn.email_key,
        sbn.step_index,
        sbn.name_key,
        sbn.payload_length,
        sbn.session_key,
        sbn.name_count,
        sbn.no_name_count,
        sbn.named_count,
        sbn.group_key,
        CASE
          -- If only one named group and some no-name requests, merge them
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
            -- Find the single name key in this session
            (SELECT DISTINCT s2.name_key FROM split_by_name s2 
             WHERE s2.session_key = sbn.session_key AND s2.name_key IS NOT NULL 
             LIMIT 1)
          ELSE
            sbn.name_key
        END as merged_name_key,
        CASE
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
            sbn.session_key || ''_name_'' || 
            (SELECT DISTINCT s2.name_key FROM split_by_name s2 
             WHERE s2.session_key = sbn.session_key AND s2.name_key IS NOT NULL 
             LIMIT 1)
          ELSE
            sbn.group_key
        END as final_group_key
      FROM split_by_name sbn
    ),
    -- Merge groups with same email+origin+name that overlap in time (10-minute windows)
    -- This handles IP changes during form submission
    time_clustered AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        ip_key,
        origin_key,
        email_key,
        step_index,
        name_key,
        payload_length,
        session_key,
        merged_name_key,
        final_group_key,
        -- Find the earliest request in each final_group_key
        MIN(created_at) OVER (PARTITION BY final_group_key) as group_start_time,
        -- Find the latest request in each final_group_key
        MAX(created_at) OVER (PARTITION BY final_group_key) as group_end_time
      FROM merged_name_groups
    ),
    -- Identify overlapping groups (same email+origin+name, different IPs, within 10 minutes)
    overlapping_groups AS (
      SELECT DISTINCT
        t1.final_group_key as group1,
        t2.final_group_key as group2
      FROM time_clustered t1
      JOIN time_clustered t2 ON 
        t1.email_key = t2.email_key
        AND t1.origin_key = t2.origin_key
        AND t1.merged_name_key = t2.merged_name_key
        AND t1.final_group_key < t2.final_group_key
        AND (
          -- Groups overlap if their time ranges are within 10 minutes
          (t1.group_start_time <= t2.group_end_time + INTERVAL ''10 minutes''
           AND t1.group_end_time >= t2.group_start_time - INTERVAL ''10 minutes'')
        )
    ),
    -- Create merged group keys for overlapping groups
    merged_groups AS (
      SELECT 
        tc.*,
        COALESCE(
          -- Use the first group key if this group overlaps with others
          (SELECT MIN(LEAST(group1, group2)) 
           FROM overlapping_groups og 
           WHERE og.group1 = tc.final_group_key OR og.group2 = tc.final_group_key),
          tc.final_group_key
        ) as merged_group_key
      FROM time_clustered tc
    ),
    -- Rank requests within each merged group
    ranked_requests AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        merged_group_key,
        ROW_NUMBER() OVER (
          PARTITION BY merged_group_key
          ORDER BY 
            COALESCE(step_index, -1) DESC,  -- Prefer highest step index
            payload_length DESC,              -- Then longest payload
            created_at DESC                   -- Then most recent
        ) as rn
      FROM merged_groups
    ),
    -- Calculate total count before filtering
    total_count_cte AS (
      SELECT COUNT(DISTINCT merged_group_key) as total_count
      FROM ranked_requests
      WHERE rn = 1
    ),
    -- Final selection based on show_duplicates flag
    final_requests AS (
      SELECT 
        rr.id,
        rr.created_at,
        rr.origin,
        rr.payload,
        rr.ip,
        rr.email,
        rr.success,
        rr.status,
        rr.category,
        rr.notes,
        (SELECT total_count FROM total_count_cte) as total_count,
        CASE WHEN rr.rn > 1 THEN true ELSE false END as is_duplicate
      FROM ranked_requests rr
    ),
    filtered_final AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        MAX(total_count) OVER () as total_count,
        is_duplicate
      FROM final_requests
      WHERE ' || (CASE WHEN show_duplicates THEN 'true' ELSE 'is_duplicate = false' END) || '
    )
    SELECT 
      id,
      created_at,
      origin,
      payload,
      ip,
      email,
      success,
      status,
      category,
      notes,
      MAX(total_count) OVER () as total_count,
      is_duplicate
    FROM filtered_final';
  
  -- Add sorting
  IF sort_by IS NOT NULL AND sort_by != '' THEN
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

ALTER FUNCTION public.get_web_requests(
  filter_success boolean,
  filter_status text,
  filter_category text,
  date_from timestamp with time zone,
  date_to timestamp with time zone,
  search_term text,
  sort_by text,
  sort_order text,
  page_offset integer,
  page_limit integer,
  show_duplicates boolean
) OWNER TO postgres;
