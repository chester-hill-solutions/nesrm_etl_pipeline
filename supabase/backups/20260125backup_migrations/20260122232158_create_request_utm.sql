-- Add UTM tracking fields to requests
ALTER TABLE IF EXISTS public.request
ADD COLUMN IF NOT EXISTS utm_source text,
ADD COLUMN IF NOT EXISTS utm_medium text,
ADD COLUMN IF NOT EXISTS utm_campaign text,
ADD COLUMN IF NOT EXISTS utm_term text[],
ADD COLUMN IF NOT EXISTS utm_content text,
ADD COLUMN IF NOT EXISTS search_params jsonb;
