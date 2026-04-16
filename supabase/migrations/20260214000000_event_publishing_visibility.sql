-- Migration: Event publishing + visibility
-- Purpose: Allow events to be published publicly or privately (staff-only).
-- - published_at: null => not published (draft)
-- - visibility: public|private (only meaningful when published)

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS published_at timestamptz;

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'public';

-- Constrain visibility values (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'events_visibility_check'
  ) THEN
    ALTER TABLE public.events
      ADD CONSTRAINT events_visibility_check
      CHECK (visibility IN ('public', 'private'));
  END IF;
END $$;

-- Helpful indexes for web lookups and filters
CREATE INDEX IF NOT EXISTS idx_events_slug ON public.events(slug);
CREATE INDEX IF NOT EXISTS idx_events_published_at ON public.events(published_at) WHERE published_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_events_visibility ON public.events(visibility);

