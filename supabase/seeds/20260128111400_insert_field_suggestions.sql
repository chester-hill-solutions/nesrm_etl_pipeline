
-- Comments for documentation
COMMENT ON TABLE field_suggestions IS 'Stores field change suggestions from non-admin users. Admins can review and approve/reject suggestions.';
COMMENT ON COLUMN field_suggestions.entity_type IS 'Type of entity (e.g., "contact", "profile"). Allows extensibility to other entities.';
COMMENT ON COLUMN field_suggestions.entity_id IS 'ID of the entity being suggested for. Polymorphic - no FK constraint.';
COMMENT ON COLUMN field_suggestions.field_name IS 'Display key of the field (e.g., "firstname", "phone"). Used for UI display.';
COMMENT ON COLUMN field_suggestions.db_column_name IS 'Database column name (for standard fields). Nullable for custom fields. Used for validation.';
COMMENT ON COLUMN field_suggestions.current_value IS 'Current value of the field at the time the suggestion was created (JSONB).';
COMMENT ON COLUMN field_suggestions.suggested_value IS 'Suggested new value for the field (JSONB).';
COMMENT ON COLUMN field_suggestions.status IS 'Status of the suggestion: pending, approved, or rejected.';
COMMENT ON COLUMN field_suggestions.suggested_by IS 'Profile ID of the user who created the suggestion.';
COMMENT ON COLUMN field_suggestions.reviewed_by IS 'Profile ID of the admin who reviewed the suggestion (null if pending).';
COMMENT ON COLUMN field_suggestions.reviewed_at IS 'Timestamp when the suggestion was reviewed (approved or rejected).';
COMMENT ON COLUMN field_suggestions.rejection_reason IS 'Optional reason for rejection (e.g., "Column deleted", "Contact deleted").';

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
