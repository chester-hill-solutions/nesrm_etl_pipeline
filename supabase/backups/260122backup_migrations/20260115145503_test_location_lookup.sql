-- Test script to verify location lookup is working
-- Run this to check all components

-- 1. Verify all functions exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_supabase_url') THEN
    RAISE EXCEPTION 'Function get_supabase_url() does not exist!';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'call_location_lookup_edge_function') THEN
    RAISE EXCEPTION 'Function call_location_lookup_edge_function() does not exist!';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'trigger_location_lookup') THEN
    RAISE EXCEPTION 'Function trigger_location_lookup() does not exist!';
  END IF;
  
  RAISE NOTICE 'SUCCESS: All required functions exist';
END $$;

-- 2. Test get_supabase_url function
DO $$
DECLARE
  test_url text;
BEGIN
  SELECT get_supabase_url() INTO test_url;
  RAISE NOTICE 'Supabase URL: %', test_url;
  RAISE NOTICE 'Edge Function URL would be: %/functions/v1/location-lookup', test_url;
END $$;

-- 3. Test with a real contact (if one exists)
DO $$
DECLARE
  test_contact_id bigint;
  test_postcode text;
  test_address text;
  request_id bigint;
BEGIN
  -- Find a contact with a postcode
  SELECT id, postcode, street_address 
  INTO test_contact_id, test_postcode, test_address
  FROM contact 
  WHERE postcode IS NOT NULL AND trim(postcode) != '' 
  LIMIT 1;
  
  IF test_contact_id IS NULL THEN
    RAISE NOTICE 'No contact found with postcode to test';
  ELSE
    RAISE NOTICE 'Testing with contact ID: %, postcode: %, address: %', 
      test_contact_id, test_postcode, test_address;
    
    -- Test the Edge Function call
    SELECT call_location_lookup_edge_function(
      test_contact_id,
      test_postcode,
      test_address
    ) INTO request_id;
    
    IF request_id IS NOT NULL THEN
      RAISE NOTICE 'SUCCESS: Edge Function call returned request_id: %', request_id;
    ELSE
      RAISE WARNING 'FAILED: Edge Function call returned NULL request_id';
    END IF;
  END IF;
END $$;

-- 4. Check recent pg_net requests
DO $$
DECLARE
  request_count int;
BEGIN
  SELECT COUNT(*) INTO request_count
  FROM net.http_request 
  WHERE created > NOW() - INTERVAL '5 minutes';
  
  RAISE NOTICE 'HTTP requests in last 5 minutes: %', request_count;
  
  IF request_count > 0 THEN
    RAISE NOTICE 'Recent requests found - check net.http_request table for details';
  END IF;
END $$;

-- 5. Manual test: Update a contact to trigger the lookup
-- Uncomment and modify the contact ID to test:
/*
DO $$
DECLARE
  test_id bigint := 1; -- Change this to a real contact ID
BEGIN
  -- Update the contact to trigger the lookup
  UPDATE contact 
  SET postcode = COALESCE(postcode, 'M5H 2N2'),
      street_address = COALESCE(street_address, '123 Main St')
  WHERE id = test_id;
  
  RAISE NOTICE 'Updated contact % - check logs for trigger messages', test_id;
END $$;
*/
