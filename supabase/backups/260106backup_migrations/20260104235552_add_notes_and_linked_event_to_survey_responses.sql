-- Add notes and linked_event columns to survey_responses table
ALTER TABLE public.survey_responses
  ADD COLUMN notes text,
  ADD COLUMN linked_event text;

