-- Add computed column metadata to custom_columns.
-- Supports derived/formula/answer/submission column kinds.

ALTER TABLE public.custom_columns
  ADD COLUMN IF NOT EXISTS column_kind text NOT NULL DEFAULT 'stored',
  ADD COLUMN IF NOT EXISTS computed_config jsonb;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'custom_columns_column_kind_check'
  ) THEN
    ALTER TABLE public.custom_columns
      ADD CONSTRAINT custom_columns_column_kind_check
      CHECK (
        column_kind = ANY (
          ARRAY[
            'stored'::text,
            'derived'::text,
            'formula'::text,
            'answer'::text,
            'submission'::text
          ]
        )
      );
  END IF;
END $$;
