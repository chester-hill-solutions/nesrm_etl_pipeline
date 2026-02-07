-- ============================================================================
-- INSERT SYSTEM ROLES
-- ============================================================================

INSERT INTO "public"."roles" ("id", "name", "description", "is_system", "display_order")
VALUES
  ('super_admin', 'super_admin', 'Full system access with all permissions', true, 1),
  ('admin', 'admin', 'Administrative access with most permissions', true, 2),
  ('member', 'member', 'Standard member access', true, 3),
  ('locked', 'locked', 'Locked account with minimal access', true, 4),
  ('developer', 'developer', 'Developer access with technical permissions', true, 5)
ON CONFLICT ("id") DO NOTHING;

-- ============================================================================
-- INSERT INITIAL FEATURES
-- ============================================================================

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  ('survey_button', 'Survey Button', 'Access to survey button in contacts table', 'contacts'),
  ('survey_mark_complete', 'Survey Mark Complete', 'Ability to mark in-progress surveys complete without filling remaining questions (super_admin only)', 'contacts'),
  ('ai_research', 'AI Research', 'Access to AI-powered contact research/lookup', 'contacts'),
  ('filter_sharing', 'Filter Sharing', 'Ability to share filters with team', 'filters'),
  ('contact_editing', 'Contact Editing', 'Ability to edit contact fields inline', 'contacts'),
  ('view_management', 'View Management', 'Access to create/edit shared views', 'admin'),
  ('api_tokens', 'API Tokens', 'Access to API token management (super_admin only by default)', 'api'),
  ('admin_dashboard', 'Admin Dashboard', 'Access to admin dashboard routes', 'admin')
ON CONFLICT ("id") DO NOTHING;

-- ============================================================================
-- INSERT DEFAULT PERMISSIONS
-- ============================================================================

-- Super Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: All features denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', false
FROM "public"."features"
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: All features denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

