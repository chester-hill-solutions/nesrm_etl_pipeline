-- Add target_2023 column to division_electoral_district
ALTER TABLE public.division_electoral_district
ADD COLUMN IF NOT EXISTS target_2023 numeric;
