-- RBAC Feature Permissions Manager with Role Management
-- This migration creates the tables and functions needed for role-based access control
-- of feature permissions, supporting both system roles and custom roles.

-- ============================================================================
-- ROLES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."roles" (
  "id" text PRIMARY KEY,
  "name" text NOT NULL UNIQUE,
  "description" text,
  "is_system" boolean NOT NULL DEFAULT false,
  "display_order" integer NOT NULL DEFAULT 0,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT "roles_system_role_id_check" CHECK (
    ("is_system" = false) OR ("id" = "name")
  )
);

COMMENT ON TABLE "public"."roles" IS 'Stores both system roles (super_admin, admin, member, locked, developer) and custom roles';

-- ============================================================================
-- FEATURES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."features" (
  "id" text PRIMARY KEY,
  "name" text NOT NULL,
  "description" text,
  "category" text,
  "enabled" boolean NOT NULL DEFAULT true,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now()
);

-- ============================================================================
-- FEATURE PERMISSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."feature_permissions" (
  "id" serial PRIMARY KEY,
  "feature_id" text NOT NULL REFERENCES "public"."features"("id") ON DELETE CASCADE,
  "role_id" text NOT NULL REFERENCES "public"."roles"("id") ON DELETE CASCADE,
  "allowed" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  UNIQUE("feature_id", "role_id")
);

COMMENT ON TABLE "public"."feature_permissions" IS 'Links features to roles with permission flags. role_id references roles table for both system and custom roles.';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS "feature_permissions_role_idx" ON "public"."feature_permissions"("role_id");
CREATE INDEX IF NOT EXISTS "feature_permissions_feature_idx" ON "public"."feature_permissions"("feature_id");

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

-- ============================================================================
-- RPC FUNCTION FOR PERMISSION CHECKING
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."check_feature_permission"(
  "p_role_id" text,
  "p_feature_id" text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  "v_enabled" boolean;
  "v_allowed" boolean;
  "v_role_exists" boolean;
BEGIN
  -- Check if role exists
  SELECT EXISTS(SELECT 1 FROM "public"."roles" WHERE "id" = "p_role_id") INTO "v_role_exists";
  
  IF NOT "v_role_exists" THEN
    RETURN false;
  END IF;
  
  -- Check if feature exists and is enabled
  SELECT "enabled" INTO "v_enabled"
  FROM "public"."features"
  WHERE "id" = "p_feature_id";
  
  -- If feature doesn't exist or is disabled, return false
  IF NOT FOUND OR NOT "v_enabled" THEN
    RETURN false;
  END IF;
  
  -- Check if role has permission
  SELECT "allowed" INTO "v_allowed"
  FROM "public"."feature_permissions"
  WHERE "feature_id" = "p_feature_id"
    AND "role_id" = "p_role_id";
  
  -- If no permission record exists, default to false (deny by default)
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  RETURN "v_allowed";
END;
$$;

COMMENT ON FUNCTION "public"."check_feature_permission" IS 'Checks if a role (system or custom) has permission to access a feature. Returns false if feature is disabled, permission not granted, or feature/permission does not exist.';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION "public"."check_feature_permission"(text, text) TO authenticated, service_role;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."features" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."feature_permissions" ENABLE ROW LEVEL SECURITY;

-- Roles: service_role can manage, authenticated users can read
CREATE POLICY "roles_service_role_all" ON "public"."roles"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "roles_authenticated_read" ON "public"."roles"
  FOR SELECT
  TO authenticated
  USING (true);

COMMENT ON POLICY "roles_authenticated_read" ON "public"."roles" IS 'System roles cannot be deleted (enforced by application logic)';

-- Features: service_role can manage, authenticated users can read
CREATE POLICY "features_service_role_all" ON "public"."features"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "features_authenticated_read" ON "public"."features"
  FOR SELECT
  TO authenticated
  USING (true);

-- Feature Permissions: service_role can manage, authenticated users can read
CREATE POLICY "feature_permissions_service_role_all" ON "public"."feature_permissions"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "feature_permissions_authenticated_read" ON "public"."feature_permissions"
  FOR SELECT
  TO authenticated
  USING (true);
