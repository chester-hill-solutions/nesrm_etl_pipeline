-- Add contact_restrictions field to surveys table
-- This allows surveys to be restricted based on contact properties
-- Example: { "ballot1": { "value": "Not Nate", "allowedRoles": ["admin", "super_admin"] } }

ALTER TABLE "public"."surveys"
  ADD COLUMN IF NOT EXISTS "contact_restrictions" jsonb DEFAULT NULL;

COMMENT ON COLUMN "public"."surveys"."contact_restrictions" IS 'JSON object defining contact property-based restrictions. Format: { "fieldName": { "value": "expectedValue", "allowedRoles": ["role1", "role2"] } }';
