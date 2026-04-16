-- Optimized payload RPC for nested segment filters.
-- Keeps the response contract the same while reducing early array materialization.

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_page_payload_optimized(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_sort_rules jsonb,
  p_search_term text,
  p_page integer,
  p_page_size integer,
  p_include_unanswered_status boolean DEFAULT true,
  p_include_button_state boolean DEFAULT true,
  p_include_pending_suggestions boolean DEFAULT true
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
  v_candidate_ids bigint[];
  v_page_ids bigint[];
  v_total_count bigint := 0;
  v_contacts jsonb;
  v_unanswered jsonb := '{}'::jsonb;
  v_button_colour jsonb := '{}'::jsonb;
  v_button_survey_id jsonb := '{}'::jsonb;
  v_pending_suggestions jsonb := '{}'::jsonb;
  v_latest_survey_id integer;
  v_page_rec record;
BEGIN
  v_page_num := GREATEST(COALESCE(p_page, 1), 1);
  v_limit := GREATEST(COALESCE(p_page_size, 25), 1);
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
        (COALESCE(TRIM(p_scope_type), 'all_contacts') = 'all_contacts' AND (p_scope_values IS NULL OR cardinality(p_scope_values) = 0))
        OR (p_scope_type = 'riding' AND p_scope_values IS NOT NULL AND cardinality(p_scope_values) > 0 AND c.division_electoral_district = ANY(p_scope_values))
        OR (p_scope_type = 'campus' AND p_scope_values IS NOT NULL AND cardinality(p_scope_values) > 0 AND c.campus_club = ANY(p_scope_values))
        OR (p_scope_type = 'signups' AND p_scope_values IS NOT NULL AND cardinality(p_scope_values) > 0 AND (
          EXISTS (
            SELECT 1
            FROM unnest(regexp_split_to_array(lower(COALESCE(c.organizer, '')), '[^a-z0-9_-]+')) AS t(token)
            WHERE TRIM(t.token) <> ''
              AND TRIM(t.token) IN (
                SELECT lower(TRIM(x)) FROM unnest(p_scope_values) AS x WHERE TRIM(x) <> ''
              )
          )
        ))
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
          AND position(' ' IN v_search_esc) > 0
          AND c.firstname ILIKE '%' || TRIM(split_part(v_search_esc, ' ', 1)) || '%'
          AND c.surname ILIKE '%' || TRIM(substring(v_search_esc FROM position(' ' IN v_search_esc))) || '%'
        )
        OR (
          NOT v_email_mode
          AND (position(' ' IN v_search_esc) = 0 OR position(' ' IN v_search_esc) IS NULL)
          AND (c.firstname ILIKE '%' || v_search_esc || '%' OR c.surname ILIKE '%' || v_search_esc || '%')
        )
      )
  ),
  limited_ids AS (
    SELECT s.id
    FROM searched_ids s
    ORDER BY s.id
    LIMIT 10000
  )
  SELECT array_agg(id ORDER BY id) INTO v_candidate_ids
  FROM limited_ids;

  IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
    RETURN jsonb_build_object(
      'contacts', '[]'::jsonb,
      'total_count', 0,
      'unanswered_status', v_unanswered,
      'contact_survey_button_colour', v_button_colour,
      'contact_survey_button_survey_id', v_button_survey_id,
      'pending_suggestions_by_contact', v_pending_suggestions
    );
  END IF;

  WITH ordered AS (
    SELECT o.contact_id, o.total_count, row_number() OVER () AS rn
    FROM public.load_contact_list_page_ids(
      v_candidate_ids,
      COALESCE(p_sort_rules, '[]'::jsonb),
      v_page_num,
      v_limit,
      p_role
    ) o
  ),
  page_ids AS (SELECT ordered.contact_id, ordered.rn FROM ordered),
  tot AS (SELECT ordered.total_count FROM ordered LIMIT 1),
  agg_ids AS (SELECT array_agg(contact_id ORDER BY rn) AS ids FROM page_ids)
  SELECT a.ids, t.total_count INTO v_page_rec FROM agg_ids a, tot t;

  v_page_ids := v_page_rec.ids;
  v_total_count := v_page_rec.total_count;

  IF v_total_count IS NULL THEN
    v_total_count := 0;
  END IF;
  IF v_page_ids IS NULL THEN
    v_page_ids := ARRAY[]::bigint[];
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(c)::jsonb ORDER BY array_position(v_page_ids, c.id)), '[]'::jsonb)
  INTO v_contacts
  FROM public.contact c
  WHERE c.id = ANY(v_page_ids);
  IF v_contacts IS NULL THEN
    v_contacts := '[]'::jsonb;
  END IF;

  IF cardinality(v_page_ids) > 0 THEN
    IF p_include_unanswered_status THEN
      SELECT s.id
      INTO v_latest_survey_id
      FROM public.surveys s
      WHERE s.status = 'active'
        AND s.archived = false
      ORDER BY s.id DESC
      LIMIT 1;

      IF v_latest_survey_id IS NOT NULL THEN
        SELECT jsonb_object_agg(sub.contact_id::text, sub.status) INTO v_unanswered
        FROM (
          SELECT DISTINCT ON (sr.contact_id)
            sr.contact_id,
            CASE
              WHEN sr.status = 'in_progress' THEN 'in_progress'
              WHEN sr.status = 'completed' THEN 'completed'
              ELSE 'not_started'
            END AS status
          FROM public.survey_responses sr
          WHERE sr.contact_id = ANY(v_page_ids)
            AND sr.survey_id = v_latest_survey_id
            AND sr.status IN ('in_progress', 'completed')
          ORDER BY sr.contact_id, sr.created_at DESC
        ) sub;
        IF v_unanswered IS NULL THEN
          v_unanswered := '{}'::jsonb;
        END IF;
        v_unanswered := (
          SELECT jsonb_object_agg(n::text, COALESCE(v_unanswered->>n::text, 'not_started'))
          FROM unnest(v_page_ids) n
        );
        IF v_unanswered IS NULL THEN
          v_unanswered := '{}'::jsonb;
        END IF;
      END IF;
    END IF;

    IF p_include_button_state THEN
      WITH colour_survey AS (
        SELECT
          s.id,
          COALESCE((s.settings->'buttonDisplay'->>'colour'), 'pink') AS colour
        FROM public.surveys s
        WHERE s.status = 'active'
          AND s.archived = false
          AND COALESCE((s.settings->'buttonDisplay'->>'coloursButton')::boolean, false) = true
        ORDER BY COALESCE((s.settings->'buttonDisplay'->>'priority')::int, 0), s.id
        LIMIT 1
      ),
      latest_survey AS (
        SELECT id
        FROM public.surveys
        WHERE status = 'active'
          AND archived = false
        ORDER BY id DESC
        LIMIT 1
      ),
      survey_to_use AS (
        SELECT id, colour FROM colour_survey
        UNION ALL
        SELECT l.id, 'pink'
        FROM latest_survey l
        WHERE NOT EXISTS (SELECT 1 FROM colour_survey)
      )
      SELECT
        (
          SELECT jsonb_object_agg(x.cid::text, y.colour)
          FROM (SELECT unnest(v_page_ids) AS cid) x,
               (SELECT colour FROM survey_to_use LIMIT 1) y
        ),
        (
          SELECT jsonb_object_agg(x.cid::text, y.id)
          FROM (SELECT unnest(v_page_ids) AS cid) x,
               (SELECT id FROM survey_to_use LIMIT 1) y
        )
      INTO v_button_colour, v_button_survey_id;

      IF v_button_colour IS NULL THEN
        v_button_colour := '{}'::jsonb;
      END IF;
      IF v_button_survey_id IS NULL THEN
        v_button_survey_id := '{}'::jsonb;
      END IF;
    END IF;

    IF p_include_pending_suggestions THEN
      SELECT jsonb_object_agg(entity_id::text, field_names) INTO v_pending_suggestions
      FROM (
        SELECT fs.entity_id, jsonb_agg(fs.field_name) AS field_names
        FROM public.field_suggestions fs
        WHERE fs.entity_type = 'contact'
          AND fs.entity_id = ANY(v_page_ids)
          AND fs.status = 'pending'
        GROUP BY fs.entity_id
      ) sub;
      IF v_pending_suggestions IS NULL THEN
        v_pending_suggestions := '{}'::jsonb;
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'contacts', v_contacts,
    'total_count', v_total_count,
    'unanswered_status', v_unanswered,
    'contact_survey_button_colour', v_button_colour,
    'contact_survey_button_survey_id', v_button_survey_id,
    'pending_suggestions_by_contact', v_pending_suggestions
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_page_payload_scoped(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_sort_rules jsonb,
  p_search_term text,
  p_page integer,
  p_page_size integer,
  p_include_unanswered_status boolean DEFAULT true,
  p_include_button_state boolean DEFAULT true,
  p_include_pending_suggestions boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  RETURN public.load_contact_dashboard_page_payload_optimized(
    p_scope_type,
    p_scope_values,
    p_profile_id,
    p_role,
    p_filter_group,
    p_sort_rules,
    p_search_term,
    p_page,
    p_page_size,
    p_include_unanswered_status,
    p_include_button_state,
    p_include_pending_suggestions
  );
END;
$$;

COMMENT ON FUNCTION public.load_contact_dashboard_page_payload_optimized(
  text, text[], text, text, jsonb, jsonb, text, integer, integer, boolean, boolean, boolean
) IS 'Optimized dashboard payload function using row-set filtering before candidate array materialization.';

