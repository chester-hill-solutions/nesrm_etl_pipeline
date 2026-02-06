-- Add channel column to survey_responses table
ALTER TABLE public.survey_responses
  ADD COLUMN channel text NOT NULL DEFAULT 'email';

-- Add CHECK constraint for channel values
ALTER TABLE public.survey_responses
  ADD CONSTRAINT survey_responses_channel_check
  CHECK (channel IN ('email', 'phone', 'canvass', 'event'));

-- Add index for channel column for filtering/querying
CREATE INDEX IF NOT EXISTS survey_responses_channel_idx ON public.survey_responses(channel);

