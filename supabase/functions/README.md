# Supabase Edge Functions

This directory contains Supabase Edge Functions.

## Structure

Each edge function should be in its own subdirectory:

```
functions/
├── my-function/
│   └── index.ts
└── another-function/
    └── index.ts
```

## Development

To develop edge functions locally:

```bash
supabase functions serve
```

To deploy a function:

```bash
supabase functions deploy <function-name>
```

To deploy all functions:

```bash
supabase functions deploy
```

## Functions

### events-sync

Syncs events from the OLP (Ontario Liberal Party) website to the database. Called by a PostgreSQL cron job.

See [events-sync/README.md](./events-sync/README.md) for detailed documentation.

### survey-send-worker

Processes survey send jobs from the PGMQ queue. Sends survey invitation emails and updates campaign progress.

See [survey-send-worker/README.md](./survey-send-worker/README.md) for detailed documentation.

## Documentation

For more information, see the [Supabase Edge Functions documentation](https://supabase.com/docs/guides/functions).

