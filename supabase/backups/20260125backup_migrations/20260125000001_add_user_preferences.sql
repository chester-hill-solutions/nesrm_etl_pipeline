-- Unified User Preferences System
-- This migration renames user_view_preferences to user_preferences and adds new tables
-- for storing all user UI preferences (theme, columns, expanded sections, filters, table prefs)
-- Note: This migration requires the profiles, views, and custom_columns tables to exist

-- ============================================================================
-- RENAME USER_VIEW_PREFERENCES TO USER_PREFERENCES
-- ============================================================================

-- Rename table to be more general (not view-specific)
ALTER TABLE IF EXISTS "public"."user_view_preferences" 
RENAME TO "user_preferences";

-- Rename constraints to match new table name
ALTER TABLE "public"."user_preferences"
RENAME CONSTRAINT "user_view_preferences_pkey" TO "user_preferences_pkey";

ALTER TABLE "public"."user_preferences"
RENAME CONSTRAINT "user_view_preferences_user_id_unique" TO "user_preferences_user_id_unique";

-- Rename foreign key constraints
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'user_view_preferences_user_id_fkey'
    ) THEN
        ALTER TABLE "public"."user_preferences" 
        RENAME CONSTRAINT "user_view_preferences_user_id_fkey" TO "user_preferences_user_id_fkey";
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public' 
        AND constraint_name = 'user_view_preferences_current_view_id_fkey'
    ) THEN
        ALTER TABLE "public"."user_preferences" 
        RENAME CONSTRAINT "user_view_preferences_current_view_id_fkey" TO "user_preferences_current_view_id_fkey";
    END IF;
END $$;

-- Rename trigger
DROP TRIGGER IF EXISTS "update_user_view_preferences_updated_at" ON "public"."user_preferences";
CREATE OR REPLACE TRIGGER "update_user_preferences_updated_at" 
BEFORE UPDATE ON "public"."user_preferences" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."update_updated_at_column"();

-- Rename sequence
ALTER SEQUENCE IF EXISTS "public"."user_view_preferences_id_seq" 
RENAME TO "user_preferences_id_seq";

-- Update table comment
COMMENT ON TABLE "public"."user_preferences" IS 'Stores user preferences: theme and current view. One row per user. Can be extended with more preference columns in the future.';

-- Add theme column for user preference
ALTER TABLE "public"."user_preferences" 
ADD COLUMN IF NOT EXISTS "theme" text DEFAULT 'system' NOT NULL;

-- Add check constraint for theme values
ALTER TABLE "public"."user_preferences"
ADD CONSTRAINT "user_preferences_theme_check" 
CHECK ("theme" IN ('light', 'dark', 'system'));

COMMENT ON COLUMN "public"."user_preferences"."theme" IS 'User theme preference: light, dark, or system (follows OS preference)';

-- Rename RLS policies
DROP POLICY IF EXISTS "allow users manage own preferences" ON "public"."user_preferences";
DROP POLICY IF EXISTS "allow admin read preferences" ON "public"."user_preferences";

CREATE POLICY "allow users manage own preferences" ON "public"."user_preferences" TO "authenticated"
USING ("user_id" = auth.uid())
WITH CHECK ("user_id" = auth.uid());

CREATE POLICY "allow admin read preferences" ON "public"."user_preferences" FOR SELECT TO "authenticated"
USING (
    EXISTS (
        SELECT 1
        FROM "public"."profiles"
        WHERE "profiles"."id" = auth.uid()
        AND "profiles"."role" IN ('super_admin', 'admin')
    )
);

