-- Performance indexes for segment survey-rule expansion paths.
-- These support the query patterns in crm/app/lib/segments/segment-access.server.ts:
-- - survey_responses filtered by contact_id + status and ordered/paged by id
-- - survey_response_answers filtered by response_id + question_id and ordered/paged by id

CREATE INDEX IF NOT EXISTS idx_survey_responses_contact_status_id
  ON public.survey_responses (contact_id, status, id);

CREATE INDEX IF NOT EXISTS idx_survey_response_answers_response_question_id
  ON public.survey_response_answers (response_id, question_id, id);

-- Dashboard survey sort/open paths:
-- - latest response lookup by (contact_id, survey_id, status) ordered by created_at/id desc
-- - unanswered map lookup by (survey_id, contact_id) ordered by created_at/id desc
CREATE INDEX IF NOT EXISTS idx_survey_responses_contact_survey_status_created_desc
  ON public.survey_responses (contact_id, survey_id, status, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS idx_survey_responses_survey_contact_latest_completed
  ON public.survey_responses (survey_id, contact_id, created_at DESC, id DESC)
  WHERE status IN ('in_progress', 'completed');
