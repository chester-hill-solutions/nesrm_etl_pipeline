-- Migration: Add explicit per-profile segment grants
-- Allows granting a segment to specific profiles regardless of role-based visibility rules.

create table if not exists public.segment_profile_grants (
    segment_id uuid not null references public.segments(id) on delete cascade,
    profile_id uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now(),
    created_by uuid references public.profiles(id),
    primary key (segment_id, profile_id)
);

comment on table public.segment_profile_grants is
    'Explicit per-profile segment grants. These are additive overrides to role-based segment visibility.';

create index if not exists segment_profile_grants_profile_id_idx
    on public.segment_profile_grants (profile_id);

alter table public.segment_profile_grants enable row level security;

-- Service role can manage everything
drop policy if exists "Allow service manage segment_profile_grants" on public.segment_profile_grants;
create policy "Allow service manage segment_profile_grants" on public.segment_profile_grants
    to service_role using (true) with check (true);

grant all on public.segment_profile_grants to service_role;
grant all on public.segment_profile_grants to anon, authenticated;

