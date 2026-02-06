-- Migration: Set correct field types for enum/foreign key columns
-- This ensures columns like division_electoral_district, campus_club, and research_status
-- have the correct data_type ('select') and options populated in column_visibility table

-- Update division_electoral_district to be a select type with options from division_electoral_district table
UPDATE "public"."column_visibility"
SET 
  "data_type" = 'select',
  "options" = (
    SELECT json_agg("name" ORDER BY "name")::jsonb
    FROM "public"."division_electoral_district"
  )
WHERE "column_name" = 'division_electoral_district'
  AND ("data_type" IS NULL OR "data_type" != 'select' OR "options" IS NULL);

-- Update campus_club to be a select type with hardcoded options
-- Note: campus_club values come from a hardcoded list in the application
UPDATE "public"."column_visibility"
SET 
  "data_type" = 'select',
  "options" = '[
    "Algoma University",
    "Brock University",
    "Carleton University",
    "Humber Polytechnic",
    "Lakehead University",
    "Laurentian University",
    "McMaster University",
    "Nipissing University",
    "Queen''s University",
    "Toronto Metropolitan University",
    "Trent University",
    "University of Guelph",
    "University of Ottawa",
    "University of Toronto (Downtown Toronto Campus)",
    "University of Toronto (Mississauga Campus)",
    "University of Toronto (Scarborough Campus)",
    "University of Waterloo",
    "University of Windsor",
    "Western University",
    "Wilfrid Laurier University",
    "York University"
  ]'::jsonb
WHERE "column_name" = 'campus_club'
  AND ("data_type" IS NULL OR "data_type" != 'select' OR "options" IS NULL);

-- Update research_status to be a select type with enum values
UPDATE "public"."column_visibility"
SET 
  "data_type" = 'select',
  "options" = '["pending", "completed", "failed"]'::jsonb
WHERE "column_name" = 'research_status'
  AND ("data_type" IS NULL OR "data_type" != 'select' OR "options" IS NULL);
