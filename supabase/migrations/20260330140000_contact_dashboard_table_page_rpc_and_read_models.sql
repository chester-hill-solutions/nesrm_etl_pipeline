-- Semantically named dashboard entrypoint for TTI / portability (same payload as optimized RPC).
-- Read models: latest survey response per (contact_id, survey_id) for future filter/RPC joins.

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_table_page(
  p_scope_type text,
  p_scope_values text[],
  p_profile_id text,
  p_role text,
  p_filter_group jsonb,
  p_sort_rules jsonb,
  p_search_term text,
  p_page integer,
  p_page_size integer,
  p_include_unanswered_status boolean DEFAULT true,
  p_include_button_state boolean DEFAULT true,
  p_include_pending_suggestions boolean DEFAULT true,
  p_group_by_household boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
VOLATILE
SET search_path = public
AS $$
BEGIN
  RETURN public.load_contact_dashboard_page_payload_optimized(
    p_scope_type,
    p_scope_values,
    p_profile_id,
    p_role,
    p_filter_group,
    p_sort_rules,
    p_search_term,
    p_page,
    p_page_size,
    p_include_unanswered_status,
    p_include_button_state,
    p_include_pending_suggestions,
    p_group_by_household
  );
END;
$$;

COMMENT ON FUNCTION public.load_contact_dashboard_table_page(
  text, text[], text, text, jsonb, jsonb, text, integer, integer, boolean, boolean, boolean, boolean
) IS
  'Contact dashboard table TTI path: same jsonb payload as load_contact_dashboard_page_payload_optimized; use for explicit rollout and metrics.';

GRANT EXECUTE ON FUNCTION public.load_contact_dashboard_table_page(
  text, text[], text, text, jsonb, jsonb, text, integer, integer, boolean, boolean, boolean, boolean
) TO service_role;

-- Latest row per (contact_id, survey_id) by created_at desc, id desc — for future RPC/filter reuse.
CREATE OR REPLACE VIEW public.survey_response_latest_by_contact_survey AS
SELECT DISTINCT ON (sr.contact_id, sr.survey_id)
  sr.id,
  sr.contact_id,
  sr.survey_id,
  sr.created_at,
  sr.updated_at,
  sr.status,
  sr.disposition,
  sr.completed_at
FROM public.survey_responses sr
WHERE sr.contact_id IS NOT NULL
  AND sr.survey_id IS NOT NULL
ORDER BY sr.contact_id, sr.survey_id, sr.created_at DESC, sr.id DESC;

COMMENT ON VIEW public.survey_response_latest_by_contact_survey IS
  'One row per (contact_id, survey_id): latest survey_responses row. Use in joins instead of repeated DISTINCT ON in leaf functions.';

-- Search ILIKE on phone / street_address in dashboard RPC; trigram helps leading-wildcard patterns.
CREATE INDEX IF NOT EXISTS contact_phone_trgm_idx
  ON public.contact USING gin (phone extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS contact_street_address_trgm_idx
  ON public.contact USING gin (street_address extensions.gin_trgm_ops);
