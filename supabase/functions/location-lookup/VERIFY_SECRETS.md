# Verifying Edge Function Secrets

The Edge Function is receiving requests but returning "Missing required environment variables". 

## Required Secrets

The Edge Function needs these 4 environment variables:

1. `SUPABASE_URL` - Usually auto-set, but verify
2. `SUPABASE_SERVICE_ROLE_KEY` - Usually auto-set, but verify  
3. `RIDING_LOOKUP_USERNAME` - **Must be set manually**
4. `RIDING_LOOKUP_PASSWORD` - **Must be set manually**

## Check Current Secrets

### Using Supabase CLI:

```bash
# List all secrets (values are hidden for security)
supabase secrets list

# Check if specific secrets exist
supabase secrets list | grep RIDING_LOOKUP
```

### Using Supabase Dashboard:

1. Go to **Project Settings** → **Edge Functions**
2. Scroll to **Secrets** section
3. Verify you see:
   - `RIDING_LOOKUP_USERNAME`
   - `RIDING_LOOKUP_PASSWORD`

## Set Missing Secrets

### Using Supabase CLI (Recommended):

```bash
# Set the riding lookup credentials
supabase secrets set RIDING_LOOKUP_USERNAME=your_username
supabase secrets set RIDING_LOOKUP_PASSWORD=your_password

# After setting, redeploy the function
supabase functions deploy location-lookup
```

### Using Supabase Dashboard:

1. Go to **Project Settings** → **Edge Functions**
2. Scroll to **Secrets** section
3. Click **Add Secret** or edit existing
4. Add:
   - Name: `RIDING_LOOKUP_USERNAME`, Value: your username
   - Name: `RIDING_LOOKUP_PASSWORD`, Value: your password
5. **Important**: After adding secrets, redeploy the function

## Redeploy After Setting Secrets

**Critical**: After setting or updating secrets, you MUST redeploy the Edge Function:

```bash
supabase functions deploy location-lookup
```

Or via Dashboard:
1. Go to **Edge Functions** → **location-lookup**
2. Click **Redeploy** or make a small change and redeploy

## Verify Secrets Are Working

After redeploying, test the function:

```bash
curl -X POST https://gjbzjjwtwcgfbjjmuery.supabase.co/functions/v1/location-lookup \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -d '{
    "contact_id": 1,
    "postcode": "M5H 2N2",
    "street_address": "123 Main St"
  }'
```

If secrets are set correctly, you should get a 200 response instead of 500.

## Debugging

The Edge Function now has better error messages. Check the Edge Function logs to see which specific variable is missing:

### Using Supabase Dashboard (Recommended):
1. Go to **Edge Functions** → **location-lookup**
2. Click on the **Logs** tab
3. Look for error messages showing which variables are missing

### Check the HTTP Response:
The error response now includes a `missing` array showing which variables are not set. Check the `content` field in the `net.http_request` table:

```sql
SELECT 
  id,
  created,
  status_code,
  content::json->>'missing' as missing_vars,
  content::json->>'details' as details
FROM net.http_request 
WHERE url LIKE '%location-lookup%'
ORDER BY created DESC 
LIMIT 5;
```

This will show you exactly which environment variables are missing.
