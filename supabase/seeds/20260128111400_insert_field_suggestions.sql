-- ============================================================================
-- INSERT NEW FEATURES
-- ============================================================================

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  ('make_suggestion', 'Make Suggestions', 'Allows users to suggest field changes instead of directly editing', 'contacts'),
  ('accept_suggestion', 'Accept Suggestions', 'Allows users to review, approve, and reject field suggestions', 'contacts')
ON CONFLICT ("id") DO NOTHING;

-- ============================================================================
-- INSERT DEFAULT PERMISSIONS
-- ============================================================================

-- make_suggestion: Available to members (non-admin users can suggest changes)
-- Super Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
WHERE "id" = 'make_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
WHERE "id" = 'make_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: Allowed (non-admin users can suggest changes)
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', true
FROM "public"."features"
WHERE "id" = 'make_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
WHERE "id" = 'make_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
WHERE "id" = 'make_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- accept_suggestion: Admin-only (only admins can review and approve suggestions)
-- Super Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
WHERE "id" = 'accept_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
WHERE "id" = 'accept_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: Denied (only admins can review suggestions)
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', false
FROM "public"."features"
WHERE "id" = 'accept_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
WHERE "id" = 'accept_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
WHERE "id" = 'accept_suggestion'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;
