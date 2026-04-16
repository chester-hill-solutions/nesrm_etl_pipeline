-- Migration: Materialize contact segment membership

begin;

-- ============================================================================
-- SEGMENT MEMBERSHIP VERSIONING
-- ============================================================================

alter table public.segments
  add column if not exists membership_version bigint not null default 0,
  add column if not exists membership_updated_at timestamptz;

comment on column public.segments.membership_version is
  'Monotonic version bumped when segment definition changes; used to invalidate membership materialization.';

comment on column public.segments.membership_updated_at is
  'Timestamp of last successful membership refresh for this segment.';

-- ============================================================================
-- CONTACT SEGMENT MEMBERSHIP TABLE
-- ============================================================================

create table if not exists public.contact_segment_membership (
  segment_id uuid not null references public.segments(id) on delete cascade,
  contact_id bigint not null references public.contact(id) on delete cascade,
  segment_version bigint not null default 0,
  computed_at timestamptz not null default now(),
  primary key (segment_id, contact_id)
);

comment on table public.contact_segment_membership is
  'Materialized segment membership for contacts.';

comment on column public.contact_segment_membership.segment_version is
  'Segment membership_version at time of compute.';

comment on column public.contact_segment_membership.computed_at is
  'Timestamp of when this membership row was computed.';

create index if not exists contact_segment_membership_contact_idx
  on public.contact_segment_membership (contact_id);

create index if not exists contact_segment_membership_segment_version_idx
  on public.contact_segment_membership (segment_id, segment_version);

alter table public.contact_segment_membership enable row level security;

drop policy if exists "Allow service manage contact_segment_membership"
  on public.contact_segment_membership;

create policy "Allow service manage contact_segment_membership"
  on public.contact_segment_membership
  to service_role
  using (true)
  with check (true);

grant all on public.contact_segment_membership to service_role;
grant all on public.contact_segment_membership to anon, authenticated;

-- ============================================================================
-- PGMQ HELPERS FOR SEGMENT MEMBERSHIP QUEUE
-- ============================================================================

create or replace function public.pgmq_send_segment_membership_job(
  queue_name text,
  message jsonb
) returns table(msg_id bigint)
language plpgsql
as $$
declare
  result_msg_id bigint;
begin
  select msg_id into result_msg_id
  from pgmq.send(queue_name, message);

  return query select result_msg_id;
exception
  when others then
    raise exception 'Failed to send job to queue %: %', queue_name, sqlerrm;
end;
$$;

create or replace function public.pgmq_read_segment_membership_jobs(
  queue_name text,
  vt integer default 300,
  qty integer default 10
) returns table(msg_id bigint, message jsonb)
language plpgsql
as $$
begin
  return query
  select
    m.msg_id,
    m.message
  from pgmq.read(queue_name, vt, qty) m;
exception
  when others then
    raise exception 'Failed to read jobs from queue %: %', queue_name, sqlerrm;
end;
$$;

create or replace function public.pgmq_archive_segment_membership_job(
  queue_name text,
  msg_id_param bigint
) returns boolean
language plpgsql
as $$
begin
  perform pgmq.archive(queue_name, msg_id_param);
  return true;
exception
  when others then
    return false;
end;
$$;

create or replace function public.pgmq_delete_segment_membership_job(
  queue_name text,
  msg_id_param bigint
) returns boolean
language plpgsql
as $$
begin
  perform pgmq.delete(queue_name, msg_id_param);
  return true;
exception
  when others then
    return false;
end;
$$;

grant all on function public.pgmq_send_segment_membership_job(text, jsonb)
  to anon, authenticated, service_role;

grant all on function public.pgmq_read_segment_membership_jobs(text, integer, integer)
  to anon, authenticated, service_role;

grant all on function public.pgmq_archive_segment_membership_job(text, bigint)
  to anon, authenticated, service_role;

grant all on function public.pgmq_delete_segment_membership_job(text, bigint)
  to anon, authenticated, service_role;

commit;
