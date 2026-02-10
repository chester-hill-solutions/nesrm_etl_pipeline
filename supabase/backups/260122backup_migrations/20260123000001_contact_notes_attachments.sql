-- Contact Notes, Attachments, Enrichment, and Audit Log Tables
-- This migration creates tables for contact notes, attachments, enrichment data, and audit logging

-- ============================================================================
-- CONTACT NOTE TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."contact_note" (
  "id" bigserial PRIMARY KEY,
  "contact_id" bigint NOT NULL REFERENCES "public"."contact"("id") ON DELETE CASCADE,
  "content" text NOT NULL CHECK (char_length("content") >= 1 AND char_length("content") <= 10000),
  "content_format" text NOT NULL DEFAULT 'plain' CHECK ("content_format" IN ('plain', 'markdown')),
  "visibility" text NOT NULL DEFAULT 'team' CHECK ("visibility" IN ('private', 'team')),
  "is_pinned" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "created_by" uuid NOT NULL REFERENCES "public"."profiles"("id") ON DELETE RESTRICT,
  "updated_by" uuid REFERENCES "public"."profiles"("id") ON DELETE SET NULL
);

COMMENT ON TABLE "public"."contact_note" IS 'Stores notes associated with contacts. Supports plain text and markdown formats, with visibility controls (private/team) and pinning capability.';

-- Indexes for contact_note
CREATE INDEX IF NOT EXISTS "contact_note_contact_id_idx" ON "public"."contact_note"("contact_id");
CREATE INDEX IF NOT EXISTS "contact_note_created_by_idx" ON "public"."contact_note"("created_by");
CREATE INDEX IF NOT EXISTS "contact_note_is_pinned_idx" ON "public"."contact_note"("is_pinned");
CREATE INDEX IF NOT EXISTS "contact_note_contact_pinned_idx" ON "public"."contact_note"("contact_id", "is_pinned") WHERE "is_pinned" = true;

-- ============================================================================
-- CONTACT ATTACHMENT TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."contact_attachment" (
  "id" bigserial PRIMARY KEY,
  "contact_id" bigint NOT NULL REFERENCES "public"."contact"("id") ON DELETE CASCADE,
  "file_name" text NOT NULL,
  "file_size" bigint NOT NULL CHECK ("file_size" > 0 AND "file_size" <= 10485760),
  "mime_type" text NOT NULL,
  "storage_path" text NOT NULL,
  "deleted_at" timestamptz,
  "deleted_by" uuid REFERENCES "public"."profiles"("id") ON DELETE SET NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "uploaded_by" uuid NOT NULL REFERENCES "public"."profiles"("id") ON DELETE RESTRICT
);

COMMENT ON TABLE "public"."contact_attachment" IS 'Stores metadata for files attached to contacts. Supports soft deletion. Maximum file size is 10MB.';

-- Indexes for contact_attachment
CREATE INDEX IF NOT EXISTS "contact_attachment_contact_id_idx" ON "public"."contact_attachment"("contact_id");
CREATE INDEX IF NOT EXISTS "contact_attachment_uploaded_by_idx" ON "public"."contact_attachment"("uploaded_by");
CREATE INDEX IF NOT EXISTS "contact_attachment_deleted_at_idx" ON "public"."contact_attachment"("deleted_at") WHERE "deleted_at" IS NULL;

-- ============================================================================
-- CONTACT ENRICHMENT TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."contact_enrichment" (
  "id" bigserial PRIMARY KEY,
  "contact_id" bigint NOT NULL REFERENCES "public"."contact"("id") ON DELETE CASCADE,
  "enrichment_type" text NOT NULL CHECK ("enrichment_type" IN ('linkedin', 'company', 'social', 'news')),
  "enrichment_data" jsonb NOT NULL,
  "status" text NOT NULL DEFAULT 'pending' CHECK ("status" IN ('pending', 'completed', 'failed')),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "source" text,
  "confidence_score" numeric
);

COMMENT ON TABLE "public"."contact_enrichment" IS 'Stores enrichment data for contacts from external sources. Admin-only access.';

-- Indexes for contact_enrichment
CREATE INDEX IF NOT EXISTS "contact_enrichment_contact_id_idx" ON "public"."contact_enrichment"("contact_id");
CREATE INDEX IF NOT EXISTS "contact_enrichment_status_idx" ON "public"."contact_enrichment"("status");

