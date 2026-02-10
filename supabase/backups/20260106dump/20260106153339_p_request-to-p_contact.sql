-- Link public.request records to public.contact
ALTER TABLE public.request
ADD COLUMN IF NOT EXISTS contact_id bigint;

-- Add FK constraint if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'request_contact_id_fkey'
      AND conrelid = 'public.request'::regclass
  ) THEN
    ALTER TABLE public.request
    ADD CONSTRAINT request_contact_id_fkey
    FOREIGN KEY (contact_id)
    REFERENCES public.contact(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL;
  END IF;
END $$;

-- Helpful lookup index
CREATE INDEX IF NOT EXISTS idx_request_contact_id ON public.request (contact_id);
