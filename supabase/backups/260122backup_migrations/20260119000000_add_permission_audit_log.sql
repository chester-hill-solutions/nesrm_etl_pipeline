-- Permission Audit Log Table
-- Tracks all changes to roles, features, and permissions for audit and compliance purposes

CREATE TABLE IF NOT EXISTS "public"."permission_audit_log" (
  "id" serial PRIMARY KEY,
  "changed_by" uuid NOT NULL REFERENCES "public"."profiles"("id") ON DELETE SET NULL,
  "change_type" text NOT NULL CHECK ("change_type" IN ('create', 'update', 'delete')),
  "entity_type" text NOT NULL CHECK ("entity_type" IN ('role', 'feature', 'permission')),
  "entity_id" text NOT NULL,
  "old_value" jsonb,
  "new_value" jsonb,
  "metadata" jsonb,
  "created_at" timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE "public"."permission_audit_log" IS 'Audit log for all permission-related changes (roles, features, permissions)';

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS "permission_audit_log_changed_by_idx" ON "public"."permission_audit_log"("changed_by");
CREATE INDEX IF NOT EXISTS "permission_audit_log_entity_idx" ON "public"."permission_audit_log"("entity_type", "entity_id");
CREATE INDEX IF NOT EXISTS "permission_audit_log_created_at_idx" ON "public"."permission_audit_log"("created_at");

-- RLS Policies
ALTER TABLE "public"."permission_audit_log" ENABLE ROW LEVEL SECURITY;

-- Service role can manage audit logs
CREATE POLICY "permission_audit_log_service_role_all" ON "public"."permission_audit_log"
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Authenticated users can read audit logs (admins can view audit history)
CREATE POLICY "permission_audit_log_authenticated_read" ON "public"."permission_audit_log"
  FOR SELECT
  TO authenticated
  USING (true);