-- ============================================================================
-- ATTACHMENT AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."attachment_audit_log" (
  "id" bigserial PRIMARY KEY,
  "attachment_id" bigint NOT NULL REFERENCES "public"."contact_attachment"("id") ON DELETE CASCADE,
  "action" text NOT NULL,
  "performed_by" uuid NOT NULL REFERENCES "public"."profiles"("id") ON DELETE RESTRICT,
  "performed_at" timestamptz NOT NULL DEFAULT now(),
  "metadata" jsonb
);

COMMENT ON TABLE "public"."attachment_audit_log" IS 'Audit log for attachment actions (upload, delete, etc.).';

-- Indexes for attachment_audit_log
CREATE INDEX IF NOT EXISTS "attachment_audit_log_attachment_id_idx" ON "public"."attachment_audit_log"("attachment_id");
CREATE INDEX IF NOT EXISTS "attachment_audit_log_performed_by_idx" ON "public"."attachment_audit_log"("performed_by");
CREATE INDEX IF NOT EXISTS "attachment_audit_log_performed_at_idx" ON "public"."attachment_audit_log"("performed_at");

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION "public"."update_contact_note_updated_at"()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updated_at" = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "update_contact_note_updated_at"
  BEFORE UPDATE ON "public"."contact_note"
  FOR EACH ROW
  EXECUTE FUNCTION "public"."update_contact_note_updated_at"();

-- Trigger function to ensure max one pinned note per contact
CREATE OR REPLACE FUNCTION "public"."ensure_single_pinned_note"()
RETURNS TRIGGER AS $$
BEGIN
  -- If this note is being pinned, unpin all other notes for this contact
  IF NEW."is_pinned" = true THEN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD."is_pinned" = false) THEN
      UPDATE "public"."contact_note"
      SET "is_pinned" = false
      WHERE "contact_id" = NEW."contact_id"
        AND "id" != NEW."id"
        AND "is_pinned" = true;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "ensure_single_pinned_note"
  BEFORE INSERT OR UPDATE ON "public"."contact_note"
  FOR EACH ROW
  EXECUTE FUNCTION "public"."ensure_single_pinned_note"();

-- Trigger function to validate attachment updates
CREATE OR REPLACE FUNCTION "public"."validate_attachment_update"()
RETURNS TRIGGER AS $$
DECLARE
  is_admin boolean;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM "public"."profiles" "p"
    WHERE "p"."id" = auth.uid()
      AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
  ) INTO is_admin;

  -- Validate deleted_at changes
  IF OLD."deleted_at" IS DISTINCT FROM NEW."deleted_at" THEN
    -- Soft delete: must be uploader and deleted_at was NULL
    IF OLD."deleted_at" IS NULL AND NEW."deleted_at" IS NOT NULL THEN
      IF NEW."uploaded_by" != auth.uid() THEN
        RAISE EXCEPTION 'Only the uploader can delete attachments';
      END IF;
      IF NEW."deleted_by" != auth.uid() THEN
        RAISE EXCEPTION 'deleted_by must match the current user';
      END IF;
    -- Restore: must be admin and deleted_at was NOT NULL
    ELSIF OLD."deleted_at" IS NOT NULL AND NEW."deleted_at" IS NULL THEN
      IF NOT is_admin THEN
        RAISE EXCEPTION 'Only admins can restore deleted attachments';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER "validate_attachment_update"
  BEFORE UPDATE ON "public"."contact_attachment"
  FOR EACH ROW
  EXECUTE FUNCTION "public"."validate_attachment_update"();

