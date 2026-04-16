-- Optimize check_feature_permission: one query instead of three sequential lookups.
-- Same semantics: false if role missing, feature missing/disabled, or no permission (deny by default).

CREATE OR REPLACE FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text")
RETURNS boolean
LANGUAGE "plpgsql"
SECURITY DEFINER
AS $$
DECLARE
  "v_allowed" boolean;
BEGIN
  SELECT fp.allowed INTO "v_allowed"
  FROM "public"."feature_permissions" fp
  INNER JOIN "public"."features" f ON f.id = fp.feature_id AND f.enabled = true
  INNER JOIN "public"."roles" r ON r.id = fp.role_id
  WHERE fp.feature_id = "p_feature_id"
    AND fp.role_id = "p_role_id";

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  RETURN "v_allowed";
END;
$$;

COMMENT ON FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") IS
  'Checks if a role (system or custom) has permission to access a feature. Returns false if feature is disabled, permission not granted, or feature/permission does not exist.';
