-- Migration: Add ticket token to event registrations
-- Purpose: Provide a durable public token for digital tickets (QR + scan-to-check-in).

BEGIN;

-- Add column nullable first to safely backfill existing rows.
ALTER TABLE public.event_registrations
  ADD COLUMN IF NOT EXISTS ticket_token uuid;

-- Ensure new rows get a token.
ALTER TABLE public.event_registrations
  ALTER COLUMN ticket_token SET DEFAULT gen_random_uuid();

-- Backfill existing rows.
UPDATE public.event_registrations
SET ticket_token = gen_random_uuid()
WHERE ticket_token IS NULL;

-- Enforce presence + uniqueness.
ALTER TABLE public.event_registrations
  ALTER COLUMN ticket_token SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_event_registrations_ticket_token_unique
  ON public.event_registrations (ticket_token);

COMMENT ON COLUMN public.event_registrations.ticket_token IS
  'Public token used to render and validate digital tickets at check-in.';

COMMIT;

