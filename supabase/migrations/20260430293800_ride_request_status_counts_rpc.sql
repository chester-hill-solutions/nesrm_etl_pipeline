-- Ride-requests dashboard: aggregate ride_request_status counts without loading all contacts.
-- Matches scoped + resolve_filter_group + expanded search semantics used by load_contact_dashboard_page_payload_optimized.

CREATE OR REPLACE FUNCTION public.ride_request_status_counts(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_search_term text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_has_filter boolean;
  v_search_esc text;
  v_email_mode boolean;
  v_all bigint;
  v_none bigint;
  v_requested bigint;
  v_confirmed bigint;
  v_completed bigint;
  v_cancelled bigint;
BEGIN
  v_has_filter :=
    p_filter_group IS NOT NULL
    AND jsonb_typeof(p_filter_group) = 'object'
    AND (p_filter_group->'children') IS NOT NULL
    AND jsonb_array_length(p_filter_group->'children') > 0;

  IF p_search_term IS NOT NULL AND TRIM(p_search_term) <> '' THEN
    v_search_esc := public.escape_search_for_ilike(TRIM(p_search_term));
    v_email_mode := (position('@' IN TRIM(p_search_term)) > 0);
  ELSE
    v_search_esc := NULL;
    v_email_mode := false;
  END IF;

  WITH scoped_ids AS (
    SELECT c.id
    FROM public.contact c
    WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
      AND (
        (
          COALESCE(TRIM(p_scope_type), 'all_contacts') = 'all_contacts'
          AND (p_scope_values IS NULL OR cardinality(p_scope_values) = 0)
        )
        OR (
          p_scope_type = 'riding'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND c.division_electoral_district = ANY(p_scope_values)
        )
        OR (
          p_scope_type = 'campus'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND c.campus_club = ANY(p_scope_values)
        )
        OR (
          p_scope_type = 'signups'
          AND p_scope_values IS NOT NULL
          AND cardinality(p_scope_values) > 0
          AND EXISTS (
            SELECT 1
            FROM unnest(regexp_split_to_array(lower(COALESCE(c.organizer, '')), '[^a-z0-9_-]+')) AS t(token)
            WHERE TRIM(t.token) <> ''
              AND TRIM(t.token) IN (
                SELECT lower(TRIM(x)) FROM unnest(p_scope_values) AS x WHERE TRIM(x) <> ''
              )
          )
        )
      )
  ),
  filtered_ids AS (
    SELECT s.id
    FROM scoped_ids s
    WHERE NOT v_has_filter
      OR EXISTS (
        SELECT 1
        FROM public.resolve_filter_group(p_filter_group) AS f(id)
        WHERE f.id = s.id
      )
  ),
  searched_ids AS (
    SELECT f.id
    FROM filtered_ids f
    JOIN public.contact c ON c.id = f.id
    WHERE p_search_term IS NULL
      OR TRIM(p_search_term) = ''
      OR (
        (v_email_mode AND c.email ILIKE '%' || v_search_esc || '%')
        OR (
          NOT v_email_mode
          AND (
            (
              position(' ' IN v_search_esc) > 0
              AND c.firstname ILIKE '%' || TRIM(split_part(v_search_esc, ' ', 1)) || '%'
              AND c.surname ILIKE '%' || TRIM(
                substring(v_search_esc FROM position(' ' IN v_search_esc))
              ) || '%'
            )
            OR c.phone ILIKE '%' || v_search_esc || '%'
            OR c.street_address ILIKE '%' || v_search_esc || '%'
            OR c.municipality ILIKE '%' || v_search_esc || '%'
            OR c.division ILIKE '%' || v_search_esc || '%'
            OR c.region ILIKE '%' || v_search_esc || '%'
            OR c.country ILIKE '%' || v_search_esc || '%'
            OR c.postcode ILIKE '%' || v_search_esc || '%'
            OR (
              (position(' ' IN v_search_esc) = 0 OR position(' ' IN v_search_esc) IS NULL)
              AND (
                c.firstname ILIKE '%' || v_search_esc || '%'
                OR c.surname ILIKE '%' || v_search_esc || '%'
              )
            )
          )
        )
      )
  ),
  agg AS (
    SELECT
      COUNT(*)::bigint AS all_cnt,
      COUNT(*) FILTER (
        WHERE c.ride_request_status IS NULL OR BTRIM(c.ride_request_status) = ''
      )::bigint AS none_cnt,
      COUNT(*) FILTER (WHERE lower(BTRIM(c.ride_request_status)) = 'requested')::bigint AS requested_cnt,
      COUNT(*) FILTER (WHERE lower(BTRIM(c.ride_request_status)) = 'confirmed')::bigint AS confirmed_cnt,
      COUNT(*) FILTER (WHERE lower(BTRIM(c.ride_request_status)) = 'completed')::bigint AS completed_cnt,
      COUNT(*) FILTER (WHERE lower(BTRIM(c.ride_request_status)) = 'cancelled')::bigint AS cancelled_cnt
    FROM searched_ids s
    JOIN public.contact c ON c.id = s.id
  )
  SELECT
    a.all_cnt,
    a.none_cnt,
    a.requested_cnt,
    a.confirmed_cnt,
    a.completed_cnt,
    a.cancelled_cnt
  INTO v_all, v_none, v_requested, v_confirmed, v_completed, v_cancelled
  FROM agg a;

  RETURN jsonb_build_object(
    'all', COALESCE(v_all, 0),
    'none', COALESCE(v_none, 0),
    'requested', COALESCE(v_requested, 0),
    'confirmed', COALESCE(v_confirmed, 0),
    'completed', COALESCE(v_completed, 0),
    'cancelled', COALESCE(v_cancelled, 0)
  );
END;
$$;

COMMENT ON FUNCTION public.ride_request_status_counts(text, text[], text, text, jsonb, text) IS
  'Ride-requests tab counts: scoped contacts intersect resolve_filter_group + dashboard search, then aggregate ride_request_status.';

GRANT EXECUTE ON FUNCTION public.ride_request_status_counts(text, text[], text, text, jsonb, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ride_request_status_counts(text, text[], text, text, jsonb, text) TO service_role;
