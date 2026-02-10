-- Setup cron job for survey-send-worker edge function
-- This serves as a backup to ensure jobs are processed even if automatic triggering fails
--
-- Prerequisites:
-- 1. pg_cron extension must be enabled (usually enabled by default in Supabase)
-- 2. net extension must be enabled for HTTP requests
-- 3. Anon key must be set (get from Supabase Dashboard > Settings > API > anon/public key)

-- Enable required extensions if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS net;

-- Project configuration
DO $$
DECLARE
  project_ref text := 'gjbzjjwtwcgfbjjmuery';
  anon_key text;
BEGIN
  -- Get anon key from environment or prompt user to set it
  -- For security, the anon key should be retrieved from Supabase settings
  -- You can find it in: Supabase Dashboard > Settings > API > anon/public key
  
  -- Check if cron job already exists
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'survey-send-worker'
  ) THEN
    RAISE NOTICE 'Cron job "survey-send-worker" already exists. Skipping creation.';
    RETURN;
  END IF;
  
  -- Note: The cron job requires the anon key to be set manually
  -- Run the following SQL in your Supabase SQL editor after getting your anon key:
  --
  -- SELECT cron.schedule(
  --   'survey-send-worker',
  --   '*/2 * * * *', -- Every 2 minutes
  --   $$
  --   SELECT net.http_post(
  --     url := 'https://gjbzjjwtwcgfbjjmuery.supabase.co/functions/v1/survey-send-worker',
  --     headers := '{"Authorization": "Bearer YOUR_ANON_KEY_HERE", "Content-Type": "application/json"}'::jsonb
  --   ) AS request_id;
  --   $$
  -- );
  
  RAISE NOTICE 'Extensions enabled. To create the cron job, run the SQL command shown above with your anon key.';
END $$;

-- Helper function to check cron job status
CREATE OR REPLACE FUNCTION check_survey_send_worker_cron()
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
  WHERE jobname = 'survey-send-worker';
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_survey_send_worker_cron() TO authenticated;
GRANT EXECUTE ON FUNCTION check_survey_send_worker_cron() TO service_role;

-- Instructions:
-- 1. Get your anon key from: Supabase Dashboard > Settings > API > anon/public key
-- 2. Run this SQL to create the cron job (replace YOUR_ANON_KEY_HERE):
--
-- SELECT cron.schedule(
--   'survey-send-worker',
--   '*/2 * * * *', -- Every 2 minutes
--   $$
--   SELECT net.http_post(
--     url := 'https://gjbzjjwtwcgfbjjmuery.supabase.co/functions/v1/survey-send-worker',
--     headers := '{"Authorization": "Bearer YOUR_ANON_KEY_HERE", "Content-Type": "application/json"}'::jsonb
--   ) AS request_id;
--   $$
-- );
--
-- 3. Verify the cron job is scheduled:
--    SELECT * FROM check_survey_send_worker_cron();
--
-- 4. To unschedule the cron job:
--    SELECT cron.unschedule('survey-send-worker');

