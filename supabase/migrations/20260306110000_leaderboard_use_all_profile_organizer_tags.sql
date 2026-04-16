-- Organizer leaderboard + daily activity attribution should match the rest of the app:
-- a sender can belong to an organizer tag via either profiles.organizer_tag or
-- profile_organizer_tags.tag. Count survey activity for any sent_by profile that
-- resolves to the organizer tag shown on the contact.

CREATE OR REPLACE FUNCTION "public"."get_organizer_leaderboard_for_riding"(
  "p_riding" "text" DEFAULT NULL::"text",
  "p_sort_by" "text" DEFAULT 'count'::"text",
  "p_sort_order" "text" DEFAULT 'desc'::"text"
)
RETURNS TABLE("name" "text", "count" bigint, "surveys_started" bigint, "surveys_completed" bigint)
LANGUAGE "plpgsql"
STABLE
AS $$
BEGIN
  RETURN QUERY
  WITH contact_organizer_tags AS (
    SELECT c.id AS contact_id, trim(unnest(string_to_array(c.organizer, ','))) AS tag
    FROM public.contact c
    WHERE c.organizer IS NOT NULL
      AND c.organizer != ''
      AND (p_riding IS NULL OR c.division_electoral_district = p_riding)
  ),
  organizer_tags AS (
    SELECT tag
    FROM contact_organizer_tags
    WHERE tag != ''
  ),
  tag_counts AS (
    SELECT
      tag,
      LOWER(tag) AS tag_lower,
      count(*)::bigint AS variant_count
    FROM organizer_tags
    GROUP BY tag
  ),
  organizer_profile_tags AS (
    SELECT DISTINCT
      LOWER(source.tag) AS tag_lower,
      source.profile_id
    FROM (
      SELECT p.organizer_tag AS tag, p.id AS profile_id
      FROM public.profiles p
      WHERE p.organizer_tag IS NOT NULL
        AND p.organizer_tag != ''

      UNION ALL

      SELECT pot.tag, pot.profile_id
      FROM public.profile_organizer_tags pot
      WHERE pot.tag IS NOT NULL
        AND pot.tag != ''
    ) source
  ),
  response_by_tag AS (
    SELECT
      LOWER(cot.tag) AS tag_lower,
      count(*) FILTER (WHERE sr.status IN ('in_progress', 'completed'))::bigint AS started,
      count(*) FILTER (WHERE sr.status = 'completed')::bigint AS completed
    FROM contact_organizer_tags cot
    INNER JOIN organizer_profile_tags opt
      ON opt.tag_lower = LOWER(cot.tag)
    INNER JOIN public.survey_responses sr
      ON sr.contact_id = cot.contact_id
    INNER JOIN public.survey_instances si
      ON si.id = sr.survey_instance_id
     AND si.sent_by = opt.profile_id
    WHERE cot.tag != ''
    GROUP BY LOWER(cot.tag)
  ),
  proper_format_from_profiles AS (
    SELECT DISTINCT ON (LOWER(p.organizer_tag))
      LOWER(p.organizer_tag) AS tag_lower,
      CASE
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          UPPER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || '_' || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || '_' || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        ELSE
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
      END AS proper_name
    FROM public.profiles p
    WHERE p.organizer_tag IS NOT NULL
      AND p.organizer_tag != ''
      AND p.first_name IS NOT NULL
      AND p.surname IS NOT NULL
  ),
  most_common_casing AS (
    SELECT DISTINCT ON (tc.tag_lower)
      tc.tag_lower,
      tc.tag AS proper_name,
      tc.variant_count
    FROM tag_counts tc
    WHERE NOT EXISTS (
      SELECT 1 FROM proper_format_from_profiles pfp
      WHERE pfp.tag_lower = tc.tag_lower
    )
    ORDER BY tc.tag_lower, tc.variant_count DESC, tc.tag ASC
  ),
  all_proper_formats AS (
    SELECT tag_lower, proper_name FROM proper_format_from_profiles
    UNION
    SELECT tag_lower, proper_name FROM most_common_casing
  ),
  aggregated_counts AS (
    SELECT
      tag_lower,
      SUM(variant_count)::bigint AS total_count
    FROM tag_counts
    GROUP BY tag_lower
  ),
  leaderboard_rows AS (
    SELECT
      COALESCE(apf.proper_name, UPPER(SUBSTRING(ac.tag_lower, 1, 1)) || SUBSTRING(ac.tag_lower, 2)) AS row_name,
      ac.total_count AS row_count,
      COALESCE(rbt.started, 0)::bigint AS row_surveys_started,
      COALESCE(rbt.completed, 0)::bigint AS row_surveys_completed
    FROM aggregated_counts ac
    LEFT JOIN all_proper_formats apf ON ac.tag_lower = apf.tag_lower
    LEFT JOIN response_by_tag rbt ON ac.tag_lower = rbt.tag_lower
  )
  SELECT
    lr.row_name AS name,
    lr.row_count AS count,
    lr.row_surveys_started AS surveys_started,
    lr.row_surveys_completed AS surveys_completed
  FROM leaderboard_rows lr
  ORDER BY
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'name' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'asc' THEN lr.row_name END ASC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'name' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'desc' THEN lr.row_name END DESC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'count' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'asc' THEN lr.row_count END ASC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'count' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'desc' THEN lr.row_count END DESC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'surveys_started' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'asc' THEN lr.row_surveys_started END ASC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'surveys_started' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'desc' THEN lr.row_surveys_started END DESC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'surveys_completed' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'asc' THEN lr.row_surveys_completed END ASC,
    CASE WHEN LOWER(COALESCE(NULLIF(TRIM(p_sort_by), ''), 'count')) = 'surveys_completed' AND LOWER(COALESCE(NULLIF(TRIM(p_sort_order), ''), 'desc')) = 'desc' THEN lr.row_surveys_completed END DESC,
    lr.row_count DESC;
