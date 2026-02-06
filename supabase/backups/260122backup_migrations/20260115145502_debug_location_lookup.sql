-- Debug migration to help troubleshoot location lookup
-- This adds logging and checks if the trigger is working

-- Check if trigger exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_location_lookup_on_address_change'
  ) THEN
    RAISE NOTICE 'WARNING: trigger_location_lookup_on_address_change trigger does not exist!';
  ELSE
    RAISE NOTICE 'SUCCESS: trigger_location_lookup_on_address_change trigger exists';
  END IF;
END $$;

-- Check if function exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'trigger_location_lookup'
  ) THEN
    RAISE NOTICE 'WARNING: trigger_location_lookup function does not exist!';
  ELSE
    RAISE NOTICE 'SUCCESS: trigger_location_lookup function exists';
  END IF;
END $$;

-- Check if pg_net extension is enabled
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
  ) THEN
    RAISE NOTICE 'WARNING: pg_net extension is not enabled!';
  ELSE
    RAISE NOTICE 'SUCCESS: pg_net extension is enabled';
  END IF;
END $$;

-- Test the get_supabase_url function
DO $$
DECLARE
  test_url text;
BEGIN
  SELECT get_supabase_url() INTO test_url;
  RAISE NOTICE 'Supabase URL: %', test_url;
END $$;

-- Note: The trigger function already has RAISE NOTICE/WARNING statements
-- for debugging. Check database logs to see trigger execution.

-- Test the trigger function directly to see if it works
-- This will help identify if the issue is with the trigger or the Edge Function call
DO $$
DECLARE
  test_contact_id bigint;
  test_result record;
BEGIN
  -- Get a test contact with a postcode
  SELECT id INTO test_contact_id 
  FROM contact 
  WHERE postcode IS NOT NULL AND trim(postcode) != '' 
  LIMIT 1;
  
  IF test_contact_id IS NULL THEN
    RAISE NOTICE 'No contact found with postcode to test';
  ELSE
    RAISE NOTICE 'Found test contact with id: %', test_contact_id;
    
    -- Test the get_supabase_url function
    DECLARE
      test_url text;
    BEGIN
      SELECT get_supabase_url() INTO test_url;
      RAISE NOTICE 'Edge Function URL would be: %/functions/v1/location-lookup', test_url;
    END;
  END IF;
END $$;

-- Check if we can make HTTP requests via pg_net
DO $$
DECLARE
  request_id bigint;
BEGIN
  -- Try a simple test request
  SELECT net.http_post(
    url := 'https://httpbin.org/post',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('test', 'true')
  ) INTO request_id;
  
  IF request_id IS NOT NULL THEN
    RAISE NOTICE 'SUCCESS: pg_net can make HTTP requests. Test request_id: %', request_id;
  ELSE
    RAISE WARNING 'FAILED: pg_net returned NULL request_id - HTTP requests may not work';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'ERROR testing pg_net: %', SQLERRM;
END $$;
