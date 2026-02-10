-- Deduplicate survey responses: keep only one response per survey_instance_id
-- Priority: 1) Completed responses, 2) Most recently updated, 3) Most recently created

-- Find all responses that should be kept (one per survey_instance_id)
WITH ranked_responses AS (
  SELECT 
    id,
    survey_instance_id,
    ROW_NUMBER() OVER (
      PARTITION BY survey_instance_id 
      ORDER BY 
        CASE WHEN status = 'completed' THEN 0 ELSE 1 END,  -- Completed first
        updated_at DESC,  -- Then most recently updated
        created_at DESC   -- Then most recently created
    ) as rn
  FROM public.survey_responses
),
responses_to_delete AS (
  SELECT id
  FROM ranked_responses
  WHERE rn > 1
)
-- Delete duplicate responses (keeping the best one for each instance)
DELETE FROM public.survey_responses
WHERE id IN (SELECT id FROM responses_to_delete);

-- Log the number of duplicates removed (this will be visible in migration logs)
-- Note: The actual count is handled by the DELETE statement above
