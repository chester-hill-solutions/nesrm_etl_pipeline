-- GOTV dashboard: SQL-side latest vote filter + pagination, and aggregate counts without full contact hydration.

CREATE OR REPLACE FUNCTION public.load_gotv_contact_page_ids(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_voted_filter text,
  p_sort_rules jsonb,
  p_page integer,
  p_page_size integer,
  p_search_term text,
  p_group_by_household boolean DEFAULT false
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
  v_page_num integer;
  v_limit integer;
  v_vote text;
  v_ids bigint[];
  v_total bigint;
  v_page_ids bigint[];
BEGIN
  v_page_num := GREATEST(COALESCE(p_page, 1), 1);
  v_limit := GREATEST(COALESCE(p_page_size, 25), 1);
  v_vote := lower(trim(COALESCE(p_voted_filter, 'all')));
  IF v_vote NOT IN ('all', 'voted', 'not_voted') THEN
    v_vote := 'all';
  END IF;

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
  with_vote AS (
    SELECT
      s.id,
      (
        SELECT h.voted
        FROM public.contact_voting_history h
        WHERE h.contact_id = s.id
        ORDER BY h.marked_at DESC NULLS LAST, h.id DESC
        LIMIT 1
      ) AS latest_voted
    FROM searched_ids s
  ),
  slice_ids AS (
    SELECT w.id
    FROM with_vote w
    WHERE v_vote = 'all'
      OR (v_vote = 'voted' AND w.latest_voted IS TRUE)
      OR (v_vote = 'not_voted' AND w.latest_voted IS NOT TRUE)
  )
  SELECT
    COUNT(*)::bigint,
    COALESCE(array_agg(slice.id ORDER BY slice.id), ARRAY[]::bigint[])
  INTO v_total, v_ids
  FROM slice_ids slice;

  IF v_ids IS NULL OR cardinality(v_ids) = 0 THEN
    RETURN jsonb_build_object(
      'contact_ids', '[]'::jsonb,
      'total_count', COALESCE(v_total, 0)
    );
  END IF;

  SELECT COALESCE(array_agg(x.contact_id ORDER BY x.rn), ARRAY[]::bigint[])
  INTO v_page_ids
  FROM (
    SELECT row_number() OVER () AS rn, o.contact_id
    FROM public.load_contact_list_page_ids(
      v_ids,
      COALESCE(p_sort_rules, '[]'::jsonb),
      v_page_num,
      v_limit,
      p_role,
      COALESCE(p_group_by_household, false)
    ) o
  ) x;

  RETURN jsonb_build_object(
    'contact_ids', COALESCE(to_jsonb(v_page_ids), '[]'::jsonb),
    'total_count', COALESCE(v_total, 0)
  );
END;
$$;

COMMENT ON FUNCTION public.load_gotv_contact_page_ids(text, text[], text, text, jsonb, text, jsonb, integer, integer, text, boolean) IS
  'GOTV: contacts matching scope + filter + search + latest vote slice; returns one page of contact ids (sorted) and full slice total_count.';

CREATE OR REPLACE FUNCTION public.load_gotv_dashboard_counts(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_voted_filter text,
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
  v_vote text;
  v_all bigint;
  v_not_contacted bigint;
  v_contacted bigint;
  v_on_their_way bigint;
  v_voted_status bigint;
  v_unreachable bigint;
  v_follow_up bigint;
  v_voting_yes bigint;
  v_voting_no bigint;
BEGIN
  v_vote := lower(trim(COALESCE(p_voted_filter, 'all')));
  IF v_vote NOT IN ('all', 'voted', 'not_voted') THEN
    v_vote := 'all';
  END IF;

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
  with_vote AS (
    SELECT
      s.id,
      (
        SELECT h.voted
        FROM public.contact_voting_history h
        WHERE h.contact_id = s.id
        ORDER BY h.marked_at DESC NULLS LAST, h.id DESC
        LIMIT 1
      ) AS latest_voted
    FROM searched_ids s
  ),
  slice_ids AS (
    SELECT w.id, w.latest_voted
    FROM with_vote w
    WHERE v_vote = 'all'
      OR (v_vote = 'voted' AND w.latest_voted IS TRUE)
      OR (v_vote = 'not_voted' AND w.latest_voted IS NOT TRUE)
  ),
  joined AS (
    SELECT
      s.id,
      s.latest_voted,
      CASE
        WHEN c.contact_status IS NULL OR BTRIM(c.contact_status) = '' THEN 'not_contacted'
        ELSE lower(BTRIM(c.contact_status))
      END AS st
    FROM slice_ids s
    JOIN public.contact c ON c.id = s.id
  ),
  agg AS (
    SELECT
      COUNT(*)::bigint AS all_cnt,
      COUNT(*) FILTER (
        WHERE j.st = 'not_contacted'
          OR j.st NOT IN (
            'contacted',
            'on_their_way',
            'voted',
            'unreachable',
            'follow_up'
          )
      )::bigint AS not_contacted_cnt,
      COUNT(*) FILTER (WHERE j.st = 'contacted')::bigint AS contacted_cnt,
      COUNT(*) FILTER (WHERE j.st = 'on_their_way')::bigint AS on_their_way_cnt,
      COUNT(*) FILTER (WHERE j.st = 'voted')::bigint AS voted_status_cnt,
      COUNT(*) FILTER (WHERE j.st = 'unreachable')::bigint AS unreachable_cnt,
      COUNT(*) FILTER (WHERE j.st = 'follow_up')::bigint AS follow_up_cnt,
      COUNT(*) FILTER (WHERE j.latest_voted IS TRUE)::bigint AS voting_yes_cnt,
      COUNT(*) FILTER (WHERE j.latest_voted IS NOT TRUE)::bigint AS voting_no_cnt
    FROM joined j
  )
  SELECT
    a.all_cnt,
    a.not_contacted_cnt,
    a.contacted_cnt,
    a.on_their_way_cnt,
    a.voted_status_cnt,
    a.unreachable_cnt,
    a.follow_up_cnt,
    a.voting_yes_cnt,
    a.voting_no_cnt
  INTO
    v_all,
    v_not_contacted,
    v_contacted,
    v_on_their_way,
    v_voted_status,
    v_unreachable,
    v_follow_up,
    v_voting_yes,
    v_voting_no
  FROM agg a;

  RETURN jsonb_build_object(
    'statusCounts',
    jsonb_build_object(
      'all', COALESCE(v_all, 0),
      'not_contacted', COALESCE(v_not_contacted, 0),
      'contacted', COALESCE(v_contacted, 0),
      'on_their_way', COALESCE(v_on_their_way, 0),
      'voted', COALESCE(v_voted_status, 0),
      'unreachable', COALESCE(v_unreachable, 0),
      'follow_up', COALESCE(v_follow_up, 0)
    ),
    'votingCounts',
    jsonb_build_object(
      'voted', COALESCE(v_voting_yes, 0),
      'not_voted', COALESCE(v_voting_no, 0)
    )
  );
END;
$$;

COMMENT ON FUNCTION public.load_gotv_dashboard_counts(text, text[], text, text, jsonb, text, text) IS
  'GOTV: status + voting tallies for contacts matching scope + filter + search + optional vote slice.';

GRANT EXECUTE ON FUNCTION public.load_gotv_contact_page_ids(text, text[], text, text, jsonb, text, jsonb, integer, integer, text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.load_gotv_contact_page_ids(text, text[], text, text, jsonb, text, jsonb, integer, integer, text, boolean) TO service_role;

GRANT EXECUTE ON FUNCTION public.load_gotv_dashboard_counts(text, text[], text, text, jsonb, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.load_gotv_dashboard_counts(text, text[], text, text, jsonb, text, text) TO service_role;
