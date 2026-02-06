-- Create RPC function to efficiently get previous survey answers
-- This function performs the join in the database and returns answers grouped by question_id
-- It's optimized to limit responses first, then get all answers for those responses

-- Drop the function if it exists (in case of type changes)
DROP FUNCTION IF EXISTS get_survey_previous_answers(bigint, bigint, bigint, bigint[], integer);
DROP FUNCTION IF EXISTS get_survey_previous_answers(integer, integer, integer, integer[], integer);

CREATE OR REPLACE FUNCTION get_survey_previous_answers(
  p_contact_id bigint,
  p_survey_id bigint,
  p_exclude_response_id bigint DEFAULT NULL,
  p_question_ids bigint[] DEFAULT NULL,
  p_limit_responses integer DEFAULT 10
)
RETURNS TABLE (
  question_id bigint,
  response_id bigint,
  created_at timestamp with time zone,
  completed_at timestamp with time zone,
  answer_text text,
  answer_number numeric,
  answer_date date,
  answer_boolean boolean,
  answer_json jsonb
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  WITH recent_responses AS (
    -- First, get the N most recent completed responses
    SELECT 
      sr.id,
      sr.created_at,
      sr.completed_at
    FROM survey_responses sr
    WHERE sr.contact_id = p_contact_id
      AND sr.survey_id = p_survey_id
      AND sr.status = 'completed'
      AND (p_exclude_response_id IS NULL OR sr.id != p_exclude_response_id)
    ORDER BY sr.completed_at DESC NULLS LAST, sr.created_at DESC
    LIMIT p_limit_responses
  )
  -- Then, get all answers for those responses
  SELECT
    sra.question_id,
    rr.id as response_id,
    rr.created_at,
    rr.completed_at,
    sra.answer_text,
    sra.answer_number,
    sra.answer_date,
    sra.answer_boolean,
    sra.answer_json
  FROM recent_responses rr
  INNER JOIN survey_response_answers sra ON rr.id = sra.response_id
  WHERE p_question_ids IS NULL OR sra.question_id = ANY(p_question_ids)
  ORDER BY rr.completed_at DESC NULLS LAST, rr.created_at DESC, sra.question_id;
END;
$$;

-- Add comment explaining the function
COMMENT ON FUNCTION get_survey_previous_answers IS 'Efficiently retrieves previous survey answers for a contact and survey. Returns answers from the N most recent completed responses, optionally filtered by question IDs. Performs the join in the database for better performance.';

