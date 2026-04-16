-- Segment dashboard: optional swipe-outcome hide filters on contact dashboard RPC.
-- Keeps pagination + total_count consistent with TS helpers in segment-swipe-match.server.ts.

CREATE OR REPLACE FUNCTION public.segment_swipe_stored_answer_matches_target(
  p_question_type text,
  p_raw text,
  p_answer_text text,
  p_answer_number numeric,
  p_answer_date date,
  p_answer_boolean boolean,
  p_answer_json jsonb
) RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_trim text := TRIM(COALESCE(p_raw, ''));
  v_lower text;
  v_num numeric;
  v_exp_json jsonb;
BEGIN
  IF p_question_type IN (
    'descriptive_text',
    'send_email',
    'send_sms',
    'event_rsvp',
    'ranking',
    'matrix',
    'file_upload'
  ) THEN
    RETURN false;
  END IF;

  IF p_question_type = 'boolean' THEN
    v_lower := lower(v_trim);
    IF v_lower NOT IN ('true', 'false') THEN
      RETURN false;
    END IF;
    RETURN p_answer_boolean IS NOT DISTINCT FROM (v_lower = 'true');
  END IF;

  IF p_question_type = 'number' THEN
    IF v_trim = '' THEN
      RETURN p_answer_number IS NULL AND p_answer_text IS NULL AND p_answer_json IS NULL;
    END IF;
    BEGIN
      v_num := v_trim::numeric;
      RETURN p_answer_number IS NOT DISTINCT FROM v_num;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN false;
    END;
  END IF;

  IF p_question_type = 'date' THEN
    IF v_trim = '' THEN
      RETURN p_answer_date IS NULL;
    END IF;
    BEGIN
      RETURN p_answer_date IS NOT DISTINCT FROM v_trim::date;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN false;
    END;
  END IF;

  IF p_question_type = 'contact_info' THEN
    IF v_trim = '' OR left(v_trim, 1) <> '{' THEN
      RETURN false;
    END IF;
    BEGIN
      v_exp_json := v_trim::jsonb;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN false;
    END;
    RETURN p_answer_json IS NOT NULL AND p_answer_json = v_exp_json;
  END IF;

  IF p_question_type IN ('checkbox', 'multi_select') THEN
    BEGIN
      IF v_trim <> '' AND left(v_trim, 1) = '[' THEN
        v_exp_json := v_trim::jsonb;
      ELSIF v_trim = '' THEN
        v_exp_json := '[]'::jsonb;
      ELSE
        SELECT COALESCE(
          jsonb_agg(to_jsonb(trim(x)) ORDER BY trim(x)),
          '[]'::jsonb
        )
        INTO v_exp_json
        FROM unnest(string_to_array(v_trim, ',')) AS t(x)
        WHERE trim(x) <> '';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN false;
    END;
    RETURN p_answer_json IS NOT NULL AND p_answer_json = v_exp_json;
  END IF;

  -- text, textarea, email, single_select, multiple_choice, etc.
  RETURN COALESCE(p_answer_text, '') = COALESCE(nullif(v_trim, ''), '');
END;
$$;

CREATE OR REPLACE FUNCTION public.segment_swipe_direction_matches(
  p_contact_id bigint,
  p_survey_id integer,
  p_actions jsonb
) RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actions jsonb;
  v_resp_id bigint;
  v_ch text;
  v_disp text;
  elem jsonb;
  v_has_disposition boolean := false;
  v_expect_ch text;
  v_expect_disp text;
  v_qid bigint;
  v_qtype text;
  v_raw text;
  v_ans RECORD;
  v_idx integer;
  v_n integer;
