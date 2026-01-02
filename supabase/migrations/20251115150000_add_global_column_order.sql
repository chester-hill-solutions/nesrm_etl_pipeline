-- Add global_display_order to both column_visibility and custom_columns for unified ordering
-- This allows default and custom columns to be mixed together

-- Add global_display_order to column_visibility
ALTER TABLE public.column_visibility
  ADD COLUMN IF NOT EXISTS global_display_order integer;

-- Add global_display_order to custom_columns  
ALTER TABLE public.custom_columns
  ADD COLUMN IF NOT EXISTS global_display_order integer;

-- Create indexes
CREATE INDEX IF NOT EXISTS column_visibility_global_display_order_idx 
  ON public.column_visibility(global_display_order);

CREATE INDEX IF NOT EXISTS custom_columns_global_display_order_idx 
  ON public.custom_columns(global_display_order);

-- Initialize global_display_order for default columns (use existing display_order * 10 to leave room for custom columns)
UPDATE public.column_visibility
SET global_display_order = display_order * 10
WHERE global_display_order IS NULL;

-- Initialize global_display_order for custom columns (start after default columns, use id * 10 + 10000)
UPDATE public.custom_columns
SET global_display_order = (id * 10) + 10000
WHERE global_display_order IS NULL;