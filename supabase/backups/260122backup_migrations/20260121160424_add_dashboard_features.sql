-- Add dashboard feature permissions
-- These features control access to dashboard routes

-- ============================================================================
-- INSERT NEW FEATURES
-- ============================================================================

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  ('gotv_dashboard', 'GOTV Dashboard', 'Access to GOTV (Get Out The Vote) dashboard', 'dashboards'),
  ('ride_requests_dashboard', 'Ride Requests Dashboard', 'Access to ride requests management dashboard', 'dashboards'),
  ('all_contacts', 'All Contacts', 'Access to view and manage all contacts across all ridings', 'dashboards'),
  ('form_submissions', 'Form Submissions', 'Access to view and manage form submissions', 'dashboards')
ON CONFLICT ("id") DO NOTHING;

-- ============================================================================
-- INSERT DEFAULT PERMISSIONS
-- ============================================================================

-- Super Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'super_admin', true
FROM "public"."features"
WHERE "id" IN ('gotv_dashboard', 'ride_requests_dashboard', 'all_contacts', 'form_submissions')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
WHERE "id" IN ('gotv_dashboard', 'ride_requests_dashboard', 'all_contacts', 'form_submissions')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: All features denied (admin-level features)
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', false
FROM "public"."features"
WHERE "id" IN ('gotv_dashboard', 'ride_requests_dashboard', 'all_contacts', 'form_submissions')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Locked: All features denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'locked', false
FROM "public"."features"
WHERE "id" IN ('gotv_dashboard', 'ride_requests_dashboard', 'all_contacts', 'form_submissions')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
WHERE "id" IN ('gotv_dashboard', 'ride_requests_dashboard', 'all_contacts', 'form_submissions')
ON CONFLICT ("feature_id", "role_id") DO NOTHING;
