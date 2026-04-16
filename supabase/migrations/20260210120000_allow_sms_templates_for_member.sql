-- Allow member role to access sms_templates so the respondent-sms-templates
-- dashboard data route works for survey modal template selector (mirrors email_templates).
UPDATE "public"."feature_permissions"
SET "allowed" = true
WHERE "feature_id" = 'sms_templates'
  AND "role_id" = 'member';
