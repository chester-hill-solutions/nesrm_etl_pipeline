-- Migrate profiles.role from enum (role_type) to DB-backed roles (text FK).
-- This allows custom roles created in `public.roles` to be assigned to users.

-- ============================================================================
-- Ensure system roles exist (required for FK + defaults)
-- ============================================================================
-- Data moved to seeds/20260223190000_migrate_profiles_role_to_roles_fk.sql

-- ============================================================================
-- Drop role_type-dependent policies before altering profiles.role
--
-- Postgres forbids altering a column type when any RLS policy definition depends on it.
-- Existing policies reference `profiles.role` (enum) via `::role_type` casts, so we
-- drop them first and recreate them later in this migration.
-- ============================================================================
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    WITH role_col AS (
      SELECT a.attrelid AS relid, a.attnum AS attnum
      FROM pg_attribute a
      JOIN pg_class c ON c.oid = a.attrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'profiles'
        AND a.attname = 'role'
    )
    SELECT n.nspname AS schemaname, c.relname AS tablename, p.polname AS policyname
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN role_col rc ON true
    JOIN pg_depend d
      ON d.classid = 'pg_policy'::regclass
     AND d.objid = p.oid
     AND d.refclassid = 'pg_class'::regclass
     AND d.refobjid = rc.relid
     AND d.refobjsubid = rc.attnum
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END
$$;

-- ============================================================================
-- Convert profiles.role to text and add FK
-- ============================================================================
ALTER TABLE "public"."profiles"
  ALTER COLUMN "role" DROP DEFAULT;

ALTER TABLE "public"."profiles"
  ALTER COLUMN "role" TYPE "text"
  USING ("role"::"text");

ALTER TABLE "public"."profiles"
  ALTER COLUMN "role" SET DEFAULT 'caller'::"text";

CREATE INDEX IF NOT EXISTS "profiles_role_idx" ON "public"."profiles" USING "btree" ("role");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_role_fkey'
  ) THEN
    ALTER TABLE "public"."profiles"
      ADD CONSTRAINT "profiles_role_fkey"
      FOREIGN KEY ("role")
      REFERENCES "public"."roles" ("id")
      ON UPDATE CASCADE
      ON DELETE RESTRICT;
  END IF;
END
$$;

-- Keep signup_requests.invited_role aligned with roles table too (column is already text).
ALTER TABLE "public"."signup_requests"
  ALTER COLUMN "invited_role" SET DEFAULT 'caller'::"text";

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'signup_requests_invited_role_fkey'
  ) THEN
    ALTER TABLE "public"."signup_requests"
      ADD CONSTRAINT "signup_requests_invited_role_fkey"
      FOREIGN KEY ("invited_role")
      REFERENCES "public"."roles" ("id")
      ON UPDATE CASCADE
      ON DELETE SET NULL;
  END IF;
END
$$;

-- ============================================================================
-- Update policies that referenced role_type casts (text-safe comparisons)
-- ============================================================================

-- api_tokens / api_logs
DROP POLICY IF EXISTS "Only super_admins can create tokens" ON "public"."api_tokens";
CREATE POLICY "Only super_admins can create tokens" ON "public"."api_tokens"
FOR INSERT TO "authenticated"
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND "profiles"."role" = 'super_admin'::"text"
  )
);

DROP POLICY IF EXISTS "Users can delete own tokens, super_admins can delete any" ON "public"."api_tokens";
CREATE POLICY "Users can delete own tokens, super_admins can delete any" ON "public"."api_tokens"
FOR DELETE TO "authenticated"
USING (
  "profile_id" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND "profiles"."role" = 'super_admin'::"text"
  )
);

DROP POLICY IF EXISTS "Users can update own tokens, super_admins can update any" ON "public"."api_tokens";
CREATE POLICY "Users can update own tokens, super_admins can update any" ON "public"."api_tokens"
FOR UPDATE TO "authenticated"
USING (
  "profile_id" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND "profiles"."role" = 'super_admin'::"text"
  )
)
WITH CHECK (
  "profile_id" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND "profiles"."role" = 'super_admin'::"text"
  )
);

DROP POLICY IF EXISTS "Users can view logs for own tokens, super_admins can view all" ON "public"."api_logs";
CREATE POLICY "Users can view logs for own tokens, super_admins can view all" ON "public"."api_logs"
FOR SELECT TO "authenticated"
USING (
  (
    "token_id" IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM "public"."api_tokens"
      WHERE "api_tokens"."id" = "api_logs"."token_id"
        AND "api_tokens"."profile_id" = "auth"."uid"()
    )
  )
  OR ("token_id" IS NULL AND "profile_id" = "auth"."uid"())
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND "profiles"."role" = 'super_admin'::"text"
  )
);

