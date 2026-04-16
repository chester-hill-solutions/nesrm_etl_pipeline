create or replace function public.sync_profile_organizer_defaults()
returns trigger
language plpgsql
as $$
declare
  resolved text;
begin
  resolved := nullif(trim(coalesce(new.organizer_code, '')), '');
  if resolved is null then
    resolved := nullif(trim(coalesce(new.organizer_tag, '')), '');
  end if;

  if coalesce(new.organizer_code, '') = coalesce(resolved, '')
    and coalesce(new.organizer_tag, '') = coalesce(resolved, '') then
    return new;
  end if;

  new.organizer_code := resolved;
  new.organizer_tag := resolved;
  return new;
end;
$$;

drop trigger if exists sync_profile_organizer_defaults on public.profiles;

create trigger sync_profile_organizer_defaults
before insert or update of organizer_tag, organizer_code
on public.profiles
for each row
execute function public.sync_profile_organizer_defaults();