END;
$$;

CREATE OR REPLACE FUNCTION "public"."get_organizer_daily_activity_for_riding"(
  "p_riding" "text" DEFAULT NULL::"text",
  "p_start_date" "date" DEFAULT NULL::"date",
  "p_end_date" "date" DEFAULT NULL::"date"
)
RETURNS TABLE(
  "name" "text",
  "tag_lower" "text",
  "day" "date",
  "surveys_started" bigint,
  "surveys_completed" bigint
)
LANGUAGE "plpgsql"
STABLE
AS $$
DECLARE
  v_start_date date := COALESCE(p_start_date, (CURRENT_DATE - 83));
  v_end_date date := COALESCE(p_end_date, CURRENT_DATE);
BEGIN
  RETURN QUERY
  WITH contact_organizer_tags AS (
    SELECT
      c.id AS contact_id,
      trim(unnest(string_to_array(c.organizer, ','))) AS tag
    FROM public.contact c
    WHERE c.organizer IS NOT NULL
      AND c.organizer != ''
      AND (p_riding IS NULL OR c.division_electoral_district = p_riding)
  ),
  organizer_tags AS (
    SELECT tag
    FROM contact_organizer_tags
    WHERE tag != ''
  ),
  tag_counts AS (
    SELECT
      tag,
      LOWER(tag) AS tag_lower,
      count(*)::bigint AS variant_count
    FROM organizer_tags
    GROUP BY tag
  ),
  organizer_profile_tags AS (
    SELECT DISTINCT
      LOWER(source.tag) AS tag_lower,
      source.profile_id
    FROM (
      SELECT p.organizer_tag AS tag, p.id AS profile_id
      FROM public.profiles p
      WHERE p.organizer_tag IS NOT NULL
        AND p.organizer_tag != ''

      UNION ALL

      SELECT pot.tag, pot.profile_id
      FROM public.profile_organizer_tags pot
      WHERE pot.tag IS NOT NULL
        AND pot.tag != ''
    ) source
  ),
  proper_format_from_profiles AS (
    SELECT DISTINCT ON (LOWER(p.organizer_tag))
      LOWER(p.organizer_tag) AS tag_lower,
      CASE
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          UPPER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || '_' || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || '_' || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        ELSE
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
      END AS proper_name
    FROM public.profiles p
    WHERE p.organizer_tag IS NOT NULL
      AND p.organizer_tag != ''
      AND p.first_name IS NOT NULL
      AND p.surname IS NOT NULL
  ),
  most_common_casing AS (
    SELECT DISTINCT ON (tc.tag_lower)
      tc.tag_lower,
      tc.tag AS proper_name,
      tc.variant_count
    FROM tag_counts tc
    WHERE NOT EXISTS (
      SELECT 1 FROM proper_format_from_profiles pfp
      WHERE pfp.tag_lower = tc.tag_lower
    )
    ORDER BY tc.tag_lower, tc.variant_count DESC, tc.tag ASC
  ),
  all_proper_formats AS (
    SELECT pfp.tag_lower, pfp.proper_name FROM proper_format_from_profiles pfp
    UNION
    SELECT mcc.tag_lower, mcc.proper_name FROM most_common_casing mcc
  ),
  aggregated_counts AS (
    SELECT
      tc.tag_lower,
      SUM(tc.variant_count)::bigint AS total_count
    FROM tag_counts tc
    GROUP BY tc.tag_lower
  ),
  leaderboard_rows AS (
    SELECT
      ac.tag_lower,
      COALESCE(apf.proper_name, UPPER(SUBSTRING(ac.tag_lower, 1, 1)) || SUBSTRING(ac.tag_lower, 2)) AS row_name
    FROM aggregated_counts ac
    LEFT JOIN all_proper_formats apf ON ac.tag_lower = apf.tag_lower
  ),
  activity_by_tag_day AS (
    SELECT
      LOWER(cot.tag) AS tag_lower,
      (timezone('utc', COALESCE(sr.started_at, sr.created_at)))::date AS day,
      count(*) FILTER (WHERE sr.status IN ('in_progress', 'completed'))::bigint AS started,
      count(*) FILTER (WHERE sr.status = 'completed')::bigint AS completed
    FROM contact_organizer_tags cot
    INNER JOIN organizer_profile_tags opt
      ON opt.tag_lower = LOWER(cot.tag)
    INNER JOIN public.survey_responses sr
      ON sr.contact_id = cot.contact_id
    INNER JOIN public.survey_instances si
      ON si.id = sr.survey_instance_id
     AND si.sent_by = opt.profile_id
    WHERE cot.tag != ''
      AND sr.status IN ('in_progress', 'completed')
      AND (timezone('utc', COALESCE(sr.started_at, sr.created_at)))::date BETWEEN v_start_date AND v_end_date
    GROUP BY LOWER(cot.tag), (timezone('utc', COALESCE(sr.started_at, sr.created_at)))::date
  )
  SELECT
    lr.row_name AS name,
    lr.tag_lower,
    abd.day,
    abd.started AS surveys_started,
    abd.completed AS surveys_completed
  FROM activity_by_tag_day abd
  INNER JOIN leaderboard_rows lr
    ON lr.tag_lower = abd.tag_lower
  ORDER BY abd.day ASC, lr.row_name ASC;
END;
$$;
