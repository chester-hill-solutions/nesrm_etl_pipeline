-- Add 'developer' role to role_type enum

ALTER TYPE public.role_type ADD VALUE IF NOT EXISTS 'developer';

-- Update comments to include developer role
COMMENT ON COLUMN "public"."survey_pages"."visible_to_roles" IS 'Array of role types that can see this page by default. NULL or empty array means visible to all roles. Valid values: super_admin, admin, member, locked, developer';
COMMENT ON COLUMN "public"."survey_questions"."visible_to_roles" IS 'Array of role types that can see this question. NULL or empty array means visible to all roles. Valid values: super_admin, admin, member, locked, developer';
COMMENT ON COLUMN "public"."surveys"."visible_to_roles" IS 'Array of role types that can see this survey. NULL or empty array means visible to all roles. Valid values: super_admin, admin, member, locked, developer';
