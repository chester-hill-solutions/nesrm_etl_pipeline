-- Add survey_mark_complete feature (super_admin only).
-- Allows quick "Mark complete" for partially-complete surveys from the contact table.

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  (
    'survey_mark_complete',
    'Survey Mark Complete',
    'Ability to mark in-progress surveys as complete without filling remaining questions (super_admin only)',
    'contacts'
  )
ON CONFLICT ("id") DO NOTHING;

-- Grant only to super_admin
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
VALUES ('survey_mark_complete', 'super_admin', true)
ON CONFLICT ("feature_id", "role_id") DO UPDATE SET "allowed" = true, "updated_at" = NOW();

-- Explicitly deny for admin, member, locked, developer
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
VALUES
  ('survey_mark_complete', 'admin', false),
  ('survey_mark_complete', 'member', false),
  ('survey_mark_complete', 'locked', false),
  ('survey_mark_complete', 'developer', false)
ON CONFLICT ("feature_id", "role_id") DO UPDATE SET "allowed" = false, "updated_at" = NOW();
