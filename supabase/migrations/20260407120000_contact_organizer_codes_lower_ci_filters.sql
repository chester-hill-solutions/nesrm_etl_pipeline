-- Case-insensitive organizer code matching: CRM/RPC lowercases filter tokens, but
-- sync_contact_organizer_fields stores original-case tokens in organizer_codes, so @>/cs was exact-case and missed (e.g. arfin vs Arfin).
--
-- Postgres rejects subqueries directly in GENERATED expressions; use an IMMUTABLE SQL helper.

CREATE OR REPLACE FUNCTION public.contact_organizer_codes_lower_array(codes text[])
RETURNS text[]
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = public
AS $$
  SELECT COALESCE(
    ARRAY(
      SELECT lower(trim(t))
      FROM unnest(codes) AS t
      WHERE trim(t) <> ''
    ),
    ARRAY[]::text[]
  );
$$;

COMMENT ON FUNCTION public.contact_organizer_codes_lower_array(text[]) IS
  'Lowercased organizer_codes elements for GENERATED column organizer_codes_lower (filters).';

ALTER TABLE public.contact
  ADD COLUMN IF NOT EXISTS organizer_codes_lower text[]
  GENERATED ALWAYS AS (public.contact_organizer_codes_lower_array(organizer_codes)) STORED;

COMMENT ON COLUMN public.contact.organizer_codes_lower IS
  'Lowercased organizer_codes elements for case-insensitive filter @> / overlap; GENERATED.';

-- resolve_filter_node: compare on organizer_codes_lower (tokens already lowercased)
DO $migration$
DECLARE
  fd text;
  od text;
BEGIN
  SELECT pg_get_functiondef('public.resolve_filter_node(jsonb)'::regprocedure)
  INTO fd;

  IF fd IS NULL THEN
    RAISE EXCEPTION 'public.resolve_filter_node(jsonb) not found';
  END IF;

  od := fd;
  fd := replace(
    fd,
    'c.organizer_codes @> v_org_codes_tokens',
    'c.organizer_codes_lower @> v_org_codes_tokens'
  );
  fd := replace(
    fd,
    'c.organizer_codes && v_org_codes_tokens',
    'c.organizer_codes_lower && v_org_codes_tokens'
  );

  -- Allow filter column organizer_codes_lower (PostgREST) to use the same branch
  fd := replace(
    fd,
    'IF v_db_col = ''organizer_codes'' THEN',
    'IF v_db_col IN (''organizer_codes'', ''organizer_codes_lower'') THEN'
  );

  IF fd = od THEN
    RAISE NOTICE 'resolve_filter_node organizer_codes_lower patch: no @>/&& replacements (already patched or branch missing)';
  ELSE
    EXECUTE fd;
  END IF;
END;
$migration$;
