-- Add contact_archiving feature permission
-- Enables archiving contacts from the contact card (super admin only by default).

-- ============================================================================
-- INSERT NEW FEATURE
-- ============================================================================

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  (
    'contact_archiving',
    'Contact Archiving',
    'Archive contacts from the contact card and hide them from contact tables',
    'contacts'
  )
ON CONFLICT ("id") DO NOTHING;

-- ============================================================================
-- INSERT DEFAULT PERMISSIONS
-- ============================================================================

-- Super Admin: Allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
WHERE "id" = 'contact_archiving'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', false
FROM "public"."features"
WHERE "id" = 'contact_archiving'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', false
FROM "public"."features"
WHERE "id" = 'contact_archiving'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
WHERE "id" = 'contact_archiving'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: Denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', false
FROM "public"."features"
WHERE "id" = 'contact_archiving'
ON CONFLICT ("feature_id", "role_id") DO NOTHING;
