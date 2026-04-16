DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'contact_last_request_fkey'
      AND conrelid = 'public.contact'::regclass
  ) THEN
    ALTER TABLE public.contact
      DROP CONSTRAINT contact_last_request_fkey;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'contact_last_request_fkey'
      AND conrelid = 'public.contact'::regclass
  ) THEN
    ALTER TABLE public.contact
      ADD CONSTRAINT contact_last_request_fkey
      FOREIGN KEY (last_request)
        REFERENCES public.request(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL;
  END IF;
END $$;
