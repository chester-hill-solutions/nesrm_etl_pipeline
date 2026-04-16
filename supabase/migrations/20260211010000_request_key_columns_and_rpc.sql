-- Persist duplicate-detection keys on request so get_web_requests avoids per-row JSONB work.
-- Adds IMMUTABLE helpers and generated columns; then updates get_web_requests to use them.

-- 1) Helper: origin_key from origin + payload (referer/origin fallbacks)
CREATE OR REPLACE FUNCTION public.get_request_origin_key(p_origin text, p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT LOWER(TRIM(TRAILING '/' FROM COALESCE(
    CASE
      WHEN p_origin IS NOT NULL AND (p_origin LIKE 'http://%' OR p_origin LIKE 'https://%') THEN
        regexp_replace(p_origin, '(https?://[^/]+).*', '\1')
      ELSE p_origin
    END,
    CASE
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null'
        AND p_payload->'_meta'->>'referer' IS NOT NULL
        AND (p_payload->'_meta'->>'referer' LIKE 'http://%' OR p_payload->'_meta'->>'referer' LIKE 'https://%') THEN
        regexp_replace(p_payload->'_meta'->>'referer', '(https?://[^/]+).*', '\1')
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->'_meta'->>'referer' IS NOT NULL THEN
        p_payload->'_meta'->>'referer'
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->>'referer' IS NOT NULL
        AND (p_payload->>'referer' LIKE 'http://%' OR p_payload->>'referer' LIKE 'https://%') THEN
        regexp_replace(p_payload->>'referer', '(https?://[^/]+).*', '\1')
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->>'referer' IS NOT NULL THEN
        p_payload->>'referer'
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->>'origin' IS NOT NULL THEN
        p_payload->>'origin'
      ELSE 'no-origin'
    END
  )));
$$;

-- 2) Helper: step_index from payload (body._meta.step.index or _meta.step.index)
CREATE OR REPLACE FUNCTION public.get_request_step_index(p_payload jsonb)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT COALESCE(
    CASE
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->'body' IS NOT NULL THEN
        CASE
          WHEN jsonb_typeof(p_payload->'body') = 'string' THEN
            CASE
              WHEN (p_payload->'body')::text::jsonb->'_meta'->'step'->>'index' IS NOT NULL THEN
                ((p_payload->'body')::text::jsonb->'_meta'->'step'->>'index')::integer
              ELSE NULL
            END
          WHEN jsonb_typeof(p_payload->'body') = 'object' THEN
            CASE
              WHEN p_payload->'body'->'_meta'->'step'->>'index' IS NOT NULL THEN
                (p_payload->'body'->'_meta'->'step'->>'index')::integer
              ELSE NULL
            END
          ELSE NULL
        END
      ELSE NULL
    END,
    CASE
      WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->'_meta'->'step'->>'index' IS NOT NULL THEN
        (p_payload->'_meta'->'step'->>'index')::integer
      ELSE NULL
    END
  );
$$;

-- 3) Helper: name_key from payload (firstname|surname)
CREATE OR REPLACE FUNCTION public.get_request_name_key(p_payload jsonb)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE
    WHEN p_payload IS NOT NULL AND p_payload::text != 'null' AND p_payload->'body' IS NOT NULL THEN
      CASE
        WHEN jsonb_typeof(p_payload->'body') = 'string' THEN
          CASE
            WHEN (p_payload->'body')::text::jsonb->>'firstname' IS NOT NULL
              AND (p_payload->'body')::text::jsonb->>'surname' IS NOT NULL THEN
              LOWER(TRIM((p_payload->'body')::text::jsonb->>'firstname')) || '|' ||
              LOWER(TRIM((p_payload->'body')::text::jsonb->>'surname'))
            ELSE NULL
          END
        WHEN jsonb_typeof(p_payload->'body') = 'object' THEN
          CASE
            WHEN p_payload->'body'->>'firstname' IS NOT NULL AND p_payload->'body'->>'surname' IS NOT NULL THEN
              LOWER(TRIM(p_payload->'body'->>'firstname')) || '|' || LOWER(TRIM(p_payload->'body'->>'surname'))
            ELSE NULL
          END
        ELSE NULL
      END
    WHEN p_payload IS NOT NULL AND p_payload::text != 'null'
      AND p_payload->>'firstname' IS NOT NULL AND p_payload->>'surname' IS NOT NULL THEN
      LOWER(TRIM(p_payload->>'firstname')) || '|' || LOWER(TRIM(p_payload->>'surname'))
    ELSE NULL
  END;
