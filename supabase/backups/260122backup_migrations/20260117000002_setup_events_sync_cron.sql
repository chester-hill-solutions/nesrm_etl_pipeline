-- Setup cron job functions for events sync

-- Enable required extensions if not already enabled
-- Note: pg_net is already enabled in base schema (accessed as net.*)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================================
-- CONFIG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."events_sync_config" (
    "id" text PRIMARY KEY DEFAULT 'default',
    "auth_token" text NOT NULL,
    "project_ref" text NOT NULL DEFAULT 'gjbzjjwtwcgfbjjmuery',
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT "events_sync_config_single_row" CHECK ("id" = 'default')
);

ALTER TABLE "public"."events_sync_config" OWNER TO "postgres";

CREATE OR REPLACE TRIGGER "update_events_sync_config_updated_at" 
    BEFORE UPDATE ON "public"."events_sync_config" 
    FOR EACH ROW 
    EXECUTE FUNCTION "public"."update_updated_at_column"();

ALTER TABLE "public"."events_sync_config" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow service_role manage config" ON "public"."events_sync_config"
    TO "service_role"
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Helper function to check cron job status
CREATE OR REPLACE FUNCTION check_events_sync_cron()
RETURNS TABLE(
  jobname text,
  schedule text,
  active boolean,
  command text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    jobname::text,
    schedule::text,
    active,
    command::text
  FROM cron.job
  WHERE jobname = 'events-sync';
$$;

-- Function to set or update the auth token in config
CREATE OR REPLACE FUNCTION set_events_sync_auth_token(
  auth_token text,
  project_ref text DEFAULT 'gjbzjjwtwcgfbjjmuery'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO "public"."events_sync_config" ("id", "auth_token", "project_ref")
  VALUES ('default', auth_token, project_ref)
  ON CONFLICT ("id") 
  DO UPDATE SET 
    "auth_token" = EXCLUDED."auth_token",
    "project_ref" = EXCLUDED."project_ref",
    "updated_at" = now();
END;
$$;

-- Function to schedule the events sync cron job
-- Uses auth token from config table
CREATE OR REPLACE FUNCTION schedule_events_sync_cron(
  schedule_cron text DEFAULT '0 2 * * *'
)
RETURNS TABLE(
  jobid bigint,
  jobname text,
  schedule text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  config_record record;
  job_id bigint;
  sql_command text;
BEGIN
  -- Get config
  SELECT "auth_token", "project_ref" INTO config_record
  FROM "public"."events_sync_config"
  WHERE "id" = 'default';

  IF config_record IS NULL OR config_record."auth_token" IS NULL OR config_record."auth_token" = '' THEN
    RAISE EXCEPTION 'Auth token not configured. Call set_events_sync_auth_token() first.';
  END IF;

  -- Check if cron job already exists
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE cron.job.jobname = 'events-sync'
  ) THEN
    RAISE EXCEPTION 'Cron job "events-sync" already exists. Use cron.unschedule() to remove it first.';
  END IF;

  -- Build the SQL command with the auth token from config
  sql_command := format('
    SELECT net.http_post(
      url := ''https://%s.supabase.co/api/v1/events/sync'',
      headers := jsonb_build_object(
        ''Authorization'', ''Bearer %s'',
        ''Content-Type'', ''application/json''
      ),
      body := ''{}''::jsonb
    ) AS request_id;
  ', config_record."project_ref", config_record."auth_token");

  -- Schedule the cron job
  SELECT cron.schedule(
    'events-sync',
    schedule_cron,
    sql_command
  ) INTO job_id;

  RETURN QUERY
  SELECT 
    job_id,
    'events-sync'::text,
    schedule_cron::text;
END;
$$;

-- ============================================================================
-- PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION check_events_sync_cron() TO authenticated;
GRANT EXECUTE ON FUNCTION check_events_sync_cron() TO service_role;
GRANT EXECUTE ON FUNCTION set_events_sync_auth_token(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_events_sync_auth_token(text, text) TO service_role;
GRANT EXECUTE ON FUNCTION schedule_events_sync_cron(text) TO authenticated;
GRANT EXECUTE ON FUNCTION schedule_events_sync_cron(text) TO service_role;
