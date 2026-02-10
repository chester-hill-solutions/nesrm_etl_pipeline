-- Configure database settings for location lookup Edge Function calls
-- Note: Database-level settings require superuser. We'll use a smarter detection method instead.

-- The get_supabase_url() function will automatically detect the environment
-- For production Supabase, we can detect it from the request context or use a different approach
-- For now, we'll update the function to be smarter about detection

-- Note: Database-level parameter settings require superuser privileges
-- Instead, we'll update the functions to work without requiring these settings
-- The Edge Function can be called without authentication for internal database triggers

-- Test the configuration
DO $$
DECLARE
  test_url text;
  test_key text;
BEGIN
  BEGIN
    test_url := current_setting('app.settings.supabase_url', true);
  EXCEPTION WHEN OTHERS THEN
    test_url := NULL;
  END;

  BEGIN
    test_key := current_setting('app.settings.service_role_key', true);
  EXCEPTION WHEN OTHERS THEN
    test_key := NULL;
  END;

  RAISE NOTICE 'Configuration check:';
  RAISE NOTICE '  Supabase URL: %', COALESCE(test_url, 'NOT SET');
  RAISE NOTICE '  Service Role Key: %', CASE WHEN test_key IS NOT NULL AND test_key != '' THEN 'SET' ELSE 'NOT SET' END;
END $$;
