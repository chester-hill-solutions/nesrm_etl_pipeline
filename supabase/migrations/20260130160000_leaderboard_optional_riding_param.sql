-- Organizer leaderboard: add survey counts and optional riding filter (no breaking changes).
-- get_organizer_leaderboard(p_riding text DEFAULT NULL):
--   Returns name, count, surveys_started, surveys_completed.
--   When p_riding is NULL, all contacts; when set, only contacts with division_electoral_district = p_riding.
-- Surveys started = survey_responses with status in ('in_progress','completed').
-- Surveys completed = survey_responses with status = 'completed'.

CREATE OR REPLACE FUNCTION "public"."get_organizer_leaderboard"("p_riding" "text" DEFAULT NULL::"text")
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
  response_by_tag AS (
    SELECT
      LOWER(cot.tag) AS tag_lower,
      count(*) FILTER (WHERE sr.status IN ('in_progress', 'completed'))::bigint AS started,
      count(*) FILTER (WHERE sr.status = 'completed')::bigint AS completed
    FROM contact_organizer_tags cot
    INNER JOIN public.survey_responses sr ON sr.contact_id = cot.contact_id
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
  )
  SELECT
    COALESCE(apf.proper_name, UPPER(SUBSTRING(ac.tag_lower, 1, 1)) || SUBSTRING(ac.tag_lower, 2)) AS name,
    ac.total_count AS count,
    COALESCE(rbt.started, 0)::bigint AS surveys_started,
    COALESCE(rbt.completed, 0)::bigint AS surveys_completed
  FROM aggregated_counts ac
  LEFT JOIN all_proper_formats apf ON ac.tag_lower = apf.tag_lower
  LEFT JOIN response_by_tag rbt ON ac.tag_lower = rbt.tag_lower
  ORDER BY ac.total_count DESC;
END;
$$;

ALTER FUNCTION "public"."get_organizer_leaderboard"("p_riding" "text") OWNER TO "postgres";
