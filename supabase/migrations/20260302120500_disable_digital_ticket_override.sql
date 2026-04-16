-- Migration: Explicit override to disable digital tickets
-- Purpose: Allow admins to opt out of sending digital ticket attachments even when auto-send rules apply.

BEGIN;

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS disable_digital_ticket boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.events.disable_digital_ticket IS
  'If true, never attach a digital ticket artifact to attendee emails (overrides include_digital_ticket and auto-send defaults).';

COMMIT;

