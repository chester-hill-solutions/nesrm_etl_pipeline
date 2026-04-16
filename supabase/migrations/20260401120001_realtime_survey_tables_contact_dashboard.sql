-- Enable postgres_changes for contact table survey button state (responses + answers).
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY "public"."survey_responses";
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY "public"."survey_response_answers";
