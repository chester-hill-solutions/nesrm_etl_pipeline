-- Ensure Division Electoral District displays as Riding
UPDATE public.column_visibility
SET column_label = 'Riding', updated_at = now()
WHERE column_name = 'division_electoral_district';

-- Seed the row if it is missing (for fresh environments without prior seed)
INSERT INTO public.column_visibility (column_name, column_label, visible, display_order)
SELECT 'division_electoral_district', 'Riding', true, 15
WHERE NOT EXISTS (
  SELECT 1 FROM public.column_visibility WHERE column_name = 'division_electoral_district'
);
