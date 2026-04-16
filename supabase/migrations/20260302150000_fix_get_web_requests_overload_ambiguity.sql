-- Fix PostgREST RPC ambiguity for get_web_requests.
--
-- PostgREST cannot resolve overloaded functions when defaults make multiple candidates valid.
-- We keep only the newer signature that includes filter_has_message and drop the older 11-arg overload.
--
-- Error seen in app:
-- PGRST203: Could not choose the best candidate function between get_web_requests(..., show_duplicates) and get_web_requests(..., show_duplicates, filter_has_message)

DROP FUNCTION IF EXISTS public.get_web_requests(
  boolean,
  text,
  text,
  timestamp with time zone,
  timestamp with time zone,
  text,
  text,
  text,
  integer,
  integer,
  boolean
);

-- Defensive: some environments may have created the overload with non-tz timestamps.
DROP FUNCTION IF EXISTS public.get_web_requests(
  boolean,
  text,
  text,
  timestamp without time zone,
  timestamp without time zone,
  text,
  text,
  text,
  integer,
  integer,
  boolean
);

-- Ensure PostgREST updates its schema cache immediately.
NOTIFY pgrst, 'reload schema';
