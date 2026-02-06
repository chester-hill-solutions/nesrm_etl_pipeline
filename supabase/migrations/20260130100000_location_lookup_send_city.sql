-- Send contact municipality as city to location lookup Edge Function when available.
-- The Edge Function and riding lookup API use city to improve address lookup accuracy.

-- Replace call_location_lookup_edge_function to accept optional city (contact.municipality)
DROP FUNCTION IF EXISTS "public"."call_location_lookup_edge_function"(bigint, text, text);

CREATE OR REPLACE FUNCTION "public"."call_location_lookup_edge_function"(
  "p_contact_id" bigint,
  "p_postcode" text,
  "p_street_address" text,
  "p_city" text DEFAULT NULL
) RETURNS bigint
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $$
DECLARE
  edge_function_url text;
  supabase_url text;
  service_role_key text;
  request_id bigint;
  request_body jsonb;
BEGIN
  supabase_url := get_supabase_url();
  edge_function_url := supabase_url || '/functions/v1/location-lookup';

  -- Same service role key as original (from project settings)
  service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqYnpqand0d2NnZmJqam11ZXJ5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg0OTI1NiwiZXhwIjoyMDY0NDI1MjU2fQ.65ppa6roapEA_mvuec7876PMeyqdY0T6MkvoWvGsBvs';

  -- Build body including city when present
  request_body := jsonb_build_object(
    'contact_id', p_contact_id,
    'postcode', COALESCE(p_postcode, ''),
    'street_address', p_street_address
  );
  IF p_city IS NOT NULL AND trim(p_city) <> '' THEN
    request_body := request_body || jsonb_build_object('city', trim(p_city));
  END IF;

  IF service_role_key IS NOT NULL AND service_role_key != '' THEN
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := request_body
    ) INTO request_id;
  ELSE
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := request_body
    ) INTO request_id;
  END IF;

  RETURN request_id;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Failed to call location lookup Edge Function for contact %: %', p_contact_id, SQLERRM;
  RETURN NULL;
END;
$$;

ALTER FUNCTION "public"."call_location_lookup_edge_function"(bigint, text, text, text) OWNER TO "postgres";
COMMENT ON FUNCTION "public"."call_location_lookup_edge_function"(bigint, text, text, text) IS 'Calls the location lookup Edge Function with contact_id, postcode, street_address, and optional city (municipality).';

GRANT ALL ON FUNCTION "public"."call_location_lookup_edge_function"(bigint, text, text, text) TO "anon";
GRANT ALL ON FUNCTION "public"."call_location_lookup_edge_function"(bigint, text, text, text) TO "authenticated";
GRANT ALL ON FUNCTION "public"."call_location_lookup_edge_function"(bigint, text, text, text) TO "service_role";

-- Update trigger to pass municipality as city
CREATE OR REPLACE FUNCTION "public"."trigger_location_lookup"() RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $$
DECLARE
  postcode_changed boolean;
  address_changed boolean;
  request_id bigint;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    postcode_changed := (OLD.postcode IS DISTINCT FROM NEW.postcode);
    address_changed := (OLD.street_address IS DISTINCT FROM NEW.street_address);

    IF NOT postcode_changed AND NOT address_changed THEN
      RETURN NEW;
    END IF;
  END IF;

  IF NEW.postcode IS NULL OR trim(NEW.postcode) = '' THEN
    RETURN NEW;
  END IF;

  SELECT call_location_lookup_edge_function(
    NEW.id,
    NEW.postcode,
    NEW.street_address,
    NEW.municipality
  ) INTO request_id;

  IF request_id IS NOT NULL THEN
    RAISE NOTICE 'Location lookup triggered for contact %: request_id %', NEW.id, request_id;
  ELSE
    RAISE WARNING 'Location lookup request failed for contact %: request_id is NULL', NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Location lookup trigger error for contact %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."trigger_location_lookup"() OWNER TO "postgres";
COMMENT ON FUNCTION "public"."trigger_location_lookup"() IS 'Trigger function that validates conditions and calls the location lookup Edge Function when contact postcode or street_address changes; passes municipality as city when present.';
