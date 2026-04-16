-- Improve contact dashboard and request lookup query paths.
-- - Batch request lookups ordered by (contact_id, created_at desc) benefit from a matching btree index.
-- - Contact search + NOT ILIKE filters on tags/organizer use leading-wildcard patterns; add trigram GIN indexes.
-- - Route the primary dashboard RPC through the optimized implementation (scoped wrapper delegates to it).

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

CREATE INDEX IF NOT EXISTS request_contact_id_created_at_id_desc_idx
  ON public.request (contact_id, created_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS contact_tags_trgm_idx
  ON public.contact USING gin (tags extensions.gin_trgm_ops);

CREATE INDEX IF NOT EXISTS contact_organizer_trgm_idx
  ON public.contact USING gin (organizer extensions.gin_trgm_ops);

CREATE OR REPLACE FUNCTION public.load_contact_dashboard_page_payload(
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
  p_include_pending_suggestions boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
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
    p_include_pending_suggestions
  );
END;
$$;
