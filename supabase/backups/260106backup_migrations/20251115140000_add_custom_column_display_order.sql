-- Add display_order to custom_columns table

ALTER TABLE public.custom_columns
  ADD COLUMN IF NOT EXISTS display_order integer NOT NULL DEFAULT 0;

-- Create index for efficient ordering
CREATE INDEX IF NOT EXISTS custom_columns_display_order_idx 
  ON public.custom_columns(display_order);

-- Set initial display_order based on creation order (using id as proxy)
UPDATE public.custom_columns
SET display_order = id
WHERE display_order = 0;

