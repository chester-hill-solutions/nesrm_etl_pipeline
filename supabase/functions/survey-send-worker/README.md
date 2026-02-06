# Survey Send Worker

Supabase Edge Function that processes survey send jobs from the PGMQ queue.

## Overview

This worker:
1. Polls the `survey_send` PGMQ queue for jobs
2. Processes each job by sending survey invitation emails via Resend
3. Updates survey instance status and campaign progress
4. Archives successful jobs and handles failures

## Environment Variables

Required environment variables (set via Supabase Dashboard or CLI):

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access
- `RESEND_API_KEY` - Resend API key for sending emails

Optional environment variables:

- `POLL_INTERVAL_SECONDS` - How often to poll the queue (default: 10)
- `BATCH_SIZE` - Number of jobs to process per run (default: 10)
- `MAX_RETRIES` - Maximum retry attempts for failed jobs (default: 3)

## Local Development

1. Install Supabase CLI if not already installed
2. Start Supabase locally: `supabase start`
3. Set environment variables in `.env` or via `supabase secrets set`
4. Serve the function locally: `supabase functions serve survey-send-worker`
5. Test by triggering the function: `curl http://localhost:54321/functions/v1/survey-send-worker`

## Deployment

Deploy to Supabase:

```bash
supabase functions deploy survey-send-worker
```

Set secrets:

```bash
supabase secrets set SUPABASE_URL=your-url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-key
supabase secrets set RESEND_API_KEY=your-key
```

## Triggering the Worker

The worker is automatically triggered when campaigns are enqueued (immediate processing), but a cron job is recommended as a backup for reliability.

### Automatic Triggering (Already Implemented)

When a campaign is sent via `enqueueCampaignSend()`, the worker is automatically triggered immediately. This provides:
- ✅ Immediate processing (no delay)
- ✅ Better user experience
- ⚠️ If the edge function is unavailable, jobs will wait until cron runs

### Recommended: Supabase Cron (Backup)

Set up a cron job in Supabase as a backup to ensure jobs are processed even if automatic triggering fails:

```sql
-- Create a cron job that runs every 2 minutes
SELECT cron.schedule(
  'survey-send-worker',
  '*/2 * * * *', -- Every 2 minutes
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/survey-send-worker',
    headers := '{"Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
  ) AS request_id;
  $$
);
```

## Monitoring

- Check function logs in Supabase Dashboard: Edge Functions > survey-send-worker > Logs
- Monitor queue depth: Query `pgmq` tables directly
- Check campaign progress: Query `campaigns` table for `sent_count` vs `total_recipients`

## Error Handling

- Failed jobs are deleted from the queue (after max retries)
- Failed contact IDs are tracked in `campaigns.failed_contact_ids`
- Survey instances are marked as "failed" if email send fails
- Campaign status updates to "sent" when all jobs complete

## Performance Considerations

- Batch size: Start with 10 jobs per batch, adjust based on performance
- Poll interval: 1-5 minutes recommended
- Visibility timeout: 300 seconds (5 minutes) should be enough for email send
- Rate limiting: Consider Resend API rate limits when adjusting batch size

