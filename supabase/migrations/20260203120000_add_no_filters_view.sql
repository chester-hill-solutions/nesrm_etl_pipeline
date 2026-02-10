-- Add a shared "No filters" view for contacts dashboard
-- This provides an explicit view with no filter_config applied.

INSERT INTO "public"."views" (
  "name",
  "description",
  "filter_config",
  "is_default",
  "is_shared",
  "created_by",
  "sort_rules"
)
SELECT
  'No filters',
  'No filters applied',
  NULL,
  false,
  true,
  NULL,
  NULL
WHERE NOT EXISTS (
  SELECT 1
  FROM "public"."views"
  WHERE "name" = 'No filters'
    AND "is_shared" = true
);
