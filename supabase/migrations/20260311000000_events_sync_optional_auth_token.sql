-- Event sync: allow running without storing an auth key.
-- Deploy the edge function with verify_jwt = false so the cron can call it without a Bearer token.
-- Then only project_ref is required for the cron URL; auth_token is optional.

ALTER TABLE "public"."events_sync_config"
  ALTER COLUMN "auth_token" DROP NOT NULL;

CREATE OR REPLACE FUNCTION "public"."set_events_sync_auth_token"(
  "auth_token" "text" DEFAULT NULL,
  "project_ref" "text" DEFAULT 'gjbzjjwtwcgfbjjmuery'::"text"
) RETURNS "void"
  LANGUAGE "plpgsql" SECURITY DEFINER
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

CREATE OR REPLACE FUNCTION "public"."schedule_events_sync_cron"("schedule_cron" "text" DEFAULT '0 2 * * *'::"text") RETURNS TABLE("jobid" bigint, "jobname" "text", "schedule" "text")
  LANGUAGE "plpgsql" SECURITY DEFINER
  AS $$
DECLARE
  config_record record;
  job_id bigint;
  sql_command text;
BEGIN
  SELECT "auth_token", "project_ref" INTO config_record
  FROM "public"."events_sync_config"
  WHERE "id" = 'default';

  IF config_record IS NULL OR config_record."project_ref" IS NULL OR config_record."project_ref" = '' THEN
    RAISE EXCEPTION 'Project ref not configured. Call set_events_sync_auth_token(NULL, project_ref) first.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM cron.job WHERE cron.job.jobname = 'events-sync'
  ) THEN
    RAISE EXCEPTION 'Cron job "events-sync" already exists. Use cron.unschedule(''events-sync'') to remove it first.';
  END IF;

  IF config_record."auth_token" IS NOT NULL AND config_record."auth_token" <> '' THEN
    sql_command := format('
      SELECT net.http_post(
        url := ''https://%s.supabase.co/functions/v1/events-sync'',
        headers := jsonb_build_object(
          ''Authorization'', ''Bearer %s'',
          ''Content-Type'', ''application/json''
        ),
        body := ''{}''::jsonb
      ) AS request_id;
    ', config_record."project_ref", config_record."auth_token");
  ELSE
    sql_command := format('
      SELECT net.http_post(
        url := ''https://%s.supabase.co/functions/v1/events-sync'',
        headers := jsonb_build_object(''Content-Type'', ''application/json''),
        body := ''{}''::jsonb
      ) AS request_id;
    ', config_record."project_ref");
  END IF;

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