BEGIN
  IF p_actions IS NULL
    OR jsonb_typeof(p_actions) = 'null'
    OR (jsonb_typeof(p_actions) = 'array' AND jsonb_array_length(p_actions) = 0) THEN
    RETURN false;
  END IF;

  v_actions :=
    CASE
      WHEN jsonb_typeof(p_actions) = 'array' THEN p_actions
      ELSE jsonb_build_array(p_actions)
    END;

  SELECT sr.id, sr.channel::text, sr.disposition::text
  INTO v_resp_id, v_ch, v_disp
  FROM public.survey_responses sr
  WHERE sr.contact_id = p_contact_id
    AND sr.survey_id = p_survey_id
    AND sr.status IN ('in_progress', 'completed')
  ORDER BY sr.created_at DESC, sr.id DESC
  LIMIT 1;

  IF v_resp_id IS NULL THEN
    RETURN false;
  END IF;

  v_n := COALESCE(jsonb_array_length(v_actions), 0);
  FOR v_idx IN 0..v_n - 1
  LOOP
    elem := v_actions->v_idx;
    IF elem->>'kind' = 'disposition' THEN
      v_has_disposition := true;
      v_expect_ch := elem->>'channel';
      v_expect_disp := elem->>'value';
    END IF;
  END LOOP;

  IF v_has_disposition THEN
    IF v_ch IS DISTINCT FROM v_expect_ch OR COALESCE(v_disp, '') IS DISTINCT FROM COALESCE(v_expect_disp, '') THEN
      RETURN false;
    END IF;
  END IF;

  FOR v_idx IN 0..v_n - 1
  LOOP
    elem := v_actions->v_idx;
    IF elem->>'kind' <> 'answer' THEN
      CONTINUE;
    END IF;

    v_qid := COALESCE(
      NULLIF(elem->>'questionId', '')::bigint,
      NULLIF(elem->>'question_id', '')::bigint
    );
    IF v_qid IS NULL THEN
      RETURN false;
    END IF;

    SELECT sq.question_type::text
    INTO v_qtype
    FROM public.survey_questions sq
    WHERE sq.id = v_qid
      AND COALESCE(sq.archived, false) = false
    LIMIT 1;

    IF v_qtype IS NULL THEN
      RETURN false;
    END IF;

    v_raw := COALESCE(elem->>'value', '');

    SELECT
      sra.answer_text,
      sra.answer_number,
      sra.answer_date,
      sra.answer_boolean,
      sra.answer_json
    INTO v_ans
    FROM public.survey_response_answers sra
    WHERE sra.response_id = v_resp_id
      AND sra.question_id = v_qid
    LIMIT 1;

    IF NOT FOUND THEN
      RETURN false;
    END IF;

    IF NOT public.segment_swipe_stored_answer_matches_target(
      v_qtype,
      v_raw,
      v_ans.answer_text,
      v_ans.answer_number,
      v_ans.answer_date,
      v_ans.answer_boolean,
      v_ans.answer_json
    ) THEN
      RETURN false;
    END IF;
  END LOOP;

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.segment_swipe_contact_bucket(
  p_contact_id bigint,
  p_survey_id integer,
  p_left_actions jsonb,
  p_right_actions jsonb
) RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.segment_swipe_direction_matches(p_contact_id, p_survey_id, p_left_actions) THEN
    RETURN 'left';
  END IF;
  IF public.segment_swipe_direction_matches(p_contact_id, p_survey_id, p_right_actions) THEN
    RETURN 'right';
  END IF;
  RETURN 'none';
END;
$$;

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
  p_include_pending_suggestions boolean DEFAULT true,
  p_group_by_household boolean DEFAULT false,
  p_segment_swipe_assigned_survey_id integer DEFAULT NULL,
  p_segment_swipe_left_actions jsonb DEFAULT NULL,
  p_segment_swipe_right_actions jsonb DEFAULT NULL,
  p_segment_swipe_hide jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
VOLATILE
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
  v_t_dash_ord text;
  v_household_peers jsonb := '{}'::jsonb;
  v_cohort_lim integer;
  v_swipe_active boolean;
