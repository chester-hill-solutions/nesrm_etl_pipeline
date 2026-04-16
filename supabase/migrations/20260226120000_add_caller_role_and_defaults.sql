-- Ensure `caller` role exists and is the default for signups/profiles.
-- This migration is intentionally idempotent: safe to run on any env.

-- ============================================================================
-- Ensure system roles exist (including caller)
-- ============================================================================
-- Data moved to seeds/20260225235959_add_caller_role_and_defaults.sql

-- ============================================================================
-- Defaults: new profiles + signup requests should default to caller
-- ============================================================================
ALTER TABLE "public"."profiles"
  ALTER COLUMN "role" SET DEFAULT 'caller'::"text";

ALTER TABLE "public"."signup_requests"
  ALTER COLUMN "invited_role" SET DEFAULT 'caller'::"text";

-- ============================================================================
-- Backfill: pending non-invite signup requests should show caller by default
-- ============================================================================
UPDATE "public"."signup_requests"
SET "invited_role" = 'caller'::"text"
WHERE "invited" = false
  AND "status" = 'pending'::"text"
  AND ("invited_role" IS NULL OR "invited_role" = 'member'::"text");
