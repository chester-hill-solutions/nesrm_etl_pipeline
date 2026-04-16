-- Ensure captain columns reference profiles.id (uuid) with safe, idempotent guards

-- 1) division_electoral_olp_region.captain → uuid + FK to profiles
DO $$
BEGIN
  -- Add column if it somehow does not exist (defensive; should already exist)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'division_electoral_olp_region'
      AND column_name = 'captain'
  ) THEN
    ALTER TABLE public.division_electoral_olp_region
      ADD COLUMN captain uuid;
  END IF;

  -- Cast to uuid if not already
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'division_electoral_olp_region'
      AND column_name = 'captain'
      AND data_type <> 'uuid'
  ) THEN
    ALTER TABLE public.division_electoral_olp_region
      ALTER COLUMN captain TYPE uuid USING captain::uuid;
  END IF;

  -- Add FK if missing
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'division_electoral_olp_region_captain_fkey'
      AND conrelid = 'public.division_electoral_olp_region'::regclass
  ) THEN
    ALTER TABLE public.division_electoral_olp_region
      ADD CONSTRAINT division_electoral_olp_region_captain_fkey
      FOREIGN KEY (captain) REFERENCES public.profiles(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- 2) division_electoral_district.captain → uuid + FK to profiles
DO $$
BEGIN
  -- Add column if it somehow does not exist (defensive; should already exist)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'division_electoral_district'
      AND column_name = 'captain'
  ) THEN
    ALTER TABLE public.division_electoral_district
      ADD COLUMN captain uuid;
  END IF;

  -- Cast to uuid if not already
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'division_electoral_district'
      AND column_name = 'captain'
      AND data_type <> 'uuid'
  ) THEN
    ALTER TABLE public.division_electoral_district
      ALTER COLUMN captain TYPE uuid USING captain::uuid;
  END IF;

  -- Add FK if missing
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'division_electoral_district_captain_fkey'
      AND conrelid = 'public.division_electoral_district'::regclass
  ) THEN
    ALTER TABLE public.division_electoral_district
      ADD CONSTRAINT division_electoral_district_captain_fkey
      FOREIGN KEY (captain) REFERENCES public.profiles(id)
      ON DELETE SET NULL;
  END IF;
END $$;
