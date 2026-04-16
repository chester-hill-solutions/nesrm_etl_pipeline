-- Survey completions heatmap (per sender profile).
-- Attribution: survey_instances.sent_by (profiles.id)
-- Timestamp: survey_responses.completed_at (fallback to updated_at, then created_at)

CREATE OR REPLACE FUNCTION "public"."get_survey_completions_heatmap_for_sender"(
  "p_sent_by" uuid,
  "p_days" int DEFAULT 365,
  "p_tz" text DEFAULT 'UTC'
)
RETURNS TABLE("date" date, "count_completed" bigint)
LANGUAGE "sql"
STABLE
AS $$
  WITH params AS (
    SELECT
      LEAST(GREATEST(COALESCE(p_days, 365), 1), 730) AS days,
      COALESCE(NULLIF(TRIM(p_tz), ''), 'UTC') AS tz,
      (NOW() AT TIME ZONE COALESCE(NULLIF(TRIM(p_tz), ''), 'UTC'))::date AS end_date
  ),
  bounds AS (
    SELECT
      end_date,
      (end_date - (days - 1))::date AS start_date,
      tz
    FROM params
  ),
  calendar_days AS (
    SELECT generate_series(bounds.start_date, bounds.end_date, interval '1 day')::date AS d
    FROM bounds
  ),
  counts AS (
    SELECT
      (COALESCE(sr.completed_at, sr.updated_at, sr.created_at) AT TIME ZONE bounds.tz)::date AS d,
      COUNT(*)::bigint AS count_completed
    FROM bounds
    INNER JOIN public.survey_instances si
      ON si.sent_by = p_sent_by
    INNER JOIN public.survey_responses sr
      ON sr.survey_instance_id = si.id
    WHERE sr.status = 'completed'
      AND (COALESCE(sr.completed_at, sr.updated_at, sr.created_at) AT TIME ZONE bounds.tz)::date
        BETWEEN bounds.start_date AND bounds.end_date
    GROUP BY 1
  )
  SELECT
    calendar_days.d AS date,
    COALESCE(counts.count_completed, 0)::bigint AS count_completed
  FROM calendar_days
  LEFT JOIN counts USING (d)
  ORDER BY calendar_days.d;
$$;

