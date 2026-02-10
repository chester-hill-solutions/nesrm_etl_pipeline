-- Add multi_select and boolean question types to survey_questions check constraint
-- Also add descriptive_text which was missing from the constraint

ALTER TABLE survey_questions
DROP CONSTRAINT IF EXISTS survey_questions_question_type_check;

ALTER TABLE survey_questions
ADD CONSTRAINT survey_questions_question_type_check 
CHECK (question_type = ANY (ARRAY[
  'text'::text,
  'textarea'::text,
  'multiple_choice'::text,
  'checkbox'::text,
  'multi_select'::text,
  'boolean'::text,
  'number'::text,
  'date'::text,
  'email'::text,
  'descriptive_text'::text
]));
