-- Remove literal "null" tokens (case-insensitive) from contact.organizer and contact.organizer_codes.
-- sync_contact_organizer_fields merges both columns on update; we strip null from each source so it cannot reappear.
--
-- Dry-run (SQL editor): count rows that would be touched —
--   SELECT count(*) FROM public.contact c
--   WHERE EXISTS (
--     SELECT 1 FROM unnest(regexp_split_to_array(coalesce(c.organizer, ''), '[[:space:]]*,[[:space:]]*')) AS t(tok)
--     WHERE trim(tok) <> '' AND lower(trim(tok)) = 'null'
--   ) OR EXISTS (
--     SELECT 1 FROM unnest(coalesce(c.organizer_codes, '{}'::text[])) AS e(elem)
--     WHERE trim(elem) <> '' AND lower(trim(elem)) = 'null'
--   );

DO $$
DECLARE
  candidate_count integer;
  updated_count integer;
BEGIN
  SELECT count(*)::integer
  INTO candidate_count
  FROM public.contact c
  WHERE EXISTS (
      SELECT 1
      FROM unnest(regexp_split_to_array(coalesce(c.organizer, ''), '[[:space:]]*,[[:space:]]*')) AS t(tok)
      WHERE trim(tok) <> ''
        AND lower(trim(tok)) = 'null'
    )
    OR EXISTS (
      SELECT 1
      FROM unnest(coalesce(c.organizer_codes, '{}'::text[])) AS e(elem)
      WHERE trim(elem) <> ''
        AND lower(trim(elem)) = 'null'
    );

  RAISE NOTICE 'remove_null_contact_organizer_tokens: candidate rows (before): %', candidate_count;

  UPDATE public.contact AS c
  SET
    organizer = cl.new_organizer,
    organizer_codes = cl.new_organizer_codes
  FROM (
    SELECT
      c2.id,
      (
        SELECT array_to_string(array_agg(trim(tok) ORDER BY ord), ',')
        FROM unnest(regexp_split_to_array(coalesce(c2.organizer, ''), '[[:space:]]*,[[:space:]]*'))
          WITH ORDINALITY AS t(tok, ord)
        WHERE trim(tok) <> ''
          AND lower(trim(tok)) <> 'null'
      ) AS new_organizer,
      (
        SELECT coalesce(array_agg(trim(elem) ORDER BY ord), '{}'::text[])
        FROM unnest(coalesce(c2.organizer_codes, '{}'::text[])) WITH ORDINALITY AS t(elem, ord)
        WHERE trim(elem) <> ''
          AND lower(trim(elem)) <> 'null'
      ) AS new_organizer_codes
    FROM public.contact c2
    WHERE EXISTS (
        SELECT 1
        FROM unnest(regexp_split_to_array(coalesce(c2.organizer, ''), '[[:space:]]*,[[:space:]]*')) AS t(tok)
        WHERE trim(tok) <> ''
          AND lower(trim(tok)) = 'null'
      )
      OR EXISTS (
        SELECT 1
        FROM unnest(coalesce(c2.organizer_codes, '{}'::text[])) AS e(elem)
        WHERE trim(elem) <> ''
          AND lower(trim(elem)) = 'null'
      )
  ) AS cl
  WHERE c.id = cl.id;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RAISE NOTICE 'remove_null_contact_organizer_tokens: rows updated: %', updated_count;
END $$;

-- Post-migration verify (expect 0):
--   SELECT count(*) FROM public.contact c
--   WHERE EXISTS (
--     SELECT 1 FROM unnest(regexp_split_to_array(coalesce(c.organizer, ''), '[[:space:]]*,[[:space:]]*')) AS t(tok)
--     WHERE trim(tok) <> '' AND lower(trim(tok)) = 'null'
--   ) OR EXISTS (
--     SELECT 1 FROM unnest(coalesce(c.organizer_codes, '{}'::text[])) AS e(elem)
--     WHERE trim(elem) <> '' AND lower(trim(elem)) = 'null'
--   );
