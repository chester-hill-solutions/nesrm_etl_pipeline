-- Route-level table preferences on user_preferences: one JSONB keyed by normalized route.
-- Value = same shape as user_table_preferences (page_size, sort_by, sort_order, pinned_headers). Used to preserve user preferences.
ALTER TABLE "public"."user_preferences"
    DROP COLUMN IF EXISTS "route_view_ids";

ALTER TABLE "public"."user_preferences"
    ADD COLUMN IF NOT EXISTS "route_preferences" jsonb DEFAULT '{}' NOT NULL;

COMMENT ON COLUMN "public"."user_preferences"."route_preferences" IS 'Route-level table preferences (page_size, sort_by, sort_order, pinned_headers) per route. Key = normalized route. Used to preserve user preferences; do not persist defaults.';
