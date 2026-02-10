# Events Sync Edge Function

This Supabase Edge Function syncs events from the OLP (Ontario Liberal Party) website to the database.

## Overview

The function:
- Fetches events from `https://ontarioliberal.ca/events/`
- Parses HTML to extract event details
- Filters out AGM (Annual General Meeting) events
- Upserts events into the `events` table
- Archives stale events that haven't been seen in the last 24 hours

## Deployment

Deploy the function:

```bash
supabase functions deploy events-sync
```

## Environment Variables

The function requires the following environment variables (set automatically by Supabase):
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access

Set these via:
```bash
supabase secrets set SUPABASE_URL=<your-url>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-key>
```

Or via the Supabase Dashboard:
1. Go to Project Settings > Edge Functions
2. Add secrets

## Usage

### Manual Invocation

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/events-sync \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json"
```

### Cron Job

The function is designed to be called by a PostgreSQL cron job. See the `schedule_events_sync_cron()` function in the database schema.

## Response Format

```json
{
  "success": true,
  "added": 5,
  "updated": 10,
  "archived": 2,
  "errors": 0,
  "errorMessages": [],
  "syncedAt": "2026-01-27T12:00:00.000Z"
}
```

## Error Handling

- Network errors are logged and included in `errorMessages`
- Individual event sync failures don't stop the entire process
- The function returns `success: false` if any errors occurred, but still processes all events

## Dependencies

- `deno_dom` - HTML parsing (Deno-compatible alternative to linkedom)
- `@supabase/supabase-js` - Supabase client

## Local Development

Test locally:

```bash
supabase functions serve events-sync
```

Then call:
```bash
curl -X POST http://localhost:54321/functions/v1/events-sync \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json"
```
