-- Ensure the special SSW ballot field exists before writing to it
ALTER TABLE public.contact
ADD COLUMN IF NOT EXISTS ssw_ballot1 text;

COMMENT ON COLUMN public.contact.ssw_ballot1 IS 'SSW Ballot 1 override field';
