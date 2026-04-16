-- Migration: Events default to private
-- Purpose: New events are private/draft by default. Backfill internal (source='nate') events only.
-- Depends on: 20260214000000_event_publishing_visibility.sql

ALTER TABLE public.events ALTER COLUMN visibility SET DEFAULT 'private';

-- Backfill internal events only: set to private and draft
UPDATE public.events
SET visibility = 'private', published_at = NULL
WHERE source = 'nate';
