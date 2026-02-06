# Webhook Send Worker

Supabase Edge Function that processes webhook send jobs from the PGMQ queue.

## Overview

This worker:
1. Polls the `webhook_send` PGMQ queue for jobs
2. Processes each job by sending webhook notifications via HTTP POST
3. Archives successful jobs and handles failures with retry logic

## Environment Variables

Required environment variables (set via Supabase Dashboard or CLI):

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access
- `PENDING_APPLICATION_WEBHOOK_URL` - Webhook URL to send notifications to (optional - if not set, worker will skip processing)
  - Production endpoint: `https://primary-production-a6b4.up.railway.app/webhook/nesdata-signup`

Optional environment variables:

- `POLL_INTERVAL_SECONDS` - How often to poll the queue (default: 10)
- `BATCH_SIZE` - Number of jobs to process per run (default: 10)
- `MAX_RETRIES` - Maximum retry attempts for failed jobs (default: 3)

## Local Development

1. Install Supabase CLI if not already installed
2. Start Supabase locally: `supabase start`
3. Set environment variables in `.env` or via `supabase secrets set`
4. Serve the function locally: `supabase functions serve webhook-send-worker`
5. Test by triggering the function: `curl http://localhost:54321/functions/v1/webhook-send-worker`

## Deployment

### Step 1: Deploy the Function

From the project root directory, run:

```bash
npx supabase functions deploy webhook-send-worker
```

Or if you have Supabase CLI installed globally:

```bash
supabase functions deploy webhook-send-worker
```

**Note:** Make sure you're in the project root directory (`/Users/ladmin/WebProjects/nes-dashboard`) when running this command.

### Step 2: Set Environment Variables (Secrets)

Set the required secrets using the Supabase CLI:

```bash
npx supabase secrets set SUPABASE_URL=your-project-url
npx supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
npx supabase secrets set PENDING_APPLICATION_WEBHOOK_URL=https://primary-production-a6b4.up.railway.app/webhook/nesdata-signup
```

**Alternative:** You can also set secrets via the Supabase Dashboard:
1. Go to Project Settings > Edge Functions > Secrets
2. Add each secret key-value pair

### Troubleshooting

If you get an error like "entrypoint path does not exist":
- Make sure you're running the command from the project root
- Verify the function name is exactly `webhook-send-worker` (not `worker-send-worker`)
- Check that `supabase/functions/webhook-send-worker/index.ts` exists

**Note:** The `SITE_URL` is `https://data.teamnate.ca` (used in the main application, not required by this worker).

## Triggering the Worker

The worker is automatically triggered when webhook jobs are enqueued (immediate processing), but a cron job is recommended as a backup for reliability.

### Automatic Triggering (Already Implemented)

When a webhook job is enqueued via `enqueueToWebhookQueue()`, the worker is automatically triggered immediately. This provides:
- ✅ Immediate processing (no delay)
- ✅ Better reliability
- ⚠️ If the edge function is unavailable, jobs will wait until cron runs

### Recommended: Supabase Cron (Backup)

Set up a cron job in Supabase as a backup to ensure jobs are processed even if automatic triggering fails:

```sql
-- Create a cron job that runs every 2 minutes
SELECT cron.schedule(
  'webhook-send-worker',
  '*/2 * * * *', -- Every 2 minutes
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/webhook-send-worker',
    headers := '{"Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
  ) AS request_id;
  $$
);
```

## Monitoring

- Check function logs in Supabase Dashboard: Edge Functions > webhook-send-worker > Logs
- Monitor queue depth: Query `pgmq` tables directly
- Check webhook delivery: Monitor webhook endpoint logs

## Error Handling

- Failed jobs are retried (via PGMQ visibility timeout) if they return 5xx errors or network errors
- Jobs with 4xx errors (client errors) are deleted (not retried)
- Jobs that exceed MAX_RETRIES are deleted from the queue
- Retryable jobs become visible again after the visibility timeout (5 minutes) expires

## Performance Considerations

- Batch size: Start with 10 jobs per batch, adjust based on performance
- Poll interval: 1-5 minutes recommended
- Visibility timeout: 300 seconds (5 minutes) should be enough for webhook requests
- Rate limiting: Consider webhook endpoint rate limits when adjusting batch size

