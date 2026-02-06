-- Add data_type and options columns to column_visibility table
-- This allows Super Admins to set "soft" enums for select menus and change column types

ALTER TABLE "public"."column_visibility"
  ADD COLUMN IF NOT EXISTS "data_type" "text" DEFAULT 'text'::text,
  ADD COLUMN IF NOT EXISTS "options" "jsonb";

-- Add constraint to ensure data_type is one of the valid values
ALTER TABLE "public"."column_visibility"
  ADD CONSTRAINT "column_visibility_data_type_check" 
  CHECK ("data_type" IN ('text', 'number', 'date', 'boolean', 'select'));

-- Add comment explaining the purpose
COMMENT ON COLUMN "public"."column_visibility"."data_type" IS 'Override data type for display/filtering. When set, this overrides the default inferred type. Allows converting text columns to select dropdowns, etc.';
COMMENT ON COLUMN "public"."column_visibility"."options" IS 'For select type columns, stores an array of allowed option values. Example: ["Option 1", "Option 2", "Option 3"]';
