-- PostgreSQL regexp_match does not accept the Perl/JS "u" (Unicode) flag; using 'iu' raises
-- 22023 invalid regular expression option and contact_street_civic_sort_int's EXCEPTION handler
-- returned NULL for every address — breaking civic / composite street sort in load_contact_list_page_ids.

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
  m := regexp_match(t, '^[\s#]*([0-9]+[\s]*[-/][\s]*)?([0-9]+)([^0-9]|$)', 'i');
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

UPDATE public.contact
SET street_address = street_address
WHERE street_address IS NOT NULL;
