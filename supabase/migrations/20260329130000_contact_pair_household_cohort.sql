-- Pairwise household check: true when two contacts fall in the same household component
-- within the 2-contact id set (same rules as dashboard cohort grouping).

CREATE OR REPLACE FUNCTION public.contact_pair_same_household_cohort(
  p_a bigint,
  p_b bigint,
  p_sort_rules jsonb,
  p_role text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p_a IS NOT NULL
    AND p_b IS NOT NULL
    AND p_a <> p_b
    AND (
      SELECT COUNT(DISTINCT h.household_group_id)
      FROM public.load_contact_list_page_ids(
        ARRAY[p_a, p_b]::bigint[],
        COALESCE(p_sort_rules, '[]'::jsonb),
        1,
        2,
        p_role,
        true
      ) AS h(contact_id, total_count, household_group_id)
    ) = 1;
$$;

COMMENT ON FUNCTION public.contact_pair_same_household_cohort(bigint, bigint, jsonb, text) IS
  'True when p_a and p_b are grouped in the same household within the candidate set {p_a, p_b} (household RPC rules).';
