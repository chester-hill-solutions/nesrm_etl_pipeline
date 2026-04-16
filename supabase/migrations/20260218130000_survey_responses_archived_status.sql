-- Allow 'archived' status on survey_responses for soft delete.
-- Enables archiveSurveyResponse and delete-partial (archive) to work.

alter table public.survey_responses
  drop constraint if exists survey_responses_status_check;

alter table public.survey_responses
  add constraint survey_responses_status_check
  check (status = any (array['in_progress', 'completed', 'archived']::text[]));
