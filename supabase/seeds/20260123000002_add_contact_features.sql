-- Add contact_notes and contact_attachments feature permissions
-- These features control access to contact notes and attachments functionality

-- ============================================================================
-- INSERT NEW FEATURES
-- ============================================================================

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  ('contact_notes', 'Contact Notes', 'Access to create, view, and manage contact notes', 'contacts'),
  ('contact_attachments', 'Contact Attachments', 'Access to upload, view, and manage contact attachments', 'contacts')
ON CONFLICT ("id") DO NOTHING;

-- ============================================================================
-- INSERT DEFAULT PERMISSIONS
-- ============================================================================

-- Super Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
WHERE "id" IN ('contact_notes', 'contact_attachments')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
WHERE "id" IN ('contact_notes', 'contact_attachments')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: All features allowed (default for contacts category)
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', true
FROM "public"."features"
WHERE "id" IN ('contact_notes', 'contact_attachments')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: All features denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
WHERE "id" IN ('contact_notes', 'contact_attachments')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
WHERE "id" IN ('contact_notes', 'contact_attachments')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;
