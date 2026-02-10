-- Add show_condition column to page_questions table for conditional visibility
-- This allows questions to be shown/hidden based on answers to other questions
ALTER TABLE "public"."page_questions" 
ADD COLUMN IF NOT EXISTS "show_condition" jsonb NULL;

COMMENT ON COLUMN "public"."page_questions"."show_condition" IS 'JSONB object defining when this question should be shown. Format: { "conditions": [{"questionId": number, "operator": string, "value": any}], "conditionLogic": "AND" | "OR" }. If null, question is always shown.';

-- Also add show_condition to survey_questions for survey-level conditional visibility
-- This allows questions to be conditionally shown when directly assigned to surveys
ALTER TABLE "public"."survey_questions" 
ADD COLUMN IF NOT EXISTS "show_condition" jsonb NULL;

COMMENT ON COLUMN "public"."survey_questions"."show_condition" IS 'JSONB object defining when this question should be shown. Format: { "conditions": [{"questionId": number, "operator": string, "value": any}], "conditionLogic": "AND" | "OR" }. If null, question is always shown.';
