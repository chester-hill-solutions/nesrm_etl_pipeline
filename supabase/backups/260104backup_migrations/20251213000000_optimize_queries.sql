-- Optimize queries: Add SQL function for organizer leaderboard and indexes

-- Create function to efficiently count organizer tags using SQL aggregation
CREATE OR REPLACE FUNCTION public.get_organizer_leaderboard()
RETURNS TABLE(name text, count bigint)
LANGUAGE sql
STABLE
AS $$
  WITH organizer_tags AS (
    SELECT trim(unnest(string_to_array(organizer, ','))) as tag
    FROM public.contact
    WHERE organizer IS NOT NULL 
      AND organizer != ''
  )
  SELECT 
    tag as name,
    count(*)::bigint as count
  FROM organizer_tags
  WHERE tag != ''
  GROUP BY tag
  ORDER BY count DESC;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_organizer_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_organizer_leaderboard() TO anon;
GRANT EXECUTE ON FUNCTION public.get_organizer_leaderboard() TO service_role;

-- Add indexes for commonly filtered columns to improve query performance
CREATE INDEX IF NOT EXISTS contact_division_electoral_district_idx 
  ON public.contact(division_electoral_district) 
  WHERE division_electoral_district IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_organizer_idx 
  ON public.contact(organizer) 
  WHERE organizer IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_email_idx 
  ON public.contact(email) 
  WHERE email IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_firstname_idx 
  ON public.contact(firstname) 
  WHERE firstname IS NOT NULL;

CREATE INDEX IF NOT EXISTS contact_surname_idx 
  ON public.contact(surname) 
  WHERE surname IS NOT NULL;

-- Composite index for name searches (firstname + surname)
CREATE INDEX IF NOT EXISTS contact_name_search_idx 
  ON public.contact(firstname, surname) 
  WHERE firstname IS NOT NULL OR surname IS NOT NULL;

-- Index for campus_club if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'contact' AND column_name = 'campus_club'
  ) THEN
    CREATE INDEX IF NOT EXISTS contact_campus_club_idx 
      ON public.contact(campus_club) 
      WHERE campus_club IS NOT NULL;
  END IF;
END $$;

