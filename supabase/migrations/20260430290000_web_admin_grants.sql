-- Allowlist for Team Nate public-site /admin access without elevating profiles.role (CRM).

create table if not exists public.web_admin_grants (
    profile_id uuid not null references public.profiles (id) on delete cascade,
    created_at timestamptz not null default now(),
    created_by uuid references public.profiles (id),
    primary key (profile_id)
);

comment on table public.web_admin_grants is
    'Profiles allowed to use the public-site /admin area when role is not admin/super_admin.';

create index if not exists web_admin_grants_created_at_idx
    on public.web_admin_grants (created_at desc);

alter table public.web_admin_grants enable row level security;

drop policy if exists "Service role manages web_admin_grants" on public.web_admin_grants;
create policy "Service role manages web_admin_grants" on public.web_admin_grants
    to service_role using (true) with check (true);

revoke all on table public.web_admin_grants from public;
grant all on table public.web_admin_grants to service_role;
