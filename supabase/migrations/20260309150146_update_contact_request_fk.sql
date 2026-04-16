-- Update FK delete behavior to NO ACTION
-- File: supabase/migrations/<timestamp>_set_contact_request_fks_no_action.sql

BEGIN;

ALTER TABLE public.contact
DROP CONSTRAINT IF EXISTS contact_last_request_fkey;

ALTER TABLE public.request
DROP CONSTRAINT IF EXISTS request_contact_id_fkey;

ALTER TABLE public.contact
ADD CONSTRAINT contact_last_request_fkey
FOREIGN KEY (last_request)
REFERENCES public.request(id)
ON UPDATE CASCADE
ON DELETE NO ACTION;

ALTER TABLE public.request
ADD CONSTRAINT request_contact_id_fkey
FOREIGN KEY (contact_id)
REFERENCES public.contact(id)
ON UPDATE CASCADE
ON DELETE NO ACTION;

COMMIT;
