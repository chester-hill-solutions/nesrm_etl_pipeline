-- Add dashboard feature permissions
-- These features control access to dashboard routes

-- ============================================================================
-- INSERT NEW FEATURES
-- ============================================================================

INSERT INTO "public"."features" ("id", "name", "description", "category")
VALUES
  ('signups_dashboard', 'Signups Dashboard', 'Access to signups dashboard', 'dashboards'),
  ('riding_dashboard', 'Riding Dashboard', 'Access to riding dashboard', 'dashboards'),
  ('campus_dashboard', 'Campus Dashboard', 'Access to campus dashboard', 'dashboards'),
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
WHERE "id" IN (
  'gotv_dashboard',
  'ride_requests_dashboard',
  'all_contacts',
  'form_submissions',
  'signups_dashboard',
  'riding_dashboard',
  'campus_dashboard'
)
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Admin: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'admin', true
FROM "public"."features"
WHERE "id" IN (
  'gotv_dashboard',
  'ride_requests_dashboard',
  'all_contacts',
  'form_submissions',
  'signups_dashboard',
  'riding_dashboard',
  'campus_dashboard'
)
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Member: Organizer dashboards allowed, admin-level dashboards denied
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'member', true
FROM "public"."features"
WHERE "id" IN ('signups_dashboard', 'riding_dashboard', 'campus_dashboard')
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
WHERE "id" IN (
  'gotv_dashboard',
  'ride_requests_dashboard',
  'all_contacts',
  'form_submissions',
  'signups_dashboard',
  'riding_dashboard',
  'campus_dashboard'
)
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Developer: All features allowed
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "id", 'developer', true
FROM "public"."features"
WHERE "id" IN (
  'gotv_dashboard',
  'ride_requests_dashboard',
  'all_contacts',
  'form_submissions',
  'signups_dashboard',
  'riding_dashboard',
  'campus_dashboard'
)
ON CONFLICT ("feature_id", "role_id") DO NOTHING;

-- Signups and Riding dashboards: allow for all roles except locked (including custom roles).
-- Ensures users always have a default landing page even with no data.
INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "f"."id", "r"."id", true
FROM "public"."features" "f"
CROSS JOIN "public"."roles" "r"
WHERE "f"."id" IN ('signups_dashboard', 'riding_dashboard')
  AND "r"."id" <> 'locked'
ON CONFLICT ("feature_id", "role_id") DO UPDATE SET "allowed" = EXCLUDED."allowed";
