-- Add events table for OLP event syncing and ICS calendar generation

-- ============================================================================
-- TABLE DEFINITION
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" text NOT NULL,
    "slug" text NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "start_date" timestamp with time zone NOT NULL,
    "end_date" timestamp with time zone NOT NULL,
    "location_name" text,
    "location_address" text,
    "category" text,
    "source" text NOT NULL,
    "is_external" boolean DEFAULT false NOT NULL,
    "external_url" text,
    "is_ticketed" boolean DEFAULT false NOT NULL,
    "cost" text,
    "tags" text[],
    "status" text DEFAULT 'active' NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "last_synced_at" timestamp with time zone,
    "sync_error" text,
    CONSTRAINT "events_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "events_status_check" CHECK (("status" = ANY (ARRAY['active'::text, 'cancelled'::text, 'archived'::text])))
);

ALTER TABLE "public"."events" OWNER TO "postgres";

COMMENT ON TABLE "public"."events" IS 'Events synced from external sources (OLP) and internal/manual events. Supports ICS calendar generation with filtering.';
COMMENT ON COLUMN "public"."events"."id" IS 'Unique event ID (e.g., olp-slug-2025-01-15)';
COMMENT ON COLUMN "public"."events"."slug" IS 'URL-friendly identifier';
COMMENT ON COLUMN "public"."events"."source" IS 'Event source: olp or nate';
COMMENT ON COLUMN "public"."events"."is_external" IS 'True for synced events from external sources (OLP), false for internal/manual events';
COMMENT ON COLUMN "public"."events"."status" IS 'Event status: active, cancelled, or archived';
COMMENT ON COLUMN "public"."events"."last_synced_at" IS 'When this event was last updated from source';
COMMENT ON COLUMN "public"."events"."sync_error" IS 'Last sync error message if sync failed';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS "events_start_date_idx" ON "public"."events" ("start_date");
CREATE INDEX IF NOT EXISTS "events_source_idx" ON "public"."events" ("source");
CREATE INDEX IF NOT EXISTS "events_category_idx" ON "public"."events" ("category");
CREATE INDEX IF NOT EXISTS "events_is_external_idx" ON "public"."events" ("is_external");
CREATE INDEX IF NOT EXISTS "events_status_idx" ON "public"."events" ("status");
CREATE INDEX IF NOT EXISTS "events_composite_idx" ON "public"."events" ("is_external", "status", "start_date");

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE OR REPLACE TRIGGER "update_events_updated_at" 
    BEFORE UPDATE ON "public"."events" 
    FOR EACH ROW 
    EXECUTE FUNCTION "public"."update_updated_at_column"();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow public read events" ON "public"."events"
    FOR SELECT
    TO "anon", "authenticated"
    USING (true);

CREATE POLICY "allow authenticated read events" ON "public"."events"
    FOR SELECT
    TO "authenticated"
    USING (true);

CREATE POLICY "allow admin manage events" ON "public"."events"
    TO "authenticated"
    USING (
        EXISTS (
            SELECT 1
            FROM "public"."profiles"
            WHERE "profiles"."id" = auth.uid()
            AND "profiles"."role" IN ('super_admin', 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM "public"."profiles"
            WHERE "profiles"."id" = auth.uid()
            AND "profiles"."role" IN ('super_admin', 'admin')
        )
    );

-- ============================================================================
-- PERMISSIONS
-- ============================================================================

GRANT SELECT ON TABLE "public"."events" TO "anon";
GRANT SELECT ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";