BEGIN
  v_page_num := GREATEST(COALESCE(p_page, 1), 1);
  v_limit := GREATEST(COALESCE(p_page_size, 25), 1);
  v_has_filter :=
    p_filter_group IS NOT NULL
    AND jsonb_typeof(p_filter_group) = 'object'
    AND (p_filter_group->'children') IS NOT NULL
    AND jsonb_array_length(p_filter_group->'children') > 0;

  v_swipe_active :=
    p_segment_swipe_assigned_survey_id IS NOT NULL
    AND p_segment_swipe_hide IS NOT NULL
    AND jsonb_typeof(p_segment_swipe_hide) = 'object'
    AND (
      COALESCE((p_segment_swipe_hide->>'hideLeftMatched')::boolean, false)
      OR COALESCE((p_segment_swipe_hide->>'hideRightMatched')::boolean, false)
      OR COALESCE((p_segment_swipe_hide->>'hideNoneMatched')::boolean, false)
    );

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
  swipe_filtered_ids AS (
    SELECT s.id
    FROM searched_ids s
    WHERE NOT v_swipe_active
      OR NOT (
        CASE public.segment_swipe_contact_bucket(
          s.id,
          p_segment_swipe_assigned_survey_id,
          COALESCE(p_segment_swipe_left_actions, '[]'::jsonb),
          COALESCE(p_segment_swipe_right_actions, '[]'::jsonb)
        )
          WHEN 'left' THEN COALESCE((p_segment_swipe_hide->>'hideLeftMatched')::boolean, false)
          WHEN 'right' THEN COALESCE((p_segment_swipe_hide->>'hideRightMatched')::boolean, false)
          WHEN 'none' THEN COALESCE((p_segment_swipe_hide->>'hideNoneMatched')::boolean, false)
          ELSE false
        END
      )
  ),
  total_count AS (
    SELECT COUNT(*)::bigint AS count
    FROM swipe_filtered_ids
  ),
  limited_ids AS (
    SELECT s.id
    FROM swipe_filtered_ids s
    ORDER BY s.id
    LIMIT 10000
  )
  SELECT
    (SELECT array_agg(id ORDER BY id) FROM limited_ids),
    (SELECT count FROM total_count)
  INTO v_candidate_ids, v_total_count;

  IF v_total_count IS NULL THEN
    v_total_count := 0;
  END IF;

  IF v_candidate_ids IS NULL OR cardinality(v_candidate_ids) = 0 THEN
    RETURN jsonb_build_object(
      'contacts', '[]'::jsonb,
      'total_count', v_total_count,
      'unanswered_status', v_unanswered,
      'contact_survey_button_colour', v_button_colour,
      'contact_survey_button_survey_id', v_button_survey_id,
      'pending_suggestions_by_contact', v_pending_suggestions,
      'household_peers_by_contact_id', '{}'::jsonb
    );
  END IF;

  v_t_dash_ord := 'dash_ord_' || replace(gen_random_uuid()::text, '-', '_');
  EXECUTE format(
    'CREATE TEMP TABLE %I ON COMMIT DROP AS '
    'SELECT o.contact_id, o.household_group_id, row_number() OVER () AS rn '
    'FROM public.load_contact_list_page_ids($1, $2, $3, $4, $5, $6) o',
    v_t_dash_ord
  ) USING v_candidate_ids, COALESCE(p_sort_rules, '[]'::jsonb), v_page_num, v_limit, p_role, COALESCE(p_group_by_household, false);

  EXECUTE format(
    'SELECT COALESCE(array_agg(contact_id ORDER BY rn), ARRAY[]::bigint[]) FROM %I',
    v_t_dash_ord
  ) INTO v_page_ids;

  IF v_page_ids IS NULL THEN
    v_page_ids := ARRAY[]::bigint[];
  END IF;

  EXECUTE format(
    'SELECT COALESCE('
    'jsonb_agg('
    '(row_to_json(c)::jsonb) '
    '|| CASE '
    'WHEN p.household_group_id IS NULL THEN ''{}''::jsonb '
    'ELSE jsonb_build_object(''household_group_id'', to_jsonb(p.household_group_id)) '
    'END '
    'ORDER BY p.rn'
    '), ''[]''::jsonb) '
    'FROM %I p JOIN public.contact c ON c.id = p.contact_id',
    v_t_dash_ord
  ) INTO v_contacts;
  IF v_contacts IS NULL THEN
    v_contacts := '[]'::jsonb;
  END IF;

  IF COALESCE(p_group_by_household, false) THEN
    v_cohort_lim := GREATEST(cardinality(v_candidate_ids), 1);
    SELECT COALESCE(
      (
        WITH cohort AS (
          SELECT h.contact_id, h.household_group_id
          FROM public.load_contact_list_page_ids(
            v_candidate_ids,
            COALESCE(p_sort_rules, '[]'::jsonb),
            1,
            v_cohort_lim,
            p_role,
            true
          ) AS h(contact_id, total_count, household_group_id)
        ),
        grp AS (
          SELECT household_group_id, array_agg(contact_id ORDER BY contact_id) AS member_ids
          FROM cohort
          WHERE household_group_id IS NOT NULL
          GROUP BY household_group_id
        ),
        per_contact AS (
          SELECT
            c.contact_id,
            CASE
              WHEN c.household_group_id IS NULL THEN ARRAY[]::bigint[]
              ELSE ARRAY(
                SELECT u
                FROM unnest(g.member_ids) AS u
                WHERE u <> c.contact_id
                ORDER BY 1
              )
            END AS peer_ids
          FROM cohort c
          LEFT JOIN grp g ON g.household_group_id = c.household_group_id
        )
        SELECT jsonb_object_agg(
          pc.contact_id::text,
          jsonb_build_object(
            'peer_contact_ids', to_jsonb(pc.peer_ids),
            'peers', COALESCE(
              (
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id', ct.id,
                    'firstname', ct.firstname,
                    'surname', ct.surname
                  )
                  ORDER BY ct.id
                )
                FROM unnest(pc.peer_ids) AS p(peer_id)
                JOIN public.contact ct ON ct.id = p.peer_id
              ),
              '[]'::jsonb
            )
          )
        )
        FROM per_contact pc
      ),
      '{}'::jsonb
    )
    INTO v_household_peers;
  ELSE
    v_household_peers := '{}'::jsonb;
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
    'pending_suggestions_by_contact', v_pending_suggestions,
    'household_peers_by_contact_id', v_household_peers
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
  p_include_pending_suggestions boolean DEFAULT true,
  p_group_by_household boolean DEFAULT false,
  p_segment_swipe_assigned_survey_id integer DEFAULT NULL,
  p_segment_swipe_left_actions jsonb DEFAULT NULL,
  p_segment_swipe_right_actions jsonb DEFAULT NULL,
  p_segment_swipe_hide jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
