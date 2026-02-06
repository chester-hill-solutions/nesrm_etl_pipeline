-- Add allow_other column to column_visibility table
-- This allows Super Admins to enable "Allow Other" option for select type columns,
-- similar to survey questions, allowing users to add custom values

ALTER TABLE "public"."column_visibility"
  ADD COLUMN IF NOT EXISTS "allow_other" boolean DEFAULT false NOT NULL;

-- Add comment explaining the purpose
COMMENT ON COLUMN "public"."column_visibility"."allow_other" IS 'For select type columns, when true, allows users to add custom values in addition to predefined options. Similar to survey question "Allow Other" functionality.';
