-- Idempotent: some databases never applied 20260401120000; RPC + PostgREST expect these objects.

CREATE OR REPLACE FUNCTION public.contact_street_civic_sort_int(p_street text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $func$
DECLARE
  t text;
  m text[];
  n bigint;
BEGIN
  IF p_street IS NULL THEN
    RETURN NULL;
  END IF;
  t := trim(p_street);
  IF t = '' THEN
    RETURN NULL;
  END IF;
  m := regexp_match(t, '^[\s#]*([0-9]+[\s]*[/\-\s]*)?([0-9]+)([^0-9]|$)', 'iu');
  IF m IS NULL OR m[2] IS NULL THEN
    RETURN NULL;
  END IF;
  n := m[2]::bigint;
  IF n > 2147483647 THEN
    RETURN NULL;
  END IF;
  RETURN n::integer;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$func$;

COMMENT ON FUNCTION public.contact_street_civic_sort_int(text) IS
  'Primary civic integer from street_address (matches TS extractStreetCivicNumber / parity filter).';

CREATE OR REPLACE FUNCTION public.contact_street_unit_sort_key(p_street text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $func$
DECLARE
  t text;
  m text[];
  u text;
BEGIN
  IF p_street IS NULL THEN
    RETURN NULL;
  END IF;
  t := trim(p_street);
  IF t = '' THEN
    RETURN NULL;
  END IF;
  m := regexp_match(t, '[[:space:]]+#[0-9A-Za-z-]+[[:space:]]*$', 'i');
  IF m IS NOT NULL AND m[1] IS NOT NULL THEN
    RETURN lower(trim(m[1]));
  END IF;
  m := regexp_match(t, '^[\s#]*([0-9]+)[[:space:]]*/[[:space:]]*[0-9]+', 'i');
  IF m IS NOT NULL AND m[1] IS NOT NULL THEN
    u := trim(m[1]);
    IF u <> '' THEN
      RETURN 'u/' || lower(u);
    END IF;
  END IF;
  RETURN NULL;
END;
$func$;

COMMENT ON FUNCTION public.contact_street_unit_sort_key(text) IS
  'Unit tiebreaker: trailing #suite or leading fraction unit before civic (TS contactStreetUnitSortKey).';

ALTER TABLE public.contact
  ADD COLUMN IF NOT EXISTS street_civic_sort_int integer
  GENERATED ALWAYS AS (public.contact_street_civic_sort_int(street_address)) STORED;

ALTER TABLE public.contact
  ADD COLUMN IF NOT EXISTS street_unit_sort_key text
  GENERATED ALWAYS AS (public.contact_street_unit_sort_key(street_address)) STORED;

COMMENT ON COLUMN public.contact.street_civic_sort_int IS
  'Generated: civic number for sorting (see contact_street_civic_sort_int).';

COMMENT ON COLUMN public.contact.street_unit_sort_key IS
  'Generated: unit fragment for sorting (see contact_street_unit_sort_key).';

CREATE INDEX IF NOT EXISTS contact_street_civic_sort_int_idx
  ON public.contact (street_civic_sort_int);

CREATE INDEX IF NOT EXISTS contact_street_unit_sort_key_idx
  ON public.contact (street_unit_sort_key);
