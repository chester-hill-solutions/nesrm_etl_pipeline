-- Migration: Fix internal event timestamps (UTC/local)
-- Purpose:
-- - Historical internal events were saved from <input type="datetime-local" /> values without timezone
--   into timestamptz columns, causing a timezone offset shift when displayed in the browser.
-- - This migration reinterprets those stored instants as UTC wall-clock values that were *intended*
--   to be America/Toronto local times, then converts them to the correct UTC instants.
--
-- Important:
-- - Only applies to internal events (source='nate', is_external=false).
-- - Uses DST-aware conversion via AT TIME ZONE.

BEGIN;

-- Fix core event timestamps (and registration window timestamps) for internal events.
UPDATE public.events
SET
  start_date = (start_date AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto',
  end_date = (end_date AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto',
  registration_open_at = CASE
    WHEN registration_open_at IS NULL THEN NULL
    ELSE (registration_open_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto'
  END,
  registration_close_at = CASE
    WHEN registration_close_at IS NULL THEN NULL
    ELSE (registration_close_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto'
  END
WHERE source = 'nate'
  AND is_external = false;

-- Fix ticket type sales windows for internal events.
UPDATE public.event_ticket_types ett
SET
  sales_start_at = CASE
    WHEN sales_start_at IS NULL THEN NULL
    ELSE (sales_start_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto'
  END,
  sales_end_at = CASE
    WHEN sales_end_at IS NULL THEN NULL
    ELSE (sales_end_at AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto'
  END
WHERE EXISTS (
  SELECT 1
  FROM public.events e
  WHERE e.id = ett.event_id
    AND e.source = 'nate'
    AND e.is_external = false
);

-- Fix promo code validity windows for internal events.
UPDATE public.event_promo_codes epc
SET
  valid_from = CASE
    WHEN valid_from IS NULL THEN NULL
    ELSE (valid_from AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto'
  END,
  valid_until = CASE
    WHEN valid_until IS NULL THEN NULL
    ELSE (valid_until AT TIME ZONE 'UTC') AT TIME ZONE 'America/Toronto'
  END
WHERE EXISTS (
  SELECT 1
  FROM public.events e
  WHERE e.id = epc.event_id
    AND e.source = 'nate'
    AND e.is_external = false
);

COMMIT;

