-- Contact submission confirmation + women's club fields
ALTER TABLE "public"."contact"
    ADD COLUMN IF NOT EXISTS "submission_confirmed" boolean DEFAULT false;

ALTER TABLE "public"."contact"
    ADD COLUMN IF NOT EXISTS "womens_club" text;

COMMENT ON COLUMN "public"."contact"."submission_confirmed" IS 'Whether the contact submission has been confirmed.';
COMMENT ON COLUMN "public"."contact"."womens_club" IS 'Optional women''s club affiliation or note for the contact.';