DROP POLICY IF EXISTS "Users can view own tokens, super_admins can view all" ON "public"."api_tokens";
CREATE POLICY "Users can view own tokens, super_admins can view all" ON "public"."api_tokens"
FOR SELECT TO "authenticated"
USING (
  "profile_id" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND "profiles"."role" = 'super_admin'::"text"
  )
);

-- Admin manage policies (super_admin or admin)
-- custom_columns
DROP POLICY IF EXISTS "allow admin delete custom_columns" ON "public"."custom_columns";
CREATE POLICY "allow admin delete custom_columns" ON "public"."custom_columns"
FOR DELETE TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_management')
  )
);

DROP POLICY IF EXISTS "allow admin insert custom_columns" ON "public"."custom_columns";
CREATE POLICY "allow admin insert custom_columns" ON "public"."custom_columns"
FOR INSERT TO "authenticated"
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_management')
  )
  AND "created_by" = "auth"."uid"()
);

DROP POLICY IF EXISTS "allow admin update custom_columns" ON "public"."custom_columns";
CREATE POLICY "allow admin update custom_columns" ON "public"."custom_columns"
FOR UPDATE TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_management')
  )
);

-- column_visibility
DROP POLICY IF EXISTS "allow admin modify column_visibility" ON "public"."column_visibility";
CREATE POLICY "allow admin modify column_visibility" ON "public"."column_visibility"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_management')
  )
);

-- audiences
DROP POLICY IF EXISTS "allow admin manage audiences" ON "public"."audiences";
CREATE POLICY "allow admin manage audiences" ON "public"."audiences"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

-- campaigns
DROP POLICY IF EXISTS "allow admin manage campaigns" ON "public"."campaigns";
CREATE POLICY "allow admin manage campaigns" ON "public"."campaigns"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

-- events
DROP POLICY IF EXISTS "allow admin manage events" ON "public"."events";
CREATE POLICY "allow admin manage events" ON "public"."events"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'events_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'events_admin')
  )
);

-- event management tables (ticket types, promo codes, registrations)
DROP POLICY IF EXISTS "allow admin manage event_ticket_types" ON "public"."event_ticket_types";
CREATE POLICY "allow admin manage event_ticket_types" ON "public"."event_ticket_types"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
);

DROP POLICY IF EXISTS "allow admin read event_promo_codes" ON "public"."event_promo_codes";
CREATE POLICY "allow admin read event_promo_codes" ON "public"."event_promo_codes"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
);

DROP POLICY IF EXISTS "allow admin manage event_promo_codes" ON "public"."event_promo_codes";
CREATE POLICY "allow admin manage event_promo_codes" ON "public"."event_promo_codes"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
);

DROP POLICY IF EXISTS "allow admin read event_registrations" ON "public"."event_registrations";
CREATE POLICY "allow admin read event_registrations" ON "public"."event_registrations"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
);

DROP POLICY IF EXISTS "allow admin manage event_registrations" ON "public"."event_registrations";
CREATE POLICY "allow admin manage event_registrations" ON "public"."event_registrations"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'events_admin')
  )
);

-- data access
DROP POLICY IF EXISTS "allow admin manage field_permissions" ON "public"."data_access_field_permissions";
CREATE POLICY "allow admin manage field_permissions" ON "public"."data_access_field_permissions"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage record_permissions" ON "public"."data_access_record_permissions";
CREATE POLICY "allow admin manage record_permissions" ON "public"."data_access_record_permissions"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

-- survey admin
DROP POLICY IF EXISTS "allow admin manage survey_column_update_rules" ON "public"."survey_column_update_rules";
CREATE POLICY "allow admin manage survey_column_update_rules" ON "public"."survey_column_update_rules"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage survey_instances" ON "public"."survey_instances";
CREATE POLICY "allow admin manage survey_instances" ON "public"."survey_instances"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage survey_page_assignments" ON "public"."survey_page_assignments";
CREATE POLICY "allow admin manage survey_page_assignments" ON "public"."survey_page_assignments"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage survey_pages" ON "public"."survey_pages";
CREATE POLICY "allow admin manage survey_pages" ON "public"."survey_pages"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage survey_questions" ON "public"."survey_questions";
CREATE POLICY "allow admin manage survey_questions" ON "public"."survey_questions"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage survey_response_answers" ON "public"."survey_response_answers";
CREATE POLICY "allow admin manage survey_response_answers" ON "public"."survey_response_answers"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage survey_responses" ON "public"."survey_responses";
CREATE POLICY "allow admin manage survey_responses" ON "public"."survey_responses"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage surveys" ON "public"."surveys";
CREATE POLICY "allow admin manage surveys" ON "public"."surveys"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

