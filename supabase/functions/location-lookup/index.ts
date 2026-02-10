import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Location lookup Edge Function
 * Called by database trigger when contact postcode or street_address changes
 * 
 * Request body:
 * {
 *   contact_id: number,
 *   postcode: string,
 *   street_address?: string | null,
 *   city?: string | null
 * }
 */
serve(async (req) => {
  try {
    // Get environment variables
    // Note: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are usually auto-provided
    // RIDING_LOOKUP_USERNAME and RIDING_LOOKUP_PASSWORD must be set as secrets
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const ridingLookupUsername = Deno.env.get("RIDING_LOOKUP_USERNAME");
    const ridingLookupPassword = Deno.env.get("RIDING_LOOKUP_PASSWORD");

    // Debug: Log all available env vars (without sensitive values)
    console.log("Environment variables check:", {
      hasSupabaseUrl: !!supabaseUrl,
      hasSupabaseServiceKey: !!supabaseServiceKey,
      hasRidingLookupUsername: !!ridingLookupUsername,
      hasRidingLookupPassword: !!ridingLookupPassword,
      supabaseUrlLength: supabaseUrl?.length || 0,
      supabaseServiceKeyLength: supabaseServiceKey?.length || 0,
      ridingLookupUsernameLength: ridingLookupUsername?.length || 0,
      ridingLookupPasswordLength: ridingLookupPassword?.length || 0,
    });

    // For internal calls from database triggers, we may not have auth
    // But we still need Supabase URL and service key to update the database
    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("Missing Supabase environment variables:", {
        hasSupabaseUrl: !!supabaseUrl,
        hasSupabaseServiceKey: !!supabaseServiceKey,
        supabaseUrlValue: supabaseUrl ? "SET" : "NOT SET",
        supabaseServiceKeyValue: supabaseServiceKey ? "SET" : "NOT SET",
      });
      return new Response(
        JSON.stringify({
          error: "Missing required environment variables",
          missing: [
            !supabaseUrl && "SUPABASE_URL",
            !supabaseServiceKey && "SUPABASE_SERVICE_ROLE_KEY",
          ].filter(Boolean),
          details: {
            hasSupabaseUrl: !!supabaseUrl,
            hasSupabaseServiceKey: !!supabaseServiceKey,
          },
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Optional: Validate auth if provided (for external calls)
    // For internal database trigger calls, auth may not be present
    const authHeader = req.headers.get("Authorization");
    if (authHeader) {
      const token = authHeader.replace("Bearer ", "");
      // In production, you might want to validate the token here
      // For now, we allow internal calls without strict validation
    }

    if (!ridingLookupUsername || !ridingLookupPassword) {
      console.error("Missing riding lookup credentials:", {
        hasUsername: !!ridingLookupUsername,
        hasPassword: !!ridingLookupPassword,
      });
      return new Response(
        JSON.stringify({
          error: "Missing required environment variables",
          missing: [
            !ridingLookupUsername && "RIDING_LOOKUP_USERNAME",
            !ridingLookupPassword && "RIDING_LOOKUP_PASSWORD",
          ].filter(Boolean),
          details: {
            hasUsername: !!ridingLookupUsername,
            hasPassword: !!ridingLookupPassword,
          },
          message: "Location lookup credentials not configured. Set RIDING_LOOKUP_USERNAME and RIDING_LOOKUP_PASSWORD secrets and redeploy the function.",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Parse request body
    const body = await req.json().catch(() => ({}));
    const { contact_id, postcode, street_address, city } = body;

    if (!contact_id || !postcode) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: contact_id, postcode",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Call the riding lookup API
    // The API expects query parameters: postal_code (not postcode) and/or address
    let lookupUrl = "https://riding-lookup.chester-hill-solutions.workers.dev/api/on";
    
    // Build query parameters
    const queryParams: string[] = [];
    
    // Add postal code if provided (API expects postal_code, not postcode)
    if (postcode && String(postcode).trim() !== "") {
      const trimmedPostcode = encodeURIComponent(String(postcode).trim());
      queryParams.push(`postal_code=${trimmedPostcode}`);
    }

    // Add address if provided
    if (street_address && String(street_address).trim() !== "") {
      const trimmedAddress = encodeURIComponent(String(street_address).trim());
      queryParams.push(`address=${trimmedAddress}`);
    }

    // Add city if provided (improves lookup accuracy)
    if (city && String(city).trim() !== "") {
      const trimmedCity = encodeURIComponent(String(city).trim());
      queryParams.push(`city=${trimmedCity}`);
    }

    // Ensure we have at least one location parameter
    if (queryParams.length === 0) {
      return new Response(
        JSON.stringify({
          error: "No location parameters provided",
          contact_id,
          message: "Both postcode and street_address are empty",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Append query parameters to URL
    lookupUrl += "?" + queryParams.join("&");

    // Create lookup body object for logging/debugging
    const lookupBody = {
      url: lookupUrl,
      queryParams: queryParams,
    };

    console.log(`Calling riding lookup API for contact ${contact_id}:`, lookupBody);

    let lookupResult: {
      point?: {
        lat: number;
        lon: number;
      };
      properties?: {
        ENGLISH_NA?: string;
        FRENCH_NAM?: string;
      };
      query?: Record<string, string>;
      error?: string;
    };

    try {
      const response = await fetch(lookupUrl, {
        method: "POST",
        headers: {
          Authorization: `Basic ${btoa(`${ridingLookupUsername}:${ridingLookupPassword}`)}`,
        },
        // No body - parameters are in the URL query string
      });

      if (!response.ok) {
        const errorText = await response.text();
        let errorDetails: unknown = errorText;
        
        // Try to parse as JSON
        try {
          errorDetails = JSON.parse(errorText);
        } catch {
          // Keep as text if not JSON
        }

        console.error(`Location lookup API error for contact ${contact_id}:`, {
          status: response.status,
          statusText: response.statusText,
          error: errorDetails,
          requestBody: lookupBody,
          responseHeaders: Object.fromEntries(response.headers.entries()),
        });
        
        // Log the full error for debugging
        console.error(`Full API error response:`, errorText);
        
        return new Response(
          JSON.stringify({
            message: `Location lookup API returned ${response.status}: ${response.statusText}`,
            contact_id,
            error: errorDetails,
            requestBody: lookupBody,
            apiResponse: errorText,
          }),
          {
            status: 200, // Return 200 to avoid retries - this is best effort
            headers: { "Content-Type": "application/json" },
          },
        );
      }

      lookupResult = await response.json();
      console.log(`Location lookup API success for contact ${contact_id}:`, lookupResult);
      
      // Extract data from the API response format
      // Response format: { point: { lat, lon }, properties: { ENGLISH_NA, ... } }
      if (lookupResult.point) {
        lookupResult.latitude = lookupResult.point.lat;
        lookupResult.longitude = lookupResult.point.lon;
      }
      if (lookupResult.properties?.ENGLISH_NA) {
        lookupResult.riding = lookupResult.properties.ENGLISH_NA;
      }
    } catch (error) {
      console.error(`Location lookup request failed for contact ${contact_id}:`, error);
      return new Response(
        JSON.stringify({
          message: "Location lookup request failed",
          contact_id,
          error: error instanceof Error ? error.message : "Unknown error",
        }),
        {
          status: 200, // Return 200 to avoid retries - this is best effort
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Validate response has at least some useful data
    // The API returns: { point: { lat, lon }, properties: { ENGLISH_NA } }
    const latitude = lookupResult.point?.lat;
    const longitude = lookupResult.point?.lon;
    const riding = lookupResult.properties?.ENGLISH_NA;
    
    if (!latitude && !longitude && !riding) {
      console.warn(`Location lookup returned empty response for contact ${contact_id}:`, lookupResult);
      return new Response(
        JSON.stringify({
          message: "Location lookup returned empty response",
          contact_id,
          apiResponse: lookupResult,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    // Prepare update data
    const updateData: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };

    if (lookupResult.latitude !== undefined && lookupResult.latitude !== null) {
      updateData.latitude = lookupResult.latitude;
    }
    if (lookupResult.longitude !== undefined && lookupResult.longitude !== null) {
      updateData.longitude = lookupResult.longitude;
    }
    if (lookupResult.riding !== undefined && lookupResult.riding !== null && lookupResult.riding.trim() !== "") {
      updateData.division_electoral_district = lookupResult.riding.trim();
    }

    // Update the contact
    const { error: updateError } = await supabase
      .from("contact")
      .update(updateData)
      .eq("id", contact_id);

    if (updateError) {
      console.error(`Failed to update contact ${contact_id} with location data:`, updateError);
      return new Response(
        JSON.stringify({
          error: "Failed to update contact with location data",
          contact_id,
          details: updateError.message,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        message: "Location lookup completed successfully",
        contact_id,
        updated: {
          latitude: lookupResult.point?.lat,
          longitude: lookupResult.point?.lon,
          riding: lookupResult.properties?.ENGLISH_NA,
        },
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Unexpected error in location lookup function:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});
