-- 1. Create table (idempotent)
CREATE TABLE IF NOT EXISTS public.division_electoral_olp_region (
  name TEXT PRIMARY KEY,
  captain TEXT
);

-- 2. Seed moved to seed file 20260213195539_modify_riding_schema.sql

-- 2b. Add captain column to districts (idempotent)
ALTER TABLE public.division_electoral_district
ADD COLUMN IF NOT EXISTS captain TEXT;

-- 3. Add FK constraint (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_division_region'
      AND conrelid = 'public.division_electoral_district'::regclass
  ) THEN
    ALTER TABLE public.division_electoral_district
    ADD CONSTRAINT fk_division_region
    FOREIGN KEY (olp_region)
    REFERENCES public.division_electoral_olp_region(name);
  END IF;
END $$;
