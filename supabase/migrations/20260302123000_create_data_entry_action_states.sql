-- Migration: Create data entry action states
-- Stores per-contact checked state for Data Entry actions (not tied to contact/custom fields).

begin;

create table if not exists public.data_entry_action_states (
  workflow_id uuid not null references public.data_entry_workflows(id) on delete cascade,
  segment_id uuid not null references public.segments(id) on delete cascade,
  contact_id bigint not null references public.contact(id) on delete cascade,
  action_key text not null,
  checked boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  primary key (workflow_id, contact_id, action_key)
);

comment on table public.data_entry_action_states is
  'Per-contact checked state for Data Entry workflow actions.';

create index if not exists data_entry_action_states_segment_contact_idx
  on public.data_entry_action_states (segment_id, contact_id);

create index if not exists data_entry_action_states_segment_action_idx
  on public.data_entry_action_states (segment_id, action_key);

alter table public.data_entry_action_states enable row level security;

-- Service role can manage everything
drop policy if exists "Allow service manage data_entry_action_states" on public.data_entry_action_states;
create policy "Allow service manage data_entry_action_states" on public.data_entry_action_states
  to service_role using (true) with check (true);

grant all on public.data_entry_action_states to service_role;
grant all on public.data_entry_action_states to anon, authenticated;

commit;

