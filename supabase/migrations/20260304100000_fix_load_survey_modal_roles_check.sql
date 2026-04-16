-- Fix load_survey_modal_surveys role visibility check for jsonb arrays.
-- visible_to_roles is jsonb, so cardinality(...) is invalid.

CREATE OR REPLACE FUNCTION public.load_survey_modal_surveys(
  p_contact_id bigint,
  p_role text,
  p_scoped_survey_id integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_surveys jsonb := '[]'::jsonb;
BEGIN
  IF p_contact_id IS NULL OR p_contact_id <= 0 THEN
    RETURN jsonb_build_object('surveys', '[]'::jsonb);
  END IF;

  WITH candidate_surveys AS (
    SELECT s.*
    FROM public.surveys s
    WHERE s.status = 'active'
      AND s.archived = false
      AND (p_scoped_survey_id IS NULL OR s.id = p_scoped_survey_id)
      AND (
        s.visible_to_roles IS NULL
        OR (jsonb_typeof(s.visible_to_roles) = 'array' AND jsonb_array_length(s.visible_to_roles) = 0)
        OR p_role = ANY(
          ARRAY(
            SELECT jsonb_array_elements_text(COALESCE(s.visible_to_roles, '[]'::jsonb))
          )
        )
      )
  ),
  latest AS (
    SELECT DISTINCT ON (sr.survey_id)
      sr.survey_id,
      sr.status
    FROM public.survey_responses sr
    JOIN candidate_surveys cs ON cs.id = sr.survey_id
    WHERE sr.contact_id = p_contact_id
      AND sr.status IN ('in_progress', 'completed')
    ORDER BY sr.survey_id, sr.created_at DESC, sr.id DESC
  )
  SELECT COALESCE(
    jsonb_agg(
      to_jsonb(cs)
      || jsonb_build_object(
        'has_in_progress_response',
        COALESCE((l.status = 'in_progress'), false)
      )
      ORDER BY cs.created_at DESC, cs.id DESC
    ),
    '[]'::jsonb
  )
  INTO v_surveys
  FROM candidate_surveys cs
  LEFT JOIN latest l ON l.survey_id = cs.id;

  RETURN jsonb_build_object('surveys', v_surveys);
END;
$$;

