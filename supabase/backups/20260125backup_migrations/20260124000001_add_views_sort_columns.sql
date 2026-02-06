-- Add sort_rules to views for per-view default sort (multiple rules in defined order)
ALTER TABLE "public"."views"
  ADD COLUMN IF NOT EXISTS "sort_rules" jsonb;

COMMENT ON COLUMN "public"."views"."sort_rules" IS 'Default sort rules: [{ "column": string, "order": "asc"|"desc" }]. Array index = priority (0 primary, 1 secondary). Example: [{"column":"survey_status","order":"desc"},{"column":"id","order":"asc"}]. Used when view is selected and URL has no sort params.';
