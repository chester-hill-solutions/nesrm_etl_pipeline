-- Create organizer_code table for organizer invite codes and labels
create table if not exists public.organizer_code (
  code text primary key,

  profile_id uuid not null
    references public.profiles(id)
    on delete cascade,

  -- store CSS hex: #RRGGBB
  color_hex text not null,

  label text,
  description text,
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint organizer_code_color_hex_chk
    check (color_hex ~ '^#[0-9A-Fa-f]{6}$')
);

create index if not exists organizer_code_profile_id_idx
  on public.organizer_code(profile_id);

-- Default color helper and updated_at maintenance
create or replace function public.organizer_code_default_color()
returns trigger
language plpgsql
as $$
begin
  -- if caller didn't specify a color, generate one
  if new.color_hex is null or new.color_hex = '' then
    new.color_hex := '#' || substr(md5(new.code), 1, 6);
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger organizer_code_set_default_color
before insert or update on public.organizer_code
for each row
execute function public.organizer_code_default_color();
