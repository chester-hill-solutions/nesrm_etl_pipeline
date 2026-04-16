-- Dashboard payload RPCs use CREATE TEMP TABLE / DROP TABLE (and call load_contact_list_page_ids
-- which does the same). STABLE functions may not perform DDL; Postgres raises 0A000 otherwise.

ALTER FUNCTION public.load_contact_dashboard_page_payload_optimized(
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
) VOLATILE;

ALTER FUNCTION public.load_contact_dashboard_page_payload_scoped(
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
) VOLATILE;

ALTER FUNCTION public.load_contact_dashboard_page_payload(
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
) VOLATILE;
