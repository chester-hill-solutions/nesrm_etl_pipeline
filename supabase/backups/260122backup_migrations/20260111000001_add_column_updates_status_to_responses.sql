-- Add simple status field to track if column updates have been applied
-- Much simpler than a separate approval table - just calculate changes on-demand
ALTER TABLE "public"."survey_responses" 
ADD COLUMN IF NOT EXISTS "column_updates_status" text DEFAULT 'pending' CHECK ("column_updates_status" IN ('pending', 'applied', 'rejected'));

ALTER TABLE "public"."survey_responses" 
ADD COLUMN IF NOT EXISTS "column_updates_reviewed_by" uuid REFERENCES "public"."profiles"("id") ON DELETE SET NULL;

ALTER TABLE "public"."survey_responses" 
ADD COLUMN IF NOT EXISTS "column_updates_reviewed_at" timestamp with time zone;

ALTER TABLE "public"."survey_responses" 
ADD COLUMN IF NOT EXISTS "column_updates_reviewer_notes" text;

-- Index for finding pending responses
CREATE INDEX IF NOT EXISTS "survey_responses_column_updates_status_idx" 
ON "public"."survey_responses"("column_updates_status", "completed_at") 
WHERE "status" = 'completed' AND "column_updates_status" = 'pending';

COMMENT ON COLUMN "public"."survey_responses"."column_updates_status" IS 'Status of column updates from this survey response: pending (needs review), applied (approved and applied), rejected (not applied)';
