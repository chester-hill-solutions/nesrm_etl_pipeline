-- Update organizer leaderboard function to group case-insensitively
-- and return the proper casing format (FirstLast, FLast, etc.) for each organizer tag
-- Preserves the tag pattern while applying proper capitalization

CREATE OR REPLACE FUNCTION "public"."get_organizer_leaderboard"() RETURNS TABLE("name" "text", "count" bigint)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  WITH organizer_tags AS (
    SELECT trim(unnest(string_to_array(organizer, ','))) as tag
    FROM public.contact
    WHERE organizer IS NOT NULL 
      AND organizer != ''
  ),
  tag_counts AS (
    SELECT 
      tag,
      LOWER(tag) as tag_lower,
      count(*)::bigint as variant_count
    FROM organizer_tags
    WHERE tag != ''
    GROUP BY tag
  ),
  -- Try to find proper format from profiles table
  -- Match the tag pattern (FirstLast, FLast, etc.) and rebuild with proper casing
  proper_format_from_profiles AS (
    SELECT DISTINCT ON (LOWER(p.organizer_tag))
      LOWER(p.organizer_tag) as tag_lower,
      -- Rebuild tag matching the original pattern but with proper casing
      -- Extract normalized first name and surname parts
      CASE 
        -- Match FirstLast pattern: tag matches firstname + surname
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match FLast pattern: tag starts with first letter of firstname
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          UPPER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match First2Last pattern: tag starts with first 2 letters
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match First3Last pattern: tag starts with first 3 letters
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match First_Last pattern with underscore
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || '_' || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || '_' || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Default: use FirstLast format
        ELSE
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
      END as proper_name
    FROM public.profiles p
    WHERE p.organizer_tag IS NOT NULL 
      AND p.organizer_tag != ''
      AND p.first_name IS NOT NULL
      AND p.surname IS NOT NULL
  ),
  -- For tags not found in profiles, use the most common casing variant
  -- This is likely to be the correct format since it appears most frequently
  most_common_casing AS (
    SELECT DISTINCT ON (tc.tag_lower)
      tc.tag_lower,
      tc.tag as proper_name,
      tc.variant_count
    FROM tag_counts tc
    WHERE NOT EXISTS (
      SELECT 1 FROM proper_format_from_profiles pfp 
      WHERE pfp.tag_lower = tc.tag_lower
    )
    ORDER BY tc.tag_lower, tc.variant_count DESC, tc.tag ASC
  ),
  -- Combine proper formats from profiles and most common casing
  all_proper_formats AS (
    SELECT tag_lower, proper_name FROM proper_format_from_profiles
    UNION
    SELECT tag_lower, proper_name FROM most_common_casing
  ),
  aggregated_counts AS (
    SELECT 
      tag_lower,
      SUM(variant_count)::bigint as total_count
    FROM tag_counts
    GROUP BY tag_lower
  )
  SELECT 
    COALESCE(apf.proper_name, UPPER(SUBSTRING(ac.tag_lower, 1, 1)) || SUBSTRING(ac.tag_lower, 2)) as name,
    ac.total_count as count
  FROM aggregated_counts ac
  LEFT JOIN all_proper_formats apf ON ac.tag_lower = apf.tag_lower
  ORDER BY ac.total_count DESC;
END;
$$;