-- ============================================================================
-- USER_COLUMN_PREFERENCES TABLE (Route-Scoped Column Visibility/Order)
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."user_column_preferences" (
    "id" bigint NOT NULL,
    "user_id" uuid NOT NULL,
    "route" text NOT NULL,
    "column_name" text,
    "custom_column_id" bigint,
    "visible" boolean DEFAULT true NOT NULL,
    "display_order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "user_column_preferences_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "user_column_preferences_user_id_fkey" FOREIGN KEY ("user_id") 
        REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    CONSTRAINT "user_column_preferences_custom_column_id_fkey" FOREIGN KEY ("custom_column_id") 
        REFERENCES "public"."custom_columns"("id") ON DELETE CASCADE,
    CONSTRAINT "user_column_preferences_column_type_check" CHECK (
        ("column_name" IS NOT NULL AND "custom_column_id" IS NULL) OR
        ("column_name" IS NULL AND "custom_column_id" IS NOT NULL)
    ),
    CONSTRAINT "user_column_preferences_user_route_column_unique" UNIQUE ("user_id", "route", "column_name", "custom_column_id")
);

ALTER TABLE "public"."user_column_preferences" OWNER TO "postgres";

COMMENT ON TABLE "public"."user_column_preferences" IS 'Stores user column visibility and order preferences, scoped by route. Supports both default columns (via column_name) and custom columns (via custom_column_id).';
COMMENT ON COLUMN "public"."user_column_preferences"."route" IS 'Normalized route path (e.g., "dashboards/gotv") used to scope preferences per page';
COMMENT ON COLUMN "public"."user_column_preferences"."column_name" IS 'References column_visibility.column_name for default columns. Must be NULL if custom_column_id is set.';
COMMENT ON COLUMN "public"."user_column_preferences"."custom_column_id" IS 'References custom_columns.id for custom columns. Must be NULL if column_name is set.';

ALTER TABLE "public"."user_column_preferences" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_column_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Indexes for user_column_preferences
CREATE INDEX "user_column_preferences_user_id_idx" ON "public"."user_column_preferences" USING btree ("user_id");
CREATE INDEX "user_column_preferences_route_idx" ON "public"."user_column_preferences" USING btree ("route");
CREATE INDEX "user_column_preferences_user_route_idx" ON "public"."user_column_preferences" USING btree ("user_id", "route");
CREATE INDEX "user_column_preferences_column_name_idx" ON "public"."user_column_preferences" USING btree ("column_name");
CREATE INDEX "user_column_preferences_custom_column_id_idx" ON "public"."user_column_preferences" USING btree ("custom_column_id");

-- Trigger for updated_at
CREATE OR REPLACE TRIGGER "update_user_column_preferences_updated_at" 
BEFORE UPDATE ON "public"."user_column_preferences" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."update_updated_at_column"();

-- ============================================================================
-- USER_EXPANDED_SECTIONS TABLE (Route-Scoped Expanded Sections)
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."user_expanded_sections" (
    "id" bigint NOT NULL,
    "user_id" uuid NOT NULL,
    "route" text NOT NULL,
    "section_key" text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "user_expanded_sections_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "user_expanded_sections_user_id_fkey" FOREIGN KEY ("user_id") 
        REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    CONSTRAINT "user_expanded_sections_user_route_section_unique" UNIQUE ("user_id", "route", "section_key")
);

ALTER TABLE "public"."user_expanded_sections" OWNER TO "postgres";

COMMENT ON TABLE "public"."user_expanded_sections" IS 'Stores which sections are expanded for a user on a specific route. Each row represents one expanded section.';
COMMENT ON COLUMN "public"."user_expanded_sections"."route" IS 'Normalized route path (e.g., "admin/team") used to scope expanded sections per page';
COMMENT ON COLUMN "public"."user_expanded_sections"."section_key" IS 'Identifier for the section (e.g., "team-directory", "pending-requests")';

ALTER TABLE "public"."user_expanded_sections" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_expanded_sections_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Indexes for user_expanded_sections
CREATE INDEX "user_expanded_sections_user_id_idx" ON "public"."user_expanded_sections" USING btree ("user_id");
CREATE INDEX "user_expanded_sections_route_idx" ON "public"."user_expanded_sections" USING btree ("route");
CREATE INDEX "user_expanded_sections_user_route_idx" ON "public"."user_expanded_sections" USING btree ("user_id", "route");

