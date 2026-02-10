-- Ensure all non-locked roles have access to My Signups and My Ridings dashboards
-- (even when they have no data). Custom roles without explicit permissions
-- otherwise get denied by check_feature_permission.

INSERT INTO "public"."feature_permissions" ("feature_id", "role_id", "allowed")
SELECT "f"."id", "r"."id", true
FROM "public"."features" "f"
CROSS JOIN "public"."roles" "r"
WHERE "f"."id" IN ('signups_dashboard', 'riding_dashboard')
  AND "r"."id" <> 'locked'
ON CONFLICT ("feature_id", "role_id") DO UPDATE SET "allowed" = EXCLUDED."allowed";
