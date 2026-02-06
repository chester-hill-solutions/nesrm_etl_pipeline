-- Add column_label to view_column_visibility table
-- This allows per-view label overrides for columns
-- If null, the global label from column_visibility.column_label or custom_columns.label is used

ALTER TABLE "public"."view_column_visibility"
ADD COLUMN IF NOT EXISTS "column_label" text;

COMMENT ON COLUMN "public"."view_column_visibility"."column_label" IS 'Per-view label override for the column. If null, uses the global label from column_visibility.column_label (for default columns) or custom_columns.label (for custom columns).';
