-- Migration: Track suggestions created by Data Entry actions
-- We reuse the generic field_suggestions system, but need a first-class mapping so the
-- Admin → Data Entry review queue can filter to Data Entry-originated suggestions and show notes.

begin;

create table if not exists public.data_entry_suggestions (
  suggestion_id bigint primary key references public.field_suggestions(id) on delete cascade,
  workflow_id uuid not null references public.data_entry_workflows(id) on delete cascade,
  segment_id uuid not null references public.segments(id) on delete cascade,
  action_key text not null,
  checked boolean not null,
  note_id bigint references public.data_entry_notes(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.data_entry_suggestions is
  'Mapping table linking field_suggestions to the Data Entry workflow/action that created them (and optional note).';

create index if not exists data_entry_suggestions_workflow_id_idx
  on public.data_entry_suggestions (workflow_id);

create index if not exists data_entry_suggestions_segment_id_idx
  on public.data_entry_suggestions (segment_id);

create index if not exists data_entry_suggestions_note_id_idx
  on public.data_entry_suggestions (note_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

alter table public.data_entry_suggestions enable row level security;

drop policy if exists "Allow service manage data_entry_suggestions" on public.data_entry_suggestions;
create policy "Allow service manage data_entry_suggestions" on public.data_entry_suggestions
  to service_role using (true) with check (true);

grant all on public.data_entry_suggestions to service_role;
grant all on public.data_entry_suggestions to anon, authenticated;

commit;

