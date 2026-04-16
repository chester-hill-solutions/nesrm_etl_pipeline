-- "contains" on organizer_codes should match substring case-insensitively (like other text columns),
-- not exact array element @>. RPC + PostgREST use a generated lowercased join blob for ILIKE.

CREATE OR REPLACE FUNCTION public.contact_organizer_codes_search_blob(codes text[])
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = public
AS $$
  SELECT lower(array_to_string(codes, ' '));
$$;

COMMENT ON FUNCTION public.contact_organizer_codes_search_blob(text[]) IS
  'Lowercased space-joined organizer_codes for substring ILIKE filters.';

ALTER TABLE public.contact
  ADD COLUMN IF NOT EXISTS organizer_codes_search_blob text
  GENERATED ALWAYS AS (
    CASE
      WHEN organizer_codes IS NULL THEN NULL
      ELSE public.contact_organizer_codes_search_blob(organizer_codes)
    END
  ) STORED;

COMMENT ON COLUMN public.contact.organizer_codes_search_blob IS
  'GENERATED: lower(array_to_string(organizer_codes, '' '')) for organizer_codes contains / not_contains.';

-- Split eq vs contains; neq vs not_contains in resolve_filter_node (organizer_codes branch).
DO $migration$
DECLARE
  fd text;
  od text;
  old_eq_contains_lower text := $old$
    IF v_op IN ('contains', 'eq') THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND c.organizer_codes_lower @> v_org_codes_tokens;
      RETURN;
$old$;
  new_eq_contains text := $new$
    IF v_op = 'eq' THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND NOT EXISTS (
          SELECT 1
          FROM unnest(v_org_codes_tokens) AS tok
          WHERE NOT EXISTS (
            SELECT 1
            FROM unnest(COALESCE(c.organizer_codes, '{}')) AS elem
            WHERE lower(trim(elem)) = tok
          )
        );
      RETURN;
    ELSIF v_op = 'contains' THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND NOT EXISTS (
          SELECT 1
          FROM unnest(v_org_codes_tokens) AS tok
          WHERE NOT (
            COALESCE(
              lower(array_to_string(COALESCE(c.organizer_codes, '{}'), ' ')),
              ''
            ) LIKE '%' || public.escape_search_for_ilike(tok) || '%'
          )
        );
      RETURN;
$new$;
  old_eq_contains_plain text := $old2$
    IF v_op IN ('contains', 'eq') THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND c.organizer_codes @> v_org_codes_tokens;
      RETURN;
$old2$;
  old_not_lower text := $n1$
    ELSIF v_op IN ('not_contains', 'neq') THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR NOT (c.organizer_codes_lower @> v_org_codes_tokens)
        );
      RETURN;
$n1$;
  new_not text := $n2$
    ELSIF v_op = 'neq' THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR EXISTS (
            SELECT 1
            FROM unnest(v_org_codes_tokens) AS tok
            WHERE NOT EXISTS (
              SELECT 1
              FROM unnest(COALESCE(c.organizer_codes, '{}')) AS elem
              WHERE lower(trim(elem)) = tok
            )
          )
        );
      RETURN;
    ELSIF v_op = 'not_contains' THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR EXISTS (
            SELECT 1
            FROM unnest(v_org_codes_tokens) AS tok
            WHERE NOT (
              COALESCE(
                lower(array_to_string(COALESCE(c.organizer_codes, '{}'), ' ')),
                ''
              ) LIKE '%' || public.escape_search_for_ilike(tok) || '%'
            )
          )
        );
      RETURN;
$n2$;
  old_not_plain text := $n3$
    ELSIF v_op IN ('not_contains', 'neq') THEN
      IF coalesce(array_length(v_org_codes_tokens, 1), 0) = 0 THEN
        RETURN;
      END IF;
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND (
          c.organizer_codes IS NULL
          OR NOT (c.organizer_codes @> v_org_codes_tokens)
        );
      RETURN;
$n3$;
BEGIN
  SELECT pg_get_functiondef('public.resolve_filter_node(jsonb)'::regprocedure)
  INTO fd;

  IF fd IS NULL THEN
    RAISE EXCEPTION 'public.resolve_filter_node(jsonb) not found';
  END IF;

  od := fd;

  IF strpos(fd, old_eq_contains_lower) > 0 THEN
    fd := replace(fd, old_eq_contains_lower, new_eq_contains);
  ELSIF strpos(fd, old_eq_contains_plain) > 0 THEN
    fd := replace(fd, old_eq_contains_plain, new_eq_contains);
  ELSE
    RAISE NOTICE 'resolve_filter_node organizer substring patch: eq/contains block not found; skip';
  END IF;

  IF strpos(fd, old_not_lower) > 0 THEN
    fd := replace(fd, old_not_lower, new_not);
  ELSIF strpos(fd, old_not_plain) > 0 THEN
    fd := replace(fd, old_not_plain, new_not);
  ELSE
    RAISE NOTICE 'resolve_filter_node organizer substring patch: not_contains/neq block not found; skip';
  END IF;

  IF fd = od THEN
    RAISE NOTICE 'resolve_filter_node organizer substring patch: definition unchanged';
  ELSE
    EXECUTE fd;
  END IF;
END;
$migration$;
