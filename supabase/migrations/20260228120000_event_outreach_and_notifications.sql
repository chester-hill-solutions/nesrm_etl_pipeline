-- Migration: Event outreach targeting + registration notification tracking
-- Purpose:
-- 1) Add event-level settings for registration confirmations, digital tickets, RSVP reminders
-- 2) Add event-level marketing targeting (ridings + segments)
-- 3) Add registration-level notification timestamps for idempotent email delivery

BEGIN;

--------------------------------------------------------------------------------
-- 1. Event-level outreach + notification settings
--------------------------------------------------------------------------------

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS send_registration_confirmation boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS include_digital_ticket boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS send_rsvp_reminder boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS rsvp_reminder_hours_before integer NOT NULL DEFAULT 24,
  ADD COLUMN IF NOT EXISTS target_ridings text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS target_segment_ids uuid[] NOT NULL DEFAULT '{}';

DO $$
BEGIN
  ALTER TABLE public.events
    ADD CONSTRAINT events_rsvp_reminder_hours_before_check
    CHECK (rsvp_reminder_hours_before >= 1 AND rsvp_reminder_hours_before <= 336);
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

COMMENT ON COLUMN public.events.send_registration_confirmation IS
  'If true, send a confirmation email after registration/payment completion.';
COMMENT ON COLUMN public.events.include_digital_ticket IS
  'If true, include a digital ticket artifact with confirmation/reminder emails.';
COMMENT ON COLUMN public.events.send_rsvp_reminder IS
  'If true, send automatic reminder emails to RSVP/registered attendees before the event.';
COMMENT ON COLUMN public.events.rsvp_reminder_hours_before IS
  'Reminder lead time in hours before event start (1-336).';
COMMENT ON COLUMN public.events.target_ridings IS
  'Target riding names for event-related outreach (sms/email) audience building.';
COMMENT ON COLUMN public.events.target_segment_ids IS
  'Target segment IDs for event-related outreach (sms/email) audience building.';

CREATE INDEX IF NOT EXISTS idx_events_target_ridings_gin
  ON public.events USING gin (target_ridings);
CREATE INDEX IF NOT EXISTS idx_events_target_segment_ids_gin
  ON public.events USING gin (target_segment_ids);
CREATE INDEX IF NOT EXISTS idx_events_rsvp_reminder_enabled_start_date
  ON public.events (start_date)
  WHERE send_rsvp_reminder = true;

--------------------------------------------------------------------------------
-- 2. Registration-level notification timestamps
--------------------------------------------------------------------------------

ALTER TABLE public.event_registrations
  ADD COLUMN IF NOT EXISTS confirmation_email_sent_at timestamptz,
  ADD COLUMN IF NOT EXISTS reminder_email_sent_at timestamptz;

COMMENT ON COLUMN public.event_registrations.confirmation_email_sent_at IS
  'When the registration confirmation email was successfully sent.';
COMMENT ON COLUMN public.event_registrations.reminder_email_sent_at IS
  'When the reminder email was successfully sent.';

CREATE INDEX IF NOT EXISTS idx_event_registrations_confirmation_email_sent_at
  ON public.event_registrations (confirmation_email_sent_at);
CREATE INDEX IF NOT EXISTS idx_event_registrations_reminder_email_sent_at
  ON public.event_registrations (reminder_email_sent_at);
CREATE INDEX IF NOT EXISTS idx_event_registrations_reminder_candidates
  ON public.event_registrations (event_id, status, reminder_email_sent_at);

COMMIT;
