-- Create field_suggestions table for change suggestion system
-- Allows non-admin users to suggest field changes instead of directly editing
-- Admins can review and approve/reject suggestions in bulk

CREATE TABLE IF NOT EXISTS public.field_suggestions (
  id BIGSERIAL PRIMARY KEY,
  entity_type TEXT NOT NULL, -- 'contact', 'profile', etc. (extensible)
  entity_id BIGINT NOT NULL,
  field_name TEXT NOT NULL, -- Display key (e.g., 'firstname', 'phone')
  db_column_name TEXT, -- Database column name (for validation, nullable for custom fields)
  current_value JSONB, -- Current value at time of suggestion
  suggested_value JSONB NOT NULL, -- Suggested new value
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  suggested_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Note: We don't add FK constraint on entity_id because:
-- 1. It's polymorphic (contact, profile, etc.)
-- 2. We want to keep suggestions even if entity is soft-deleted
-- 3. We'll validate entity exists before approving

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_field_suggestions_entity ON field_suggestions(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_field_suggestions_status ON field_suggestions(status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_field_suggestions_suggested_by ON field_suggestions(suggested_by);
CREATE INDEX IF NOT EXISTS idx_field_suggestions_created_at ON field_suggestions(created_at DESC);
-- Composite index for common query pattern (checking if field has pending suggestion)
CREATE INDEX IF NOT EXISTS idx_field_suggestions_entity_field_status ON field_suggestions(entity_type, entity_id, field_name, status) 
  WHERE status = 'pending';

-- Prevent duplicate pending suggestions for same field using a unique partial index
CREATE UNIQUE INDEX IF NOT EXISTS idx_field_suggestions_unique_pending 
  ON field_suggestions(entity_type, entity_id, field_name) 
  WHERE status = 'pending';


-- Rollback instructions (for reference):
-- DELETE FROM "public"."feature_permissions" WHERE "feature_id" IN ('make_suggestion', 'accept_suggestion');
-- DELETE FROM "public"."features" WHERE "id" IN ('make_suggestion', 'accept_suggestion');
-- DROP INDEX IF EXISTS idx_field_suggestions_entity_field_status;
-- DROP INDEX IF EXISTS idx_field_suggestions_created_at;
-- DROP INDEX IF EXISTS idx_field_suggestions_suggested_by;
-- DROP INDEX IF EXISTS idx_field_suggestions_status;
-- DROP INDEX IF EXISTS idx_field_suggestions_entity;
-- DROP TABLE IF EXISTS field_suggestions;