-- Trigger for updated_at
CREATE OR REPLACE TRIGGER "update_user_expanded_sections_updated_at" 
BEFORE UPDATE ON "public"."user_expanded_sections" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."update_updated_at_column"();

-- ============================================================================
-- USER_FILTER_DEFAULTS TABLE (Route-Scoped Filter Defaults)
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."user_filter_defaults" (
    "id" bigint NOT NULL,
    "user_id" uuid NOT NULL,
    "route" text NOT NULL,
    "filter_config" jsonb NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "user_filter_defaults_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "user_filter_defaults_user_id_fkey" FOREIGN KEY ("user_id") 
        REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    CONSTRAINT "user_filter_defaults_user_route_unique" UNIQUE ("user_id", "route")
);

ALTER TABLE "public"."user_filter_defaults" OWNER TO "postgres";

COMMENT ON TABLE "public"."user_filter_defaults" IS 'Stores default filter preferences per route. Uses JSONB for FilterGroup structure, following the same pattern as saved_filters.config and views.filter_config.';
COMMENT ON COLUMN "public"."user_filter_defaults"."route" IS 'Normalized route path (e.g., "dashboards/gotv") used to scope filter defaults per page';
COMMENT ON COLUMN "public"."user_filter_defaults"."filter_config" IS 'FilterGroup JSON structure matching saved_filters.filter_config format';

ALTER TABLE "public"."user_filter_defaults" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_filter_defaults_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Indexes for user_filter_defaults
CREATE INDEX "user_filter_defaults_user_id_idx" ON "public"."user_filter_defaults" USING btree ("user_id");
CREATE INDEX "user_filter_defaults_route_idx" ON "public"."user_filter_defaults" USING btree ("route");
CREATE INDEX "user_filter_defaults_user_route_idx" ON "public"."user_filter_defaults" USING btree ("user_id", "route");

-- Trigger for updated_at
CREATE OR REPLACE TRIGGER "update_user_filter_defaults_updated_at" 
BEFORE UPDATE ON "public"."user_filter_defaults" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."update_updated_at_column"();

-- ============================================================================
-- USER_TABLE_PREFERENCES TABLE (Route-Scoped Table Preferences)
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."user_table_preferences" (
    "id" bigint NOT NULL,
    "user_id" uuid NOT NULL,
    "route" text NOT NULL,
    "page_size" integer,
    "sort_by" text,
    "sort_order" text CHECK ("sort_order" IN ('asc', 'desc')),
    "pinned_headers" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "user_table_preferences_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "user_table_preferences_user_id_fkey" FOREIGN KEY ("user_id") 
        REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    CONSTRAINT "user_table_preferences_user_route_unique" UNIQUE ("user_id", "route")
);

ALTER TABLE "public"."user_table_preferences" OWNER TO "postgres";

COMMENT ON TABLE "public"."user_table_preferences" IS 'Stores table-specific preferences per route: default page size, sort column/order, and pinned headers state.';
COMMENT ON COLUMN "public"."user_table_preferences"."route" IS 'Normalized route path (e.g., "dashboards/gotv") used to scope table preferences per page';
COMMENT ON COLUMN "public"."user_table_preferences"."page_size" IS 'Default page size for pagination on this route. NULL means use global default.';
COMMENT ON COLUMN "public"."user_table_preferences"."sort_by" IS 'Default sort column for this route. NULL means use global default.';
COMMENT ON COLUMN "public"."user_table_preferences"."sort_order" IS 'Default sort order (asc/desc) for this route. NULL means use global default.';
COMMENT ON COLUMN "public"."user_table_preferences"."pinned_headers" IS 'Whether table headers should be pinned (sticky) on this route.';

ALTER TABLE "public"."user_table_preferences" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_table_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Indexes for user_table_preferences
CREATE INDEX "user_table_preferences_user_id_idx" ON "public"."user_table_preferences" USING btree ("user_id");
CREATE INDEX "user_table_preferences_route_idx" ON "public"."user_table_preferences" USING btree ("route");
CREATE INDEX "user_table_preferences_user_route_idx" ON "public"."user_table_preferences" USING btree ("user_id", "route");

