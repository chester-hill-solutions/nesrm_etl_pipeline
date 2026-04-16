create or replace function public.sync_profile_organizer_defaults()
returns trigger
language plpgsql
as $$
declare
  new_code text := nullif(trim(coalesce(new.organizer_code, '')), '');
  new_tag text := nullif(trim(coalesce(new.organizer_tag, '')), '');
  old_code text := nullif(trim(coalesce(old.organizer_code, '')), '');
  old_tag text := nullif(trim(coalesce(old.organizer_tag, '')), '');
  resolved text;
begin
  if tg_op = 'INSERT' then
    resolved := coalesce(new_code, new_tag);
  else
    if new_code is distinct from old_code and new_code is not null then
      resolved := new_code;
    elsif new_tag is distinct from old_tag and new_tag is not null then
      resolved := new_tag;
    else
      resolved := coalesce(new_code, new_tag);
    end if;
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
