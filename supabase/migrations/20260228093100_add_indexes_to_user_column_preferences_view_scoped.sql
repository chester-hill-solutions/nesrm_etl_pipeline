-- Add indexes/constraints for view-scoped user column preferences.
-- We use partial unique indexes to avoid NULL uniqueness pitfalls.

-- Fast lookup by scope + order (used by prefs loaders and contact tables).
CREATE INDEX IF NOT EXISTS "user_column_preferences_scope_order_idx"
  ON "public"."user_column_preferences" ("user_id", "route", "view_id", "display_order");

-- Ensure one preference row per default column in a given (user, route, view_id) scope.
CREATE UNIQUE INDEX IF NOT EXISTS "user_column_preferences_unique_default_col_idx"
  ON "public"."user_column_preferences" ("user_id", "route", "view_id", "column_name")
  WHERE "custom_column_id" IS NULL AND "column_name" IS NOT NULL;

-- Ensure one preference row per custom column in a given (user, route, view_id) scope.
CREATE UNIQUE INDEX IF NOT EXISTS "user_column_preferences_unique_custom_col_idx"
  ON "public"."user_column_preferences" ("user_id", "route", "view_id", "custom_column_id")
  WHERE "column_name" IS NULL AND "custom_column_id" IS NOT NULL;

