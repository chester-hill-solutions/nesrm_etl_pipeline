-- Remove legacy 4-arg overload that collides with the newer 5-arg function
-- (where p_role has a default). Keeping both causes ambiguous 4-arg calls.

DROP FUNCTION IF EXISTS public.load_contact_list_page_ids(
  bigint[],
  jsonb,
  integer,
  integer
);
