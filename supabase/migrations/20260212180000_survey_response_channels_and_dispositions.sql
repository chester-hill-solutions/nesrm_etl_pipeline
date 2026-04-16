-- Expand survey response channels and add disposition fields.
--
-- Channels are stored as text with a CHECK constraint (not a Postgres enum).
-- This migration expands allowed values and adds two response-level fields:
-- - disposition: high-level outcome for phone/canvass workflows
-- - channel_other_details: freeform detail when channel = 'other'

begin;

-- 1) Expand allowed channel values
alter table public.survey_responses
  drop constraint if exists survey_responses_channel_check;

alter table public.survey_responses
  add constraint survey_responses_channel_check
  check (
    channel = any (
      array[
        'email',
        'phone',
        'canvass',
        'event',
        'social_media',
        'other'
      ]::text[]
    )
  );

-- 2) Add response-level fields
alter table public.survey_responses
  add column if not exists disposition text null;

alter table public.survey_responses
  add column if not exists channel_other_details text null;

commit;

