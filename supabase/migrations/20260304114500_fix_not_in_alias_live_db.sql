-- Hotfix for already-applied function definitions where `in_ids` CTE did not
-- name its output column, causing references to `i.id` to fail.
-- Rewrites the live function definitions in-place by adding the CTE column alias.

DO $$
DECLARE
  v_def text;
BEGIN
  SELECT pg_get_functiondef('public.resolve_filter_group(jsonb)'::regprocedure) INTO v_def;
  IF v_def IS NOT NULL THEN
    v_def := regexp_replace(v_def, 'WITH in_ids AS \(', 'WITH in_ids(id) AS (', 'i');
    EXECUTE v_def;
  END IF;
END;
$$;

DO $$
DECLARE
  v_def text;
BEGIN
  SELECT pg_get_functiondef('public.resolve_filter_group_scoped(jsonb,bigint[])'::regprocedure)
  INTO v_def;
  IF v_def IS NOT NULL THEN
    v_def := regexp_replace(v_def, 'WITH in_ids AS \(', 'WITH in_ids(id) AS (', 'i');
    EXECUTE v_def;
  END IF;
END;
$$;
