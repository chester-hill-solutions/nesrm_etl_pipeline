create or replace function public.sync_contact_organizer_fields()
returns trigger
language plpgsql
as $$
declare
  csv_tokens text[] := regexp_split_to_array(
    coalesce(new.organizer, ''),
    '[[:space:]]*,[[:space:]]*'
  );
  array_tokens text[] := coalesce(new.organizer_codes, '{}'::text[]);
  unioned text[] := '{}'::text[];
  seen text[] := '{}'::text[];
  token text;
  normalized text;
  organizer_out text;
begin
  if coalesce(array_length(csv_tokens, 1), 0) > 0 then
    foreach token in array csv_tokens loop
      token := trim(token);
      if token <> '' then
        normalized := lower(token);
        if not (normalized = any(seen)) then
          unioned := array_append(unioned, token);
          seen := array_append(seen, normalized);
        end if;
      end if;
    end loop;
  end if;

  if coalesce(array_length(array_tokens, 1), 0) > 0 then
    foreach token in array array_tokens loop
      token := trim(token);
      if token <> '' then
        normalized := lower(token);
        if not (normalized = any(seen)) then
          unioned := array_append(unioned, token);
          seen := array_append(seen, normalized);
        end if;
      end if;
    end loop;
  end if;

  organizer_out := case
    when array_length(unioned, 1) is null then null
    else array_to_string(unioned, ',')
  end;

  if coalesce(new.organizer_codes, '{}'::text[]) = unioned
    and coalesce(new.organizer, '') = coalesce(organizer_out, '') then
    return new;
  end if;

  new.organizer_codes := unioned;
  new.organizer := organizer_out;
  return new;
end;
$$;

drop trigger if exists sync_contact_organizer_fields on public.contact;

create trigger sync_contact_organizer_fields
before insert or update of organizer, organizer_codes
on public.contact
for each row
execute function public.sync_contact_organizer_fields();

update public.contact
set organizer = organizer
where organizer is not null
  or organizer_codes is not null;