VOLATILE
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
    p_include_pending_suggestions,
    p_group_by_household,
    p_segment_swipe_assigned_survey_id,
    p_segment_swipe_left_actions,
    p_segment_swipe_right_actions,
    p_segment_swipe_hide
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_page_payload(
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
  p_include_pending_suggestions boolean DEFAULT true,
  p_group_by_household boolean DEFAULT false,
  p_segment_swipe_assigned_survey_id integer DEFAULT NULL,
  p_segment_swipe_left_actions jsonb DEFAULT NULL,
  p_segment_swipe_right_actions jsonb DEFAULT NULL,
  p_segment_swipe_hide jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
VOLATILE
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
    p_include_pending_suggestions,
    p_group_by_household,
    p_segment_swipe_assigned_survey_id,
    p_segment_swipe_left_actions,
    p_segment_swipe_right_actions,
    p_segment_swipe_hide
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_table_page(
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
  p_include_pending_suggestions boolean DEFAULT true,
  p_group_by_household boolean DEFAULT false,
  p_segment_swipe_assigned_survey_id integer DEFAULT NULL,
  p_segment_swipe_left_actions jsonb DEFAULT NULL,
  p_segment_swipe_right_actions jsonb DEFAULT NULL,
  p_segment_swipe_hide jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
VOLATILE
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
    p_include_pending_suggestions,
    p_group_by_household,
    p_segment_swipe_assigned_survey_id,
    p_segment_swipe_left_actions,
    p_segment_swipe_right_actions,
    p_segment_swipe_hide
  );
END;
$$;
