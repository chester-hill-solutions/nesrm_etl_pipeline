-- Align contact_street_civic_sort_int with crm/app/lib/contacts/street-number-parity-quick-filter.ts
-- (extractStreetCivicNumber). The previous regex used [/\-\s]* after the first digit run, which could
-- match zero slashes/dashes and treat "12 34 Oak St" as civic 34 (TS: 12). Recompute stored
-- street_civic_sort_int for all rows after the function change.

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
  m := regexp_match(t, '^[\s#]*([0-9]+[\s]*[-/][\s]*)?([0-9]+)([^0-9]|$)', 'iu');
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

-- STORED generated columns do not refresh when only the function body changes; force recompute.
UPDATE public.contact
SET street_address = street_address
WHERE street_address IS NOT NULL;
