-- Enable postgres_changes for contact table survey button state (responses + answers).
-- Idempotent: remote may already include these tables in supabase_realtime.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'survey_responses'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.survey_responses;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'survey_response_answers'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.survey_response_answers;
  END IF;
END $$;
