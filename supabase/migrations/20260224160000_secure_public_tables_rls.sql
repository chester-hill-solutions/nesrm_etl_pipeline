-- Migration: Secure public tables (RLS + policies)
-- Purpose:
-- - Remove permissive anon policies that effectively bypass RLS.
-- - Enable RLS on public tables that currently have it disabled.
-- - Add explicit service_role policies for RLS-enabled tables used by server code.
-- - Reduce write privileges on PostGIS `spatial_ref_sys` (keep SELECT available).

--------------------------------------------------------------------------------
-- 1) Remove permissive anon access
--------------------------------------------------------------------------------

-- These policies allow unrestricted access for unauthenticated clients.
DROP POLICY IF EXISTS "allow all actions for anon" ON public.contact;
DROP POLICY IF EXISTS "allow all actions for anon" ON public.request;

--------------------------------------------------------------------------------
-- 2) Enable RLS on tables that are currently public without RLS
--------------------------------------------------------------------------------

ALTER TABLE IF EXISTS public.division_electoral_olp_region ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.field_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.organizer_code ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.organizer_code_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.respondent_email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.respondent_sms_templates ENABLE ROW LEVEL SECURITY;

--------------------------------------------------------------------------------
-- 3) Ensure service_role can operate on server-managed tables
--------------------------------------------------------------------------------

-- division_electoral_olp_region
DROP POLICY IF EXISTS "service_role_all" ON public.division_electoral_olp_region;
CREATE POLICY "service_role_all"
  ON public.division_electoral_olp_region
  TO service_role
  USING (true)
  WITH CHECK (true);

-- field_suggestions
DROP POLICY IF EXISTS "service_role_all" ON public.field_suggestions;
CREATE POLICY "service_role_all"
  ON public.field_suggestions
  TO service_role
  USING (true)
  WITH CHECK (true);

-- organizer_code
DROP POLICY IF EXISTS "service_role_all" ON public.organizer_code;
CREATE POLICY "service_role_all"
  ON public.organizer_code
  TO service_role
  USING (true)
  WITH CHECK (true);

-- organizer_code_profiles
DROP POLICY IF EXISTS "service_role_all" ON public.organizer_code_profiles;
CREATE POLICY "service_role_all"
  ON public.organizer_code_profiles
  TO service_role
  USING (true)
  WITH CHECK (true);

-- respondent_email_templates
DROP POLICY IF EXISTS "service_role_all" ON public.respondent_email_templates;
CREATE POLICY "service_role_all"
  ON public.respondent_email_templates
  TO service_role
  USING (true)
  WITH CHECK (true);

-- respondent_sms_templates
DROP POLICY IF EXISTS "service_role_all" ON public.respondent_sms_templates;
CREATE POLICY "service_role_all"
  ON public.respondent_sms_templates
  TO service_role
  USING (true)
  WITH CHECK (true);

-- request: keep it locked down (no anon/auth policies). service_role bypasses RLS,
-- but we add an explicit policy for clarity and future safety.
DROP POLICY IF EXISTS "service_role_all" ON public.request;
CREATE POLICY "service_role_all"
  ON public.request
  TO service_role
  USING (true)
  WITH CHECK (true);

-- donation + division_electoral_district are RLS-enabled but had no policies.
DROP POLICY IF EXISTS "service_role_all" ON public.donation;
CREATE POLICY "service_role_all"
  ON public.donation
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "service_role_all" ON public.division_electoral_district;
CREATE POLICY "service_role_all"
  ON public.division_electoral_district
  TO service_role
  USING (true)
  WITH CHECK (true);

--------------------------------------------------------------------------------
-- 4) PostGIS hardening: `spatial_ref_sys` is required for geometry/geography work.
-- Keep SELECT available but remove write privileges from anon/authenticated.
--------------------------------------------------------------------------------

REVOKE ALL ON TABLE public.spatial_ref_sys FROM anon;
REVOKE ALL ON TABLE public.spatial_ref_sys FROM authenticated;
GRANT SELECT ON TABLE public.spatial_ref_sys TO anon;
GRANT SELECT ON TABLE public.spatial_ref_sys TO authenticated;