$$;

-- 4) Add generated columns to request (backfilled automatically; one per statement for compatibility).
-- Table request already has: id, created_at, origin, payload, ip, email, success, logs, status, category, notes, contact_id, step, utm_*, search_params, referer. We add key columns used by get_web_requests (no name clash with existing "step").
ALTER TABLE public.request
  ADD COLUMN IF NOT EXISTS ip_key text GENERATED ALWAYS AS (
    COALESCE(
      CASE
        WHEN ip IS NOT NULL AND ip LIKE '%,%' THEN TRIM(SPLIT_PART(ip, ',', 1))
        ELSE ip
      END,
      'no-ip'
    )
  ) STORED;
ALTER TABLE public.request
  ADD COLUMN IF NOT EXISTS origin_key text GENERATED ALWAYS AS (
    public.get_request_origin_key(origin, payload)
  ) STORED;
ALTER TABLE public.request
  ADD COLUMN IF NOT EXISTS email_key text GENERATED ALWAYS AS (
    LOWER(TRIM(COALESCE(email, '')))
  ) STORED;
ALTER TABLE public.request
  ADD COLUMN IF NOT EXISTS step_index int GENERATED ALWAYS AS (
    public.get_request_step_index(payload)
  ) STORED;
ALTER TABLE public.request
  ADD COLUMN IF NOT EXISTS name_key text GENERATED ALWAYS AS (
    public.get_request_name_key(payload)
  ) STORED;
ALTER TABLE public.request
  ADD COLUMN IF NOT EXISTS payload_length int GENERATED ALWAYS AS (
    length(payload::text)
  ) STORED;

-- 5) Replace get_web_requests so filtered_requests uses the new columns (no JSONB in hot path)
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
SET search_path = public
AS $$
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
        session_key
      FROM filtered_requests
    ),
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
        CASE
          WHEN name_key IS NOT NULL THEN
            session_key || ''_name_'' || name_key
          ELSE
            session_key || ''_no_name''
        END as group_key,
        (SELECT COUNT(DISTINCT s2.name_key)
         FROM grouped_by_email_origin s2
         WHERE s2.session_key = grouped_by_email_origin.session_key
           AND s2.name_key IS NOT NULL) as name_count,
        COUNT(*) FILTER (WHERE name_key IS NULL) OVER (PARTITION BY session_key) as no_name_count,
        COUNT(*) FILTER (WHERE name_key IS NOT NULL) OVER (PARTITION BY session_key) as named_count
      FROM grouped_by_email_origin
    ),
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
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
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
        MIN(created_at) OVER (PARTITION BY final_group_key) as group_start_time,
        MAX(created_at) OVER (PARTITION BY final_group_key) as group_end_time
      FROM merged_name_groups
    ),
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
          (t1.group_start_time <= t2.group_end_time + INTERVAL ''10 minutes''
           AND t1.group_end_time >= t2.group_start_time - INTERVAL ''10 minutes'')
        )
    ),
    merged_groups AS (
      SELECT
        tc.*,
        COALESCE(
          (SELECT MIN(LEAST(group1, group2))
           FROM overlapping_groups og
           WHERE og.group1 = tc.final_group_key OR og.group2 = tc.final_group_key),
          tc.final_group_key
        ) as merged_group_key
      FROM time_clustered tc
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
        status,
        category,
        notes,
        merged_group_key,
        ROW_NUMBER() OVER (
          PARTITION BY merged_group_key
          ORDER BY
            COALESCE(step_index, -1) DESC,
            payload_length DESC,
            created_at DESC
        ) as rn
      FROM merged_groups
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
$$;
