-- Add referer tracking to requests
ALTER TABLE IF EXISTS public.request
ADD COLUMN IF NOT EXISTS referer text;

COMMENT ON COLUMN public.request.referer IS 'Raw referer header captured from incoming request.';
