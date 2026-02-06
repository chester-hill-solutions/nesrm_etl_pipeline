-- Add last_seen_at column to profiles table for tracking when users were last active
ALTER TABLE "public"."profiles" 
ADD COLUMN IF NOT EXISTS "last_seen_at" timestamp with time zone NULL;

COMMENT ON COLUMN "public"."profiles"."last_seen_at" IS 'Timestamp of when the user was last seen online (last authenticated request). Updated periodically to avoid excessive database writes.';

-- Create index for efficient queries on last_seen_at
CREATE INDEX IF NOT EXISTS "profiles_last_seen_at_idx" ON "public"."profiles" USING "btree" ("last_seen_at");
