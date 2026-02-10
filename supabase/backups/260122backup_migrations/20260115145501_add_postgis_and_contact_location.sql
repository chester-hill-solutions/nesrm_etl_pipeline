-- Enable PostGIS extension for spatial geometry support
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add latitude and longitude columns to contact table
ALTER TABLE "public"."contact"
  ADD COLUMN IF NOT EXISTS "latitude" double precision,
  ADD COLUMN IF NOT EXISTS "longitude" double precision;

-- Add geometry point column for spatial queries
-- This will store the location as a PostGIS geometry point
ALTER TABLE "public"."contact"
  ADD COLUMN IF NOT EXISTS "location" geometry(POINT, 4326);

-- Create a function to update the location geometry from lat/long
CREATE OR REPLACE FUNCTION update_contact_location()
RETURNS TRIGGER AS $$
BEGIN
  -- Update location geometry if both latitude and longitude are provided
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update location geometry when lat/long changes
CREATE TRIGGER update_contact_location_trigger
  BEFORE INSERT OR UPDATE OF latitude, longitude ON "public"."contact"
  FOR EACH ROW
  EXECUTE FUNCTION update_contact_location();

-- Create spatial index on location column for efficient spatial queries
CREATE INDEX IF NOT EXISTS idx_contact_location ON "public"."contact" USING GIST (location);

-- Function to get Supabase base URL for Edge Functions
-- Manually configured - update the URL below for your environment
CREATE OR REPLACE FUNCTION get_supabase_url()
RETURNS text AS $$
BEGIN
  -- Production URL - update if your project ref is different
  RETURN 'https://gjbzjjwtwcgfbjjmuery.supabase.co';
  
  -- For local development, uncomment the line below and comment out the production URL:
  -- RETURN 'http://localhost:54321';
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to call the location lookup Edge Function
-- This function makes the HTTP request to the Edge Function
CREATE OR REPLACE FUNCTION call_location_lookup_edge_function(
  p_contact_id bigint,
  p_postcode text,
  p_street_address text
)
RETURNS bigint AS $$
DECLARE
  edge_function_url text;
  supabase_url text;
  service_role_key text;
  request_id bigint;
BEGIN
  -- Get Supabase URL
  supabase_url := get_supabase_url();

  -- Construct Edge Function URL
  edge_function_url := supabase_url || '/functions/v1/location-lookup';

  -- Get service role key for authentication
  -- Manually set your service role key here (get from Supabase Dashboard → Project Settings → API)
  -- Leave as NULL if you want to call without auth (Edge Function should handle internal calls)
  service_role_key := NULL; -- TODO: Set your service role key here, or leave NULL for no auth
  
  -- Example (uncomment and set your actual key):
  -- service_role_key := 'your-service-role-key-here';

  -- Call Edge Function asynchronously via pg_net
  -- This is fire-and-forget - errors are logged but don't block the transaction
  IF service_role_key IS NOT NULL AND service_role_key != '' THEN
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'contact_id', p_contact_id,
        'postcode', p_postcode,
        'street_address', p_street_address
      )
    ) INTO request_id;
  ELSE
    -- Call without auth header (Edge Function should validate internally if needed)
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'contact_id', p_contact_id,
        'postcode', p_postcode,
        'street_address', p_street_address
      )
    ) INTO request_id;
  END IF;

  RETURN request_id;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Failed to call location lookup Edge Function for contact %: %', p_contact_id, SQLERRM;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to trigger location lookup
-- This function is called by the trigger and validates conditions before calling the Edge Function
CREATE OR REPLACE FUNCTION trigger_location_lookup()
RETURNS TRIGGER AS $$
DECLARE
  postcode_changed boolean;
  address_changed boolean;
  request_id bigint;
BEGIN
  -- Check if postcode or street_address changed
  IF TG_OP = 'UPDATE' THEN
    postcode_changed := (OLD.postcode IS DISTINCT FROM NEW.postcode);
    address_changed := (OLD.street_address IS DISTINCT FROM NEW.street_address);
    
    -- Only proceed if at least one of them changed
    IF NOT postcode_changed AND NOT address_changed THEN
      RETURN NEW;
    END IF;
  END IF;

  -- Skip if postcode is empty (required for lookup)
  IF NEW.postcode IS NULL OR trim(NEW.postcode) = '' THEN
    RETURN NEW;
  END IF;

  -- Call the Edge Function via the helper function
  SELECT call_location_lookup_edge_function(
    NEW.id,
    NEW.postcode,
    NEW.street_address
  ) INTO request_id;

  -- Log the result
  IF request_id IS NOT NULL THEN
    RAISE NOTICE 'Location lookup triggered for contact %: request_id %', NEW.id, request_id;
  ELSE
    RAISE WARNING 'Location lookup request failed for contact %: request_id is NULL', NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the transaction
  RAISE WARNING 'Location lookup trigger error for contact %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists (for idempotency)
DROP TRIGGER IF EXISTS trigger_location_lookup_on_address_change ON "public"."contact";

-- Create trigger to call location lookup when postcode or street_address changes
-- Note: The WHEN clause ensures we only fire when postcode is not empty
-- The function itself also checks for changes, so it won't fire unnecessarily
CREATE TRIGGER trigger_location_lookup_on_address_change
  AFTER INSERT OR UPDATE OF postcode, street_address ON "public"."contact"
  FOR EACH ROW
  WHEN (NEW.postcode IS NOT NULL AND trim(NEW.postcode) != '')
  EXECUTE FUNCTION trigger_location_lookup();

-- Add comments for documentation
COMMENT ON COLUMN "public"."contact"."latitude" IS 'Latitude coordinate in decimal degrees (WGS84)';
COMMENT ON COLUMN "public"."contact"."longitude" IS 'Longitude coordinate in decimal degrees (WGS84)';
COMMENT ON COLUMN "public"."contact"."location" IS 'PostGIS geometry point (SRID 4326) automatically generated from latitude/longitude';
COMMENT ON FUNCTION update_contact_location() IS 'Automatically updates the location geometry point from latitude and longitude columns';
COMMENT ON FUNCTION call_location_lookup_edge_function(bigint, text, text) IS 'Calls the location lookup Edge Function via HTTP request';
COMMENT ON FUNCTION trigger_location_lookup() IS 'Trigger function that validates conditions and calls the location lookup Edge Function when contact postcode or street_address changes';
