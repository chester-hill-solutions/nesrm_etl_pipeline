-- Link web requests to contacts
ALTER TABLE public.request
ADD COLUMN IF NOT EXISTS contact_id bigint;

-- Add FK to contacts (keep requests when contact deleted)
ALTER TABLE public.request
ADD CONSTRAINT request_contact_id_fkey
FOREIGN KEY (contact_id)
REFERENCES public.contact(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

-- Helpful index for lookups
CREATE INDEX IF NOT EXISTS idx_request_contact_id ON public.request (contact_id);