-- pages / views
DROP POLICY IF EXISTS "allow admin manage page_questions" ON "public"."page_questions";
CREATE POLICY "allow admin manage page_questions" ON "public"."page_questions"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin manage view_column_visibility" ON "public"."view_column_visibility";
CREATE POLICY "allow admin manage view_column_visibility" ON "public"."view_column_visibility"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_management')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_management')
  )
);

DROP POLICY IF EXISTS "allow admin manage views" ON "public"."views";
CREATE POLICY "allow admin manage views" ON "public"."views"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'view_management')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'view_management')
  )
);

-- Admin read policies
DROP POLICY IF EXISTS "allow admin read column preferences" ON "public"."user_column_preferences";
CREATE POLICY "allow admin read column preferences" ON "public"."user_column_preferences"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin read expanded sections" ON "public"."user_expanded_sections";
CREATE POLICY "allow admin read expanded sections" ON "public"."user_expanded_sections"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin read filter defaults" ON "public"."user_filter_defaults";
CREATE POLICY "allow admin read filter defaults" ON "public"."user_filter_defaults"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin read preferences" ON "public"."user_preferences";
CREATE POLICY "allow admin read preferences" ON "public"."user_preferences"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

DROP POLICY IF EXISTS "allow admin read table preferences" ON "public"."user_table_preferences";
CREATE POLICY "allow admin read table preferences" ON "public"."user_table_preferences"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles"
    WHERE "profiles"."id" = "auth"."uid"()
      AND public.check_feature_permission("profiles"."role", 'admin_dashboard')
  )
);

-- contact_custom_fields: allow admins to read/modify too
DROP POLICY IF EXISTS "allow authenticated modify contact_custom_fields" ON "public"."contact_custom_fields";
CREATE POLICY "allow authenticated modify contact_custom_fields" ON "public"."contact_custom_fields"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."contact" "c"
    WHERE "c"."id" = "contact_custom_fields"."contact_id"
      AND (
        "c"."organizer" IS NULL
        OR EXISTS (
          SELECT 1
          FROM "public"."profiles" "p"
          WHERE "p"."id" = "auth"."uid"()
            AND "p"."organizer_tag" IS NOT NULL
            AND "c"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text")
        )
        OR EXISTS (
          SELECT 1
          FROM "public"."profile_organizer_tags" "pot"
          WHERE "pot"."profile_id" = "auth"."uid"()
            AND "pot"."tag" IS NOT NULL
            AND "c"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text")
        )
        OR EXISTS (
          SELECT 1
          FROM "public"."profiles" "p"
          WHERE "p"."id" = "auth"."uid"()
            AND public.check_feature_permission("p"."role", 'all_contacts')
        )
      )
  )
);

DROP POLICY IF EXISTS "allow authenticated read contact_custom_fields" ON "public"."contact_custom_fields";
CREATE POLICY "allow authenticated read contact_custom_fields" ON "public"."contact_custom_fields"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."contact" "c"
    WHERE "c"."id" = "contact_custom_fields"."contact_id"
      AND (
        "c"."organizer" IS NULL
        OR EXISTS (
          SELECT 1
          FROM "public"."profiles" "p"
          WHERE "p"."id" = "auth"."uid"()
            AND "p"."organizer_tag" IS NOT NULL
            AND "c"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text")
        )
        OR EXISTS (
          SELECT 1
          FROM "public"."profile_organizer_tags" "pot"
          WHERE "pot"."profile_id" = "auth"."uid"()
            AND "pot"."tag" IS NOT NULL
            AND "c"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text")
        )
        OR EXISTS (
          SELECT 1
          FROM "public"."profiles" "p"
          WHERE "p"."id" = "auth"."uid"()
            AND public.check_feature_permission("p"."role", 'all_contacts')
        )
      )
  )
);

