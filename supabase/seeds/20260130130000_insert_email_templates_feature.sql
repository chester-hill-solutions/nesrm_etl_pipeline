-- Add email_templates feature for permission-gated access to admin email templates (respondent templates).
-- All features must be gated via the feature permissions system; see CODE_STANDARDS.md.

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  ('email_templates', 'Email Templates', 'Access to manage respondent email templates (post-survey / volunteer onboarding)', 'admin')
ON CONFLICT ("id") DO NOTHING;

-- Super Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
WHERE "id" = 'email_templates'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
WHERE "id" = 'email_templates'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', false
FROM "public"."features"
WHERE "id" = 'email_templates'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
WHERE "id" = 'email_templates'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
WHERE "id" = 'email_templates'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;