-- Trigger for updated_at
CREATE OR REPLACE TRIGGER "update_user_table_preferences_updated_at" 
BEFORE UPDATE ON "public"."user_table_preferences" 
FOR EACH ROW 
EXECUTE FUNCTION "public"."update_updated_at_column"();

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all new tables
ALTER TABLE "public"."user_column_preferences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."user_expanded_sections" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."user_filter_defaults" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."user_table_preferences" ENABLE ROW LEVEL SECURITY;

-- User column preferences: Users can manage their own, admins can read all
CREATE POLICY "allow users manage own column preferences" ON "public"."user_column_preferences" TO "authenticated"
USING ("user_id" = auth.uid())
WITH CHECK ("user_id" = auth.uid());

CREATE POLICY "allow admin read column preferences" ON "public"."user_column_preferences" FOR SELECT TO "authenticated"
USING (
    EXISTS (
        SELECT 1
        FROM "public"."profiles"
        WHERE "profiles"."id" = auth.uid()
        AND "profiles"."role" IN ('super_admin', 'admin')
    )
);

-- User expanded sections: Users can manage their own, admins can read all
CREATE POLICY "allow users manage own expanded sections" ON "public"."user_expanded_sections" TO "authenticated"
USING ("user_id" = auth.uid())
WITH CHECK ("user_id" = auth.uid());

CREATE POLICY "allow admin read expanded sections" ON "public"."user_expanded_sections" FOR SELECT TO "authenticated"
USING (
    EXISTS (
        SELECT 1
        FROM "public"."profiles"
        WHERE "profiles"."id" = auth.uid()
        AND "profiles"."role" IN ('super_admin', 'admin')
    )
);

-- User filter defaults: Users can manage their own, admins can read all
CREATE POLICY "allow users manage own filter defaults" ON "public"."user_filter_defaults" TO "authenticated"
USING ("user_id" = auth.uid())
WITH CHECK ("user_id" = auth.uid());

CREATE POLICY "allow admin read filter defaults" ON "public"."user_filter_defaults" FOR SELECT TO "authenticated"
USING (
    EXISTS (
        SELECT 1
        FROM "public"."profiles"
        WHERE "profiles"."id" = auth.uid()
        AND "profiles"."role" IN ('super_admin', 'admin')
    )
);

-- User table preferences: Users can manage their own, admins can read all
CREATE POLICY "allow users manage own table preferences" ON "public"."user_table_preferences" TO "authenticated"
USING ("user_id" = auth.uid())
WITH CHECK ("user_id" = auth.uid());

CREATE POLICY "allow admin read table preferences" ON "public"."user_table_preferences" FOR SELECT TO "authenticated"
USING (
    EXISTS (
        SELECT 1
        FROM "public"."profiles"
        WHERE "profiles"."id" = auth.uid()
        AND "profiles"."role" IN ('super_admin', 'admin')
    )
);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT ALL ON TABLE "public"."user_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_preferences" TO "service_role";

GRANT ALL ON SEQUENCE "public"."user_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_preferences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_preferences_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."user_column_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_column_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_column_preferences" TO "service_role";

GRANT ALL ON SEQUENCE "public"."user_column_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_column_preferences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_column_preferences_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."user_expanded_sections" TO "anon";
GRANT ALL ON TABLE "public"."user_expanded_sections" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expanded_sections" TO "service_role";

GRANT ALL ON SEQUENCE "public"."user_expanded_sections_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_expanded_sections_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_expanded_sections_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."user_filter_defaults" TO "anon";
GRANT ALL ON TABLE "public"."user_filter_defaults" TO "authenticated";
GRANT ALL ON TABLE "public"."user_filter_defaults" TO "service_role";

GRANT ALL ON SEQUENCE "public"."user_filter_defaults_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_filter_defaults_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_filter_defaults_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."user_table_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_table_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_table_preferences" TO "service_role";

GRANT ALL ON SEQUENCE "public"."user_table_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_table_preferences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_table_preferences_id_seq" TO "service_role";
