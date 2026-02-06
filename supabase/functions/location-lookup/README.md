# Location Lookup Edge Function

This Edge Function is automatically triggered by a database trigger when a contact's `postcode` or `street_address` is updated. It calls the riding lookup API to get location data (latitude, longitude, riding, inferred location) and updates the contact record.

## Setup

### 1. Environment Variables

Set the following environment variables in your Supabase project:

```bash
# Required
RIDING_LOOKUP_USERNAME=your_username
RIDING_LOOKUP_PASSWORD=your_password

# These are automatically available in Edge Functions
# SUPABASE_URL
# SUPABASE_SERVICE_ROLE_KEY
```

To set secrets in Supabase:

```bash
# Using Supabase CLI
supabase secrets set RIDING_LOOKUP_USERNAME=your_username
supabase secrets set RIDING_LOOKUP_PASSWORD=your_password
```

Or via the Supabase Dashboard:
1. Go to Project Settings > Edge Functions
2. Add secrets for `RIDING_LOOKUP_USERNAME` and `RIDING_LOOKUP_PASSWORD`

### 2. Database Configuration

For production, you need to set the Supabase URL in the database so the trigger can call the Edge Function:

```sql
-- Set the Supabase project URL (replace with your actual project URL)
ALTER DATABASE postgres SET app.settings.supabase_url = 'https://<your-project-ref>.supabase.co';

-- Optional: Set service role key for authentication (recommended for production)
ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';
```

For local development, the trigger will default to `http://localhost:54321`.

### 3. Deploy the Edge Function

```bash
supabase functions deploy location-lookup
```

## How It Works

1. **Database Trigger**: When a contact's `postcode` or `street_address` is updated, the `trigger_location_lookup()` function is called
2. **HTTP Request**: The trigger function makes an async HTTP POST request to the Edge Function via `pg_net`
3. **API Call**: The Edge Function calls the riding lookup API with the postal code and address
4. **Update Contact**: The Edge Function updates the contact with:
   - `latitude` and `longitude` (coordinates)
   - `division_electoral_district` (riding)
   - `inferred_location` (location string from API)

## Request/Response

### Request (from database trigger)
```json
{
  "contact_id": 123,
  "postcode": "M5H 2N2",
  "street_address": "123 Main St"
}
```

### Response
```json
{
  "message": "Location lookup completed successfully",
  "contact_id": 123,
  "updated": {
    "latitude": 43.6532,
    "longitude": -79.3832,
    "riding": "Toronto Centre",
    "inferred_location": "Toronto, ON"
  }
}
```

## Error Handling

- If the riding lookup API fails, the error is logged but the contact update still succeeds
- If the Edge Function fails, it returns a 200 status (to avoid retries) and logs the error
- Database trigger errors are logged as warnings but don't fail the transaction

## Testing

You can test the Edge Function directly:

```bash
# Using curl
curl -X POST https://<your-project-ref>.supabase.co/functions/v1/location-lookup \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <service-role-key>" \
  -d '{
    "contact_id": 123,
    "postcode": "M5H 2N2",
    "street_address": "123 Main St"
  }'
```

Or trigger it by updating a contact's postal code:

```sql
UPDATE contact 
SET postcode = 'M5H 2N2', street_address = '123 Main St' 
WHERE id = 123;
```
