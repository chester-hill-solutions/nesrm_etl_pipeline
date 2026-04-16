begin;

alter table public.segments
  add column if not exists settings jsonb;

comment on column public.segments.settings is
  'Extensible JSON settings for segment behavior (e.g. include/exclude segmentRules).';

commit;
