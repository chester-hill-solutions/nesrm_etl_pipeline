-- Refine contact_street_name_sort_key: # civic, comma after number, multi-segment hyphens,
-- repeated strips (e.g. 784 1/2 Crawford), and "63 - Warden Ave" (dash before street name).

CREATE OR REPLACE FUNCTION public.contact_street_name_sort_key(p_street text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
STRICT
PARALLEL SAFE
SET search_path = public
AS $func$
DECLARE
  s text;
  s_prev text;
  pass integer := 0;
BEGIN
  s := trim(p_street);
  IF s = '' THEN
    RETURN NULL;
  END IF;

  LOOP
    s_prev := s;
    pass := pass + 1;
    IF pass > 24 THEN
      EXIT;
    END IF;

    -- Optional # + fraction (e.g. "1/2 Main", "# 1/2 Main")
    IF s ~* '^(#[[:space:]]*)?[0-9]+[[:space:]]*/[[:space:]]*[0-9]+([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(
        regexp_replace(
          s,
          '^(#[[:space:]]*)?[0-9]+[[:space:]]*/[[:space:]]*[0-9]+([[:space:]]*,[[:space:]]*|[[:space:]]+)',
          '',
          'i'
        )
      );
    -- Optional # + hyphen-run (#1-120, #1802-30, 12-14 Dupont, 1-391 Barrie Rd)
    ELSIF s ~ '^(#[[:space:]]*)?[0-9]+[A-Za-z]?([[:space:]]*-[[:space:]]*[0-9]+)+([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(
        regexp_replace(
          s,
          '^(#[[:space:]]*)?[0-9]+[A-Za-z]?([[:space:]]*-[[:space:]]*[0-9]+)+([[:space:]]*,[[:space:]]*|[[:space:]]+)',
          '',
          ''
        )
      );
    -- Digit(s), spaces, hyphen, spaces, then a letter — "63 - Warden Ave" (not "12-14 Dupont")
    ELSIF s ~ '^[0-9]+[[:space:]]*-[[:space:]]+[[:alpha:]]' THEN
      s := trim(regexp_replace(s, '^[0-9]+[[:space:]]*-[[:space:]]+', '', ''));
    -- Optional # + simple civic + comma or space
    ELSIF s ~ '^(#[[:space:]]*)?[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(
        regexp_replace(
          s,
          '^(#[[:space:]]*)?[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)',
          '',
          'i'
        )
      );
    -- Simple civic without #
    ELSIF s ~ '^[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(regexp_replace(s, '^[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)', '', ''));
    ELSE
      EXIT;
    END IF;

    IF s = s_prev THEN
      EXIT;
    END IF;
  END LOOP;

  IF s = '' OR s ~ '^[0-9]+$' THEN
    RETURN NULL;
  END IF;
  RETURN s;
END;
$func$;

COMMENT ON FUNCTION public.contact_street_name_sort_key(text) IS
  'Sort key from street_address: strips leading civic tokens (#, fractions, hyphen ranges, comma after number, repeated passes) so lists sort by street name.';

-- STORED generated column does not auto-refresh when only the function body changes.
UPDATE public.contact
SET street_address = street_address
WHERE street_address IS NOT NULL;
