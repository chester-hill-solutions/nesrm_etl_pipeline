-- Add new columns to public.contact
ALTER TABLE public.contact
ADD COLUMN olp_numeric_id BIGINT,
ADD COLUMN email_2 TEXT;
