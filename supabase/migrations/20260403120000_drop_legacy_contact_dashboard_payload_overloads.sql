-- PostgREST PGRST203: 12-arg and 16-arg overloads of the contact dashboard RPCs both match
-- calls that omit the segment-swipe parameters (the longer signatures use DEFAULT NULL).
-- Drop the legacy overloads; the 16-parameter versions subsume them.

DROP FUNCTION IF EXISTS public.load_contact_dashboard_page_payload(
  text,
  text[],
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  integer,
  boolean,
  boolean,
  boolean,
  boolean
);

DROP FUNCTION IF EXISTS public.load_contact_dashboard_page_payload_optimized(
  text,
  text[],
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  integer,
  boolean,
  boolean,
  boolean,
  boolean
);

DROP FUNCTION IF EXISTS public.load_contact_dashboard_page_payload_scoped(
  text,
  text[],
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  integer,
  boolean,
  boolean,
  boolean,
  boolean
);

DROP FUNCTION IF EXISTS public.load_contact_dashboard_table_page(
  text,
  text[],
  text,
  text,
  jsonb,
  jsonb,
  text,
  integer,
  integer,
  boolean,
  boolean,
  boolean,
  boolean
);
