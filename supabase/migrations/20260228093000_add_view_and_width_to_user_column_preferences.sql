-- Add view-scoped + width preferences to user_column_preferences.
-- Supports hybrid layout scoping (per-view when active, otherwise per-route).

ALTER TABLE "public"."user_column_preferences"
  ADD COLUMN IF NOT EXISTS "view_id" bigint;

ALTER TABLE "public"."user_column_preferences"
  ADD COLUMN IF NOT EXISTS "width_px" integer;

COMMENT ON COLUMN "public"."user_column_preferences"."view_id"
  IS 'Optional view scope for column layout preferences; NULL means route default.';

COMMENT ON COLUMN "public"."user_column_preferences"."width_px"
  IS 'Optional column width in pixels for resizable table layouts.';