-- Trigger function to log attachment deletions
CREATE OR REPLACE FUNCTION "public"."log_attachment_deletion"()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD."deleted_at" IS NULL AND NEW."deleted_at" IS NOT NULL THEN
    INSERT INTO "public"."attachment_audit_log" ("attachment_id", "action", "performed_by", "metadata")
    VALUES (
      NEW."id",
      'delete',
      COALESCE(NEW."deleted_by", '00000000-0000-0000-0000-000000000000'::uuid),
      jsonb_build_object('file_name', NEW."file_name", 'deleted_at', NEW."deleted_at")
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "log_attachment_deletion"
  AFTER UPDATE ON "public"."contact_attachment"
  FOR EACH ROW
  EXECUTE FUNCTION "public"."log_attachment_deletion"();

-- Trigger function to update contact_enrichment updated_at
CREATE OR REPLACE FUNCTION "public"."update_contact_enrichment_updated_at"()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updated_at" = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "update_contact_enrichment_updated_at"
  BEFORE UPDATE ON "public"."contact_enrichment"
  FOR EACH ROW
  EXECUTE FUNCTION "public"."update_contact_enrichment_updated_at"();

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE "public"."contact_note" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."contact_attachment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."contact_enrichment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."attachment_audit_log" ENABLE ROW LEVEL SECURITY;

-- Contact Note Policies
-- Users can see team notes + own private notes, admins see all
CREATE POLICY "contact_note_select_team_and_own" ON "public"."contact_note"
  FOR SELECT
  TO authenticated
  USING (
    -- Team notes are visible to all authenticated users
    "visibility" = 'team'
    OR
    -- Private notes are visible to creator
    ("visibility" = 'private' AND "created_by" = auth.uid())
    OR
    -- Admins can see all notes
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Users can create notes
CREATE POLICY "contact_note_insert_authenticated" ON "public"."contact_note"
  FOR INSERT
  TO authenticated
  WITH CHECK ("created_by" = auth.uid());

-- Only creator or admins can update notes
CREATE POLICY "contact_note_update_creator_or_admin" ON "public"."contact_note"
  FOR UPDATE
  TO authenticated
  USING (
    "created_by" = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  )
  WITH CHECK (
    "updated_by" = auth.uid()
    AND (
      "created_by" = auth.uid()
      OR
      EXISTS (
        SELECT 1 FROM "public"."profiles" "p"
        WHERE "p"."id" = auth.uid()
          AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
      )
    )
  );

-- Only creator or admins can delete notes
CREATE POLICY "contact_note_delete_creator_or_admin" ON "public"."contact_note"
  FOR DELETE
  TO authenticated
  USING (
    "created_by" = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Contact Attachment Policies
-- Users can see non-deleted attachments, admins see all
CREATE POLICY "contact_attachment_select_non_deleted" ON "public"."contact_attachment"
  FOR SELECT
  TO authenticated
  USING (
    "deleted_at" IS NULL
    OR
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Users can upload attachments
CREATE POLICY "contact_attachment_insert_authenticated" ON "public"."contact_attachment"
  FOR INSERT
  TO authenticated
  WITH CHECK ("uploaded_by" = auth.uid());

-- Only uploader or admins can update attachments
-- The validate_attachment_update trigger enforces deleted_at change rules
CREATE POLICY "contact_attachment_update_uploader_or_admin" ON "public"."contact_attachment"
  FOR UPDATE
  TO authenticated
  USING (
    "uploaded_by" = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  )
  WITH CHECK (
    "uploaded_by" = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Only uploader or admins can delete attachments
CREATE POLICY "contact_attachment_delete_uploader_or_admin" ON "public"."contact_attachment"
  FOR DELETE
  TO authenticated
  USING (
    "uploaded_by" = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Contact Enrichment Policies (Admin-only)
CREATE POLICY "contact_enrichment_admin_all" ON "public"."contact_enrichment"
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Attachment Audit Log Policies (Admin-only)
CREATE POLICY "attachment_audit_log_admin_select" ON "public"."attachment_audit_log"
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM "public"."profiles" "p"
      WHERE "p"."id" = auth.uid()
        AND "p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])
    )
  );

-- Service role has full access
CREATE POLICY "contact_note_service_role_all" ON "public"."contact_note"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "contact_attachment_service_role_all" ON "public"."contact_attachment"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "contact_enrichment_service_role_all" ON "public"."contact_enrichment"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "attachment_audit_log_service_role_all" ON "public"."attachment_audit_log"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT ALL ON TABLE "public"."contact_note" TO authenticated, service_role;
GRANT ALL ON TABLE "public"."contact_attachment" TO authenticated, service_role;
GRANT ALL ON TABLE "public"."contact_enrichment" TO authenticated, service_role;
GRANT ALL ON TABLE "public"."attachment_audit_log" TO authenticated, service_role;

GRANT USAGE ON SEQUENCE "public"."contact_note_id_seq" TO authenticated, service_role;
GRANT USAGE ON SEQUENCE "public"."contact_attachment_id_seq" TO authenticated, service_role;
GRANT USAGE ON SEQUENCE "public"."contact_enrichment_id_seq" TO authenticated, service_role;
GRANT USAGE ON SEQUENCE "public"."attachment_audit_log_id_seq" TO authenticated, service_role;
