-- Migration: Create data entry workflows + notes
-- Data Entry configuration should not be stored in segment settings.
-- This migration introduces first-class workflow configuration, segment assignment,
-- and an admin-reviewable notes queue.

begin;

-- ============================================================================
-- DATA ENTRY WORKFLOWS
-- ============================================================================

create table if not exists public.data_entry_workflows (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  enabled boolean not null default true,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id)
);

comment on table public.data_entry_workflows is
  'Configurable Data Entry workflows (rules/actions) not tied to segment settings JSON.';

comment on column public.data_entry_workflows.config is
  'Workflow configuration JSON (validated server-side).';

create index if not exists data_entry_workflows_enabled_idx
  on public.data_entry_workflows (enabled);

-- ============================================================================
-- WORKFLOW ↔ SEGMENT ASSIGNMENTS
-- ============================================================================

create table if not exists public.data_entry_workflow_segments (
  workflow_id uuid not null references public.data_entry_workflows(id) on delete cascade,
  segment_id uuid not null references public.segments(id) on delete cascade,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  primary key (workflow_id, segment_id)
);

comment on table public.data_entry_workflow_segments is
  'Assign a single Data Entry workflow to one or more segments.';

-- One workflow per segment (simplifies runtime resolution)
create unique index if not exists data_entry_workflow_segments_segment_id_uniq
  on public.data_entry_workflow_segments (segment_id);

create index if not exists data_entry_workflow_segments_workflow_id_idx
  on public.data_entry_workflow_segments (workflow_id);

-- ============================================================================
-- DATA ENTRY NOTES (ADMIN REVIEW QUEUE)
-- ============================================================================

create table if not exists public.data_entry_notes (
  id bigserial primary key,
  workflow_id uuid not null references public.data_entry_workflows(id) on delete cascade,
  segment_id uuid not null references public.segments(id) on delete cascade,
  contact_id bigint not null references public.contact(id) on delete cascade,
  trigger_key text not null,
  note text not null,
  status text not null default 'open' check (status in ('open', 'reviewed', 'dismissed')),
  metadata jsonb,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz
);

comment on table public.data_entry_notes is
  'Admin-reviewable notes created during Data Entry action execution.';

create index if not exists data_entry_notes_status_created_at_idx
  on public.data_entry_notes (status, created_at desc);

create index if not exists data_entry_notes_segment_id_idx
  on public.data_entry_notes (segment_id);

create index if not exists data_entry_notes_contact_id_idx
  on public.data_entry_notes (contact_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

alter table public.data_entry_workflows enable row level security;
alter table public.data_entry_workflow_segments enable row level security;
alter table public.data_entry_notes enable row level security;

-- Service role can manage everything
drop policy if exists "Allow service manage data_entry_workflows" on public.data_entry_workflows;
create policy "Allow service manage data_entry_workflows" on public.data_entry_workflows
  to service_role using (true) with check (true);

drop policy if exists "Allow service manage data_entry_workflow_segments" on public.data_entry_workflow_segments;
create policy "Allow service manage data_entry_workflow_segments" on public.data_entry_workflow_segments
  to service_role using (true) with check (true);

drop policy if exists "Allow service manage data_entry_notes" on public.data_entry_notes;
create policy "Allow service manage data_entry_notes" on public.data_entry_notes
  to service_role using (true) with check (true);

grant all on public.data_entry_workflows to service_role;
grant all on public.data_entry_workflow_segments to service_role;
grant all on public.data_entry_notes to service_role;

grant all on public.data_entry_workflows to anon, authenticated;
grant all on public.data_entry_workflow_segments to anon, authenticated;
grant all on public.data_entry_notes to anon, authenticated;

commit;

