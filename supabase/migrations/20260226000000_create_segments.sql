-- Migration: Create segments tables for Issue #941
-- Segments provide role-based access control to contact subsets via saved filters

begin;

-- ============================================================================
-- CREATE SEGMENTS TABLE
-- ============================================================================

create table if not exists public.segments (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    visibility text not null default 'private' check (visibility in ('private', 'team')),
    visible_to_roles text[] default '{}',
    default_for_roles text[] default '{}',
    priority int not null default 100,
    created_at timestamptz not null default now(),
    updated_at timestamptz
);

comment on table public.segments is 
    'Access control segments that define which contacts users can see based on saved filters';

comment on column public.segments.visibility is 
    'Visibility level: private (explicit assignment) or team (auto-grant to team members)';

comment on column public.segments.visible_to_roles is 
    'Array of role IDs that can see this segment. Empty array means visible to all roles.';

comment on column public.segments.default_for_roles is 
    'Array of role IDs for which this segment is the default. Lower priority wins if multiple match.';

comment on column public.segments.priority is 
    'Priority for default segment selection. Lower numbers = higher priority (e.g., 10 beats 100).';

-- ============================================================================
-- CREATE SEGMENT_FILTERS JOIN TABLE
-- ============================================================================

create table if not exists public.segment_filters (
    segment_id uuid not null references public.segments(id) on delete cascade,
    saved_filter_id bigint not null references public.saved_filters(id) on delete cascade,
    primary key (segment_id, saved_filter_id)
);

comment on table public.segment_filters is 
    'Junction table linking segments to saved filters that define contact membership';

-- ============================================================================
-- ADD CURRENT_SEGMENT_ID TO USER_PREFERENCES
-- ============================================================================

alter table public.user_preferences 
    add column if not exists current_segment_id uuid references public.segments(id) on delete set null;

comment on column public.user_preferences.current_segment_id is 
    'User''s currently selected or default segment for the segments dashboard';

-- ============================================================================
-- INDEXES
-- ============================================================================

create index if not exists segments_visible_to_roles_idx 
    on public.segments using gin (visible_to_roles);

create index if not exists segments_default_for_roles_idx 
    on public.segments using gin (default_for_roles);

create index if not exists segments_priority_idx 
    on public.segments (priority);

create index if not exists segment_filters_segment_id_idx 
    on public.segment_filters (segment_id);

create index if not exists segment_filters_saved_filter_id_idx 
    on public.segment_filters (saved_filter_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

alter table public.segments enable row level security;
alter table public.segment_filters enable row level security;

-- Service role can manage everything
drop policy if exists "Allow service manage segments" on public.segments;
create policy "Allow service manage segments" on public.segments
    to service_role using (true) with check (true);

drop policy if exists "Allow service manage segment_filters" on public.segment_filters;
create policy "Allow service manage segment_filters" on public.segment_filters
    to service_role using (true) with check (true);

-- Grant permissions
grant all on public.segments to service_role;
grant all on public.segment_filters to service_role;
grant all on public.segments to anon, authenticated;
grant all on public.segment_filters to anon, authenticated;

commit;
