-- PostgREST executes STABLE / IMMUTABLE RPCs in a read-only transaction.
-- This function calls load_contact_list_page_ids, which uses CREATE TEMP TABLE ... AS
-- (see 20260328120000_contact_household_temp_no_drop.sql), which fails with SQLSTATE 25006.

ALTER FUNCTION public.contact_pair_same_household_cohort(
  bigint,
  bigint,
  jsonb,
  text
) VOLATILE;
