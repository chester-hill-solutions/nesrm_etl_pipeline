# Location Lookup Edge Function - Setup Guide

## Required Environment Variables

The Edge Function needs these environment variables to be set in Supabase:

### 1. Supabase Environment Variables (Auto-set)
These are automatically available in Edge Functions:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access

### 2. Riding Lookup API Credentials (Must be set manually)
- `RIDING_LOOKUP_USERNAME` - Username for the riding lookup API
- `RIDING_LOOKUP_PASSWORD` - Password for the riding lookup API

## Setting Environment Variables

### Using Supabase CLI (Recommended)

```bash
# Set the riding lookup credentials
supabase secrets set RIDING_LOOKUP_USERNAME=your_username
supabase secrets set RIDING_LOOKUP_PASSWORD=your_password
```

### Using Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Project Settings** → **Edge Functions**
3. Scroll to **Secrets** section
4. Add the following secrets:
   - `RIDING_LOOKUP_USERNAME` = your username
   - `RIDING_LOOKUP_PASSWORD` = your password

### For Local Development

Create a `.env` file in your project root (or use Supabase CLI):

```bash
# In your .env file or via CLI
supabase secrets set RIDING_LOOKUP_USERNAME=your_username --env-file .env.local
supabase secrets set RIDING_LOOKUP_PASSWORD=your_password --env-file .env.local
```

## Verifying Setup

After setting the secrets, redeploy the Edge Function:

```bash
supabase functions deploy location-lookup
```

Then test it:

```bash
# Test the Edge Function directly
curl -X POST http://localhost:54321/functions/v1/location-lookup \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -d '{
    "contact_id": 1,
    "postcode": "M5H 2N2",
    "street_address": "123 Main St"
  }'
```

## Troubleshooting

### Error: "Missing required environment variables"

This means one of the required variables is not set. Check:

1. **SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY**: These should be auto-set, but if missing, check your Supabase project settings
2. **RIDING_LOOKUP_USERNAME and RIDING_LOOKUP_PASSWORD**: These must be set manually via secrets

### Check Current Secrets

```bash
# List all secrets (values are hidden for security)
supabase secrets list
```

### View Edge Function Logs

In Supabase Dashboard:
1. Go to **Edge Functions** → **location-lookup**
2. Click on **Logs** tab
3. Check for error messages

Or via CLI:
```bash
supabase functions logs location-lookup
```
