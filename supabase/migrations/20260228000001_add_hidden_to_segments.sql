-- Migration: Add hidden flag to segments
-- Hidden segments are intended for use in filters (segment membership), not as selectable dashboards.

begin;

alter table public.segments
  add column if not exists hidden boolean not null default false;

comment on column public.segments.hidden is
  'If true, this segment is hidden from segment dashboard selection (filter-only building block).';

commit;

