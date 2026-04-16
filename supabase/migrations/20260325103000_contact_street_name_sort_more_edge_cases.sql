-- More street_name_sort_key edge cases: unit letters, glued civic+street, 118A., 20-Teesdale,
-- 1804-30- Burnhill, comma chains, rural "11 Line" / "11 Street", trailing #suite.
-- (Does not strip ordinal street names like "10th St" — those are part of the street name.)

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

    IF s ~* '^(#[[:space:]]*)?[0-9]+[[:space:]]*/[[:space:]]*[0-9]+([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(
        regexp_replace(
          s,
          '^(#[[:space:]]*)?[0-9]+[[:space:]]*/[[:space:]]*[0-9]+([[:space:]]*,[[:space:]]*|[[:space:]]+)',
          '',
          'i'
        )
      );
    ELSIF s ~ '^[0-9]+([[:space:]]*-[[:space:]]*[0-9]+)+[[:space:]]*-[[:space:]]+[[:alpha:]]' THEN
      s := trim(
        regexp_replace(
          s,
          '^[0-9]+([[:space:]]*-[[:space:]]*[0-9]+)+[[:space:]]*-[[:space:]]+',
          '',
          ''
        )
      );
    ELSIF s ~ '^(#[[:space:]]*)?[0-9]+[A-Za-z]?([[:space:]]*-[[:space:]]*[0-9]+)+([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(
        regexp_replace(
          s,
          '^(#[[:space:]]*)?[0-9]+[A-Za-z]?([[:space:]]*-[[:space:]]*[0-9]+)+([[:space:]]*,[[:space:]]*|[[:space:]]+)',
          '',
          ''
        )
      );
    ELSIF s ~ '^[0-9]+-[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(regexp_replace(s, '^[0-9]+-[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)', '', ''));
    ELSIF s ~ '^[0-9]+-[A-Za-z]([[:space:]]*,[[:space:]]*|[[:space:]]+)' THEN
      s := trim(regexp_replace(s, '^[0-9]+-[A-Za-z]([[:space:]]*,[[:space:]]*|[[:space:]]+)', '', ''));
    ELSIF s ~ '^[0-9]+-[[:alpha:]]' AND s !~ '^[0-9]+-[0-9]' THEN
      s := trim(regexp_replace(s, '^[0-9]+-', '', ''));
    ELSIF s ~ '^[0-9]+[[:space:]]*-[[:space:]]+[[:alpha:]]' THEN
      s := trim(regexp_replace(s, '^[0-9]+[[:space:]]*-[[:space:]]+', '', ''));
    ELSIF s ~ '^[0-9]+[A-Za-z][[:space:]]*[.][[:space:]]+' THEN
      s := trim(regexp_replace(s, '^[0-9]+[A-Za-z][[:space:]]*[.][[:space:]]+', '', ''));
    ELSIF s ~ '^#[[:space:]]*[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)'
          AND s !~* '^#[[:space:]]*[0-9]{1,2}[[:space:]]+(line|street)([[:space:]]|,|$)' THEN
      s := trim(
        regexp_replace(
          s,
          '^#[[:space:]]*[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)',
          '',
          ''
        )
      );
    ELSIF s ~ '^[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)'
          AND s !~ '^#'
          AND s !~* '^[0-9]{1,2}[[:space:]]+(line|street)([[:space:]]|,|$)' THEN
      s := trim(regexp_replace(s, '^[0-9]+[A-Za-z]?([[:space:]]*,[[:space:]]*|[[:space:]]+)', '', ''));
    -- 121Queen St: 3+ digits glued to uppercase street word (not 10th / 2Nd)
    ELSIF s ~ '^[0-9]{3,}[[:upper:]]' THEN
      s := trim(regexp_replace(s, '^[0-9]+', '', ''));
    ELSE
      EXIT;
    END IF;

    IF s = s_prev THEN
      EXIT;
    END IF;
  END LOOP;

  s := trim(regexp_replace(s, '[[:space:]]+#[0-9A-Za-z-]+[[:space:]]*$', '', ''));

  IF s = '' OR s ~ '^[0-9]+$' THEN
    RETURN NULL;
  END IF;
  RETURN s;
END;
$func$;

COMMENT ON FUNCTION public.contact_street_name_sort_key(text) IS
  'Sort key from street_address: strips civic tokens; preserves ordinal street names (10th St) and 1–2 digit Line/Street rural names.';

UPDATE public.contact
SET street_address = street_address
WHERE street_address IS NOT NULL;