-- attachment audit log
DROP POLICY IF EXISTS "attachment_audit_log_admin_select" ON "public"."attachment_audit_log";
CREATE POLICY "attachment_audit_log_admin_select" ON "public"."attachment_audit_log"
FOR SELECT TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'view_audit_log')
  )
);

-- contact attachments
DROP POLICY IF EXISTS "contact_attachment_delete_uploader_or_admin" ON "public"."contact_attachment";
CREATE POLICY "contact_attachment_delete_uploader_or_admin" ON "public"."contact_attachment"
FOR DELETE TO "authenticated"
USING (
  "uploaded_by" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
);

DROP POLICY IF EXISTS "contact_attachment_select_non_deleted" ON "public"."contact_attachment";
CREATE POLICY "contact_attachment_select_non_deleted" ON "public"."contact_attachment"
FOR SELECT TO "authenticated"
USING (
  "deleted_at" IS NULL
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
);

DROP POLICY IF EXISTS "contact_attachment_update_uploader_or_admin" ON "public"."contact_attachment";
CREATE POLICY "contact_attachment_update_uploader_or_admin" ON "public"."contact_attachment"
FOR UPDATE TO "authenticated"
USING (
  "uploaded_by" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
)
WITH CHECK (
  "uploaded_by" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
);

-- contact enrichment
DROP POLICY IF EXISTS "contact_enrichment_admin_all" ON "public"."contact_enrichment";
CREATE POLICY "contact_enrichment_admin_all" ON "public"."contact_enrichment"
TO "authenticated"
USING (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
);

-- contact notes
DROP POLICY IF EXISTS "contact_note_delete_creator_or_admin" ON "public"."contact_note";
CREATE POLICY "contact_note_delete_creator_or_admin" ON "public"."contact_note"
FOR DELETE TO "authenticated"
USING (
  "created_by" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
);

DROP POLICY IF EXISTS "contact_note_select_team_and_own" ON "public"."contact_note";
CREATE POLICY "contact_note_select_team_and_own" ON "public"."contact_note"
FOR SELECT TO "authenticated"
USING (
  "visibility" = 'team'::"text"
  OR ("visibility" = 'private'::"text" AND "created_by" = "auth"."uid"())
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
);

DROP POLICY IF EXISTS "contact_note_update_creator_or_admin" ON "public"."contact_note";
CREATE POLICY "contact_note_update_creator_or_admin" ON "public"."contact_note"
FOR UPDATE TO "authenticated"
USING (
  "created_by" = "auth"."uid"()
  OR EXISTS (
    SELECT 1
    FROM "public"."profiles" "p"
    WHERE "p"."id" = "auth"."uid"()
      AND public.check_feature_permission("p"."role", 'all_contacts')
  )
)
WITH CHECK (
  "updated_by" = "auth"."uid"()
  AND (
    "created_by" = "auth"."uid"()
    OR EXISTS (
      SELECT 1
      FROM "public"."profiles" "p"
      WHERE "p"."id" = "auth"."uid"()
        AND public.check_feature_permission("p"."role", 'all_contacts')
    )
  )
);

-- storage policies for contact attachments bucket (defined in 20260123000003_create_contact_attachments_bucket.sql)
DROP POLICY IF EXISTS "contact_attachments_read_policy" ON storage.objects;
CREATE POLICY "contact_attachments_read_policy"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'contact_attachments' AND
  EXISTS (
    SELECT 1 FROM public.contact_attachment ca
    JOIN public.contact c ON ca.contact_id = c.id
    WHERE ca.storage_path = name
    AND ca.deleted_at IS NULL
    AND (
      c.organizer IS NULL
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.organizer_tag IS NOT NULL
        AND c.organizer ILIKE '%' || p.organizer_tag || '%'
      )
      OR EXISTS (
        SELECT 1 FROM public.profile_organizer_tags pot
        WHERE pot.profile_id = auth.uid()
        AND pot.tag IS NOT NULL
        AND c.organizer ILIKE '%' || pot.tag || '%'
      )
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND public.check_feature_permission(p.role, 'all_contacts')
      )
    )
  )
);

DROP POLICY IF EXISTS "contact_attachments_delete_policy" ON storage.objects;
CREATE POLICY "contact_attachments_delete_policy"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'contact_attachments' AND
  EXISTS (
    SELECT 1 FROM public.contact_attachment ca
    WHERE ca.storage_path = name
    AND (
      ca.uploaded_by = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND public.check_feature_permission(p.role, 'all_contacts')
      )
    )
  )
);
