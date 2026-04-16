-- Add contact_info question type so "Contact info" can be used as a block in the survey structure.
ALTER TABLE "public"."survey_questions"
  DROP CONSTRAINT IF EXISTS "survey_questions_question_type_check";

ALTER TABLE "public"."survey_questions"
  ADD CONSTRAINT "survey_questions_question_type_check" CHECK (
    "question_type" = ANY (ARRAY[
      'text'::text,
      'textarea'::text,
      'contact_info'::text,
      'multiple_choice'::text,
      'checkbox'::text,
      'multi_select'::text,
      'boolean'::text,
      'number'::text,
      'date'::text,
      'email'::text,
      'descriptive_text'::text,
      'send_email'::text,
      'send_sms'::text,
      'event_rsvp'::text
    ])
  );

