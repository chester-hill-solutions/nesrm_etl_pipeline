-- Increase statement_timeout for roles that run heavy queries (e.g. loadContactsWithCustomFields).
-- Supabase defaults: anon 3s, authenticated 8s; heavy contact list queries can exceed 8s.
-- This gives the contacts query and similar loaders more time before 57014 (statement timeout).

ALTER ROLE "authenticated" SET statement_timeout = '30s';
ALTER ROLE "service_role" SET statement_timeout = '30s';

-- Reload PostgREST so it picks up role config changes (if using API through PostgREST).
NOTIFY pgrst, 'reload config';
