-- Add send_sms question type so "Send SMS" is a block in the survey structure.
ALTER TABLE "public"."survey_questions"
  DROP CONSTRAINT IF EXISTS "survey_questions_question_type_check";

ALTER TABLE "public"."survey_questions"
  ADD CONSTRAINT "survey_questions_question_type_check" CHECK (
    "question_type" = ANY (ARRAY[
      'text'::text, 'textarea'::text, 'multiple_choice'::text, 'checkbox'::text,
      'multi_select'::text, 'boolean'::text, 'number'::text, 'date'::text,
      'email'::text, 'descriptive_text'::text, 'send_email'::text, 'send_sms'::text
    ])
  );

COMMENT ON COLUMN "public"."survey_questions"."validation_config" IS 'Type-specific config. For send_email: { "templateId": number } for respondent email template. For send_sms: optional { "defaultMessage": string } for prefill.';
