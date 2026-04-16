-- Optimize get_web_requests RPC performance
-- Key changes:
-- - Remove correlated subqueries in split_by_name (pre-aggregate per session_key)
-- - Replace overlapping_groups self-join with window-based time clustering of group intervals
-- - Preserve signature, return shape, sorting allowlist, and total_count semantics

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
SET search_path TO 'public'
AS $function$
DECLARE
  base_query text;
  v_search_esc text;
  v_sort_by text;
  v_sort_order text;
BEGIN
  v_sort_by := CASE
    WHEN sort_by IS NOT NULL AND LOWER(TRIM(sort_by)) IN ('created_at', 'email', 'success', 'status', 'category')
    THEN LOWER(TRIM(sort_by))
    ELSE 'created_at'
  END;

  v_sort_order := CASE
    WHEN sort_order IS NOT NULL AND LOWER(TRIM(sort_order)) = 'asc' THEN 'asc'
    ELSE 'desc'
  END;

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
        r.ip_key,
        r.origin_key,
        r.email_key,
        r.step_index,
        r.name_key,
        r.payload_length,
        CASE
          WHEN r.email_key IS NOT NULL AND r.email_key != '''' THEN
            r.email_key || ''|'' || r.origin_key
          ELSE
            r.ip_key || ''|'' || r.origin_key
        END as session_key
      FROM request r
      WHERE 1=1';

  IF filter_success IS NOT NULL THEN
    base_query := base_query || format(' AND r.success = %L', filter_success);
  END IF;

  IF filter_status IS NOT NULL AND TRIM(filter_status) != '' THEN
    base_query := base_query || format(' AND r.status = %L', TRIM(filter_status));
  END IF;

  IF filter_category IS NOT NULL AND TRIM(filter_category) != '' THEN
    base_query := base_query || format(' AND r.category = %L', TRIM(filter_category));
  END IF;

  IF date_from IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at >= %L', date_from);
  END IF;

  IF date_to IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at <= %L', date_to);
  END IF;

  IF search_term IS NOT NULL AND TRIM(search_term) != '' THEN
    v_search_esc := public.escape_search_for_ilike(TRIM(search_term));
    base_query := base_query || format(' AND r.email ILIKE %L', '%' || v_search_esc || '%');
  END IF;

  base_query := base_query || '
    ),
    -- Pre-aggregate session-level name stats to avoid correlated subqueries
    session_name_stats AS (
      SELECT
        fr.session_key,
        COUNT(*) FILTER (WHERE fr.name_key IS NULL) as no_name_count,
        COUNT(*) FILTER (WHERE fr.name_key IS NOT NULL) as named_count,
        COUNT(DISTINCT fr.name_key) FILTER (WHERE fr.name_key IS NOT NULL) as name_count,
        MIN(fr.name_key) FILTER (WHERE fr.name_key IS NOT NULL) as single_name_key
      FROM filtered_requests fr
      GROUP BY fr.session_key
    ),
    split_by_name AS (
      SELECT
        fr.id,
        fr.created_at,
        fr.origin,
        fr.payload,
        fr.ip,
        fr.email,
        fr.success,
        fr.status,
        fr.category,
        fr.notes,
        fr.ip_key,
        fr.origin_key,
        fr.email_key,
        fr.step_index,
        fr.name_key,
        fr.payload_length,
        fr.session_key,
        CASE
          WHEN fr.name_key IS NOT NULL THEN
            fr.session_key || ''_name_'' || fr.name_key
          ELSE
            fr.session_key || ''_no_name''
        END as group_key,
        sns.name_count,
        sns.no_name_count,
        sns.named_count,
        sns.single_name_key
      FROM filtered_requests fr
      INNER JOIN session_name_stats sns ON sns.session_key = fr.session_key
    ),
    -- Merge no-name requests with the single named group (when it exists)
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
        CASE
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
            sbn.single_name_key
          ELSE
            sbn.name_key
        END as merged_name_key,
        CASE
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
            sbn.session_key || ''_name_'' || sbn.single_name_key
          ELSE
            sbn.group_key
        END as final_group_key
      FROM split_by_name sbn
    ),
    -- Collapse each final_group_key down to a single interval row (avoids exploding self-joins)
    group_intervals AS (
      SELECT
        mng.final_group_key,
        mng.email_key,
        mng.origin_key,
        mng.merged_name_key,
        MIN(mng.created_at) as group_start_time,
        MAX(mng.created_at) as group_end_time
      FROM merged_name_groups mng
      GROUP BY
        mng.final_group_key,
        mng.email_key,
        mng.origin_key,
        mng.merged_name_key
    ),
    ordered_intervals AS (
      SELECT
        gi.*,
        LAG(gi.group_end_time) OVER (
          PARTITION BY gi.email_key, gi.origin_key, gi.merged_name_key
          ORDER BY gi.group_start_time, gi.group_end_time, gi.final_group_key
        ) as prev_end_time
      FROM group_intervals gi
    ),
    clustered_intervals AS (
      SELECT
        oi.*,
        SUM(
          CASE
            WHEN oi.prev_end_time IS NULL THEN 1
            WHEN oi.group_start_time > oi.prev_end_time + INTERVAL ''10 minutes'' THEN 1
            ELSE 0
          END
        ) OVER (
          PARTITION BY oi.email_key, oi.origin_key, oi.merged_name_key
          ORDER BY oi.group_start_time, oi.group_end_time, oi.final_group_key
        ) as cluster_no
      FROM ordered_intervals oi
    ),
    merged_group_key_map AS (
      SELECT
        ci.final_group_key,
        MIN(ci.final_group_key) OVER (
          PARTITION BY ci.email_key, ci.origin_key, ci.merged_name_key, ci.cluster_no
        ) as merged_group_key
      FROM clustered_intervals ci
    ),
    merged_groups AS (
      SELECT
        mng.id,
        mng.created_at,
        mng.origin,
        mng.payload,
        mng.ip,
        mng.email,
        mng.success,
        mng.status,
        mng.category,
        mng.notes,
        mgkm.merged_group_key,
        mng.step_index,
        mng.payload_length
      FROM merged_name_groups mng
      INNER JOIN merged_group_key_map mgkm
        ON mgkm.final_group_key = mng.final_group_key
    ),
    ranked_requests AS (
      SELECT
        mg.id,
        mg.created_at,
        mg.origin,
        mg.payload,
        mg.ip,
        mg.email,
        mg.success,
        mg.status,
        mg.category,
        mg.notes,
        mg.merged_group_key,
        ROW_NUMBER() OVER (
          PARTITION BY mg.merged_group_key
          ORDER BY
            COALESCE(mg.step_index, -1) DESC,
            mg.payload_length DESC,
            mg.created_at DESC,
            mg.id DESC
        ) as rn
      FROM merged_groups mg
    ),
    total_count_cte AS (
      SELECT COUNT(DISTINCT merged_group_key) as total_count
      FROM ranked_requests
      WHERE rn = 1
    ),
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

  base_query := base_query || format(' ORDER BY %I %s, id %s', v_sort_by, v_sort_order, v_sort_order);

  IF page_limit > 0 THEN
    base_query := base_query || ' LIMIT ' || page_limit::text;
    IF page_offset > 0 THEN
      base_query := base_query || ' OFFSET ' || page_offset::text;
    END IF;
  END IF;

  base_query := base_query || ';';

  RETURN QUERY EXECUTE base_query;
END;
$function$;

-- Keep the legacy 10-arg overload in sync by delegating to the 11-arg function.
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
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
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
    total_count
  FROM public.get_web_requests(
    filter_success,
    filter_status,
    filter_category,
    date_from,
    date_to,
    search_term,
    sort_by,
    sort_order,
    page_offset,
    page_limit,
    false
  );
$$;

