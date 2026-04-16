alter table public.profiles
  add column if not exists organizer_code text;

update public.profiles
set organizer_code = organizer_tag
where organizer_code is null
  and organizer_tag is not null;
