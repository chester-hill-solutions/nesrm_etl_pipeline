-- Add nullable organizer_codes array to contacts
alter table public.contact
  add column if not exists organizer_codes text[];
