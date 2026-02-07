-- Remove direct profile_id from organizer_code and create join table organizer_code_profiles

-- Drop existing foreign key and index, then remove the column
alter table public.organizer_code
  drop constraint if exists organizer_code_profile_id_fkey;

drop index if exists organizer_code_profile_id_idx;

alter table public.organizer_code
  drop column if exists profile_id;

-- Create join table to associate organizer codes with profiles
create table if not exists public.organizer_code_profiles (
  code text not null references public.organizer_code(code) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (code, profile_id)
);

create index if not exists organizer_code_profiles_profile_id_idx
  on public.organizer_code_profiles(profile_id);
