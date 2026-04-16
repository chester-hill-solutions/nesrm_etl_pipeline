-- Optimize web requests list/dashboard: composite indexes for common filters and sort,
-- and trigram index for email ILIKE search. Used by get_web_requests RPC and manual fallback.

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

CREATE INDEX IF NOT EXISTS request_status_created_at_idx
ON public.request (status, created_at DESC)
WHERE status IS NOT NULL;

CREATE INDEX IF NOT EXISTS request_category_created_at_idx
ON public.request (category, created_at DESC)
WHERE category IS NOT NULL;

CREATE INDEX IF NOT EXISTS request_success_created_at_idx
ON public.request (success, created_at DESC)
WHERE success IS NOT NULL;

-- GIN trigram index for request.email to speed ILIKE '%term%' in get_web_requests.
-- pg_trgm is created in schema extensions, so opclass is extensions.gin_trgm_ops.
CREATE INDEX IF NOT EXISTS request_email_trgm_idx
ON public.request USING gin (email extensions.gin_trgm_ops)
WHERE email IS NOT NULL;

-- To validate index usage after applying, run (with real params) and check for index scans:
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM get_web_requests(NULL, 'complete', NULL, NULL, NULL, 'test', 'created_at', 'desc', 0, 25, false);
