-- Migration: events hide_address_public
-- Purpose: Allow internal events to hide street address publicly.
-- When true, public displays should show only the city name (derived from location_address).

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS hide_address_public boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.events.hide_address_public IS 'If true, public pages should show only the city name (not the street address).';

