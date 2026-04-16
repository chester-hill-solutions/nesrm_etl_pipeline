-- Upgrade get_web_requests RPC: include contact_id in return signature and selection
-- Preserves parameter and return contract for existing TypeScript callers.
-- Depends on: public.request (id, created_at, origin, payload, ip, email, success, status::enum, category, notes, contact_id), public.escape_search_for_ilike(p_val text).
-- Uses escape_search_for_ilike for search; validates sort columns and adds deterministic tie-breaker.

DROP FUNCTION IF EXISTS public.get_web_requests(
  boolean, -- filter_success
  text,    -- filter_status
  text,    -- filter_category
  timestamp with time zone, -- date_from
  timestamp with time zone, -- date_to
  text,    -- search_term
  text,    -- sort_by
  text,    -- sort_order
  integer, -- page_offset
  integer, -- page_limit
  boolean  -- show_duplicates
);

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
  referer text,
  contact_id bigint,
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
  -- Normalize and validate sort: allowlist matches TS (created_at, email, success, status, category)
  v_sort_by := CASE
    WHEN sort_by IS NOT NULL AND LOWER(TRIM(sort_by)) IN ('created_at', 'email', 'success', 'status', 'category')
    THEN LOWER(TRIM(sort_by))
    ELSE 'created_at'
  END;
  v_sort_order := CASE
    WHEN sort_order IS NOT NULL AND LOWER(TRIM(sort_order)) = 'asc' THEN 'asc'
    ELSE 'desc'
  END;

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
        r.referer,
        r.contact_id,
        COALESCE(
          CASE 
            WHEN r.ip IS NOT NULL AND r.ip LIKE ''%,%'' THEN
              TRIM(SPLIT_PART(r.ip, '','', 1))
            ELSE r.ip
          END,
          ''no-ip''
        ) as ip_key,
        LOWER(
          TRIM(TRAILING ''/'' FROM
            COALESCE(
              CASE 
                WHEN r.origin IS NOT NULL AND (r.origin LIKE ''http://%'' OR r.origin LIKE ''https://%'' ) THEN
                  regexp_replace(r.origin, ''(https?://[^/]+).*'', ''\1'')
                ELSE r.origin
              END,
              CASE 
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL 
                  AND (r.payload->''_meta''->>''referer'' LIKE ''http://%'' OR r.payload->''_meta''->>''referer'' LIKE ''https://%'' ) THEN
                  regexp_replace(r.payload->''_meta''->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL THEN
                  r.payload->''_meta''->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL 
                  AND (r.payload->>''referer'' LIKE ''http://%'' OR r.payload->>''referer'' LIKE ''https://%'' ) THEN
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
        LOWER(TRIM(COALESCE(r.email, ''''))) as email_key,
        COALESCE(
          CASE 
            WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
              AND r.payload->''body'' IS NOT NULL THEN
              CASE
                WHEN jsonb_typeof(r.payload->''body'') = ''string'' THEN
                  CASE
                    WHEN (r.payload->''body'')::text::jsonb->''_meta''->>''step''->>''index'' IS NOT NULL THEN
                      ((r.payload->''body'')::text::jsonb->''_meta''->>''step''->>''index'')::integer
                    ELSE NULL
                  END
                WHEN jsonb_typeof(r.payload->''body'') = ''object'' THEN
                  CASE
                    WHEN r.payload->''body''->''_meta''->>''step''->>''index'' IS NOT NULL THEN
                      (r.payload->''body''->''_meta''->>''step''->>''index'')::integer
                    ELSE NULL
                  END
                ELSE NULL
              END
            ELSE NULL
          END,
          CASE
            WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
              AND r.payload->''_meta''->>''step''->>''index'' IS NOT NULL THEN
              (r.payload->''_meta''->>''step''->>''index'')::integer
            ELSE NULL
          END
        ) as step_index,
        CASE
          WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
            AND r.payload->''body'' IS NOT NULL THEN
            CASE
              WHEN jsonb_typeof(r.payload->''body'') = ''string'' THEN
                CASE
                  WHEN (r.payload->''body'')::text::jsonb->>''firstname'' IS NOT NULL
                    AND (r.payload->''body'')::text::jsonb->>''surname'' IS NOT NULL THEN
                    LOWER(TRIM((r.payload->''body'')::text::jsonb->>''firstname'')) || ''|'' || 
                    LOWER(TRIM((r.payload->''body'')::text::jsonb->>''surname''))
                  ELSE NULL
                END
              WHEN jsonb_typeof(r.payload->''body'') = ''object'' THEN
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
        length(r.payload::text) as payload_length
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

  base_query := base_query || '\n    ),\n    grouped_by_email_origin AS (\n      SELECT \n        id,\n        created_at,\n        origin,\n        payload,\n        ip,\n        email,\n        success,\n        status,\n        category,\n        notes,
      referer,\n        contact_id,\n        ip_key,\n        origin_key,\n        email_key,\n        step_index,\n        name_key,\n        payload_length,\n        CASE\n          WHEN email_key IS NOT NULL AND email_key != '' THEN\n            email_key || ''|'' || origin_key\n          ELSE\n            ip_key || ''|'' || origin_key\n        END as session_key\n      FROM filtered_requests\n    ),\n    final_requests AS (\n      SELECT \n        fr.id,\n        fr.created_at,\n        fr.origin,\n        fr.payload,\n        fr.ip,\n        fr.email,\n        fr.success,\n        fr.status,\n        fr.category,\n        fr.notes,
        r.referer,\n        fr.contact_id,\n        fr.total_count,\n        CASE WHEN fr.rn > 1 THEN true ELSE false END as is_duplicate\n      FROM (\n        SELECT *, ROW_NUMBER() OVER (PARTITION BY merged_group_key ORDER BY created_at DESC) as rn\n        FROM (\n          SELECT id, created_at, origin, payload, ip, email, success, status,\n                 category, notes, contact_id,\n                 MAX(total_count) OVER () as total_count,\n                 merged_group_key, is_duplicate\n          FROM final_requests_base\n        ) sub_merged\n      ) fr\n    )\n    SELECT \n      id,\n      created_at,\n      origin,\n      payload,\n      ip,\n      email,\n      success,\n      status,\n      category,\n      notes,
      referer,\n      contact_id,\n      total_count,\n      is_duplicate\n    FROM final_requests';

  -- Deterministic sort: validated column + id tie-breaker
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
