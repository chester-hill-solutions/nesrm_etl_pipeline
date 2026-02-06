-- Enable Realtime publication for profiles table
-- This allows clients to subscribe to profile updates via Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS "public"."profiles";

COMMENT ON TABLE "public"."profiles" IS 'Profiles table is enabled for Realtime subscriptions. Clients can subscribe to INSERT/UPDATE/DELETE events, particularly for tracking last_seen_at changes for online status.';
