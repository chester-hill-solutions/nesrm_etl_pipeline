-- Add unique constraint to ensure one response per survey instance
-- This prevents duplicate responses from being created in the future

ALTER TABLE "public"."survey_responses"
ADD CONSTRAINT "survey_responses_survey_instance_id_unique" 
UNIQUE ("survey_instance_id");

COMMENT ON CONSTRAINT "survey_responses_survey_instance_id_unique" ON "public"."survey_responses" IS 
'Ensures that each survey instance can only have one response. A contact can take the same survey multiple times (multiple instances), but each instance (session) should only have one response.';
