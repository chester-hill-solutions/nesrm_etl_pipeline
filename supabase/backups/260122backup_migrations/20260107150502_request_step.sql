ALTER TABLE IF EXISTS public.request
ADD COLUMN IF NOT EXISTS step integer;
