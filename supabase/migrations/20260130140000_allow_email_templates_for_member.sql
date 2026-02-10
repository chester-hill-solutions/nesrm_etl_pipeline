-- Allow member role to access email_templates so the respondent-email-templates
-- data route (used by survey modal) remains accessible to all profile users.
-- Preserves current permissions; admins can revoke via role management if desired.

UPDATE "public"."feature_permissions"
SET "allowed" = true, "updated_at" = NOW()
WHERE "feature_id" = 'email_templates'
  AND "role_id" = 'member';
