ALTER TABLE public.column_visibility DROP CONSTRAINT column_visibility_data_type_check;
     ALTER TABLE public.column_visibility
     ADD CONSTRAINT column_visibility_data_type_check CHECK (
       data_type = ANY (ARRAY[
         'text'::text,
         'number'::text,
         'date'::text,
         'boolean'::text,
         'select'::text,
         'text[]'::text
       ])
     );
