-- Fix bigint/text mismatch for not_in filters on contact.id in dashboard RPC
-- filter-group expansion helpers.

CREATE OR REPLACE FUNCTION public.resolve_filter_group(p_group jsonb)
RETURNS SETOF bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_kind text;
  v_mode text;
  v_child jsonb;

  v_ids bigint[];
  v_all bigint[] := ARRAY[]::bigint[];
  v_first boolean := true;

  v_filter_op text;
  v_filter_val text;
  v_min text;
  v_max text;
  v_filter_col text;
  v_filter_id bigint;
  v_filter_ids bigint[];
BEGIN
  IF p_group IS NULL OR jsonb_typeof(p_group) <> 'object' THEN
    RETURN;
  END IF;

  v_kind := p_group->>'kind';

  IF v_kind = 'filter' THEN
    v_filter_op := LOWER(COALESCE(p_group->>'operator', ''));
    v_filter_val := p_group->>'value';
    v_filter_col := NULLIF(TRIM(COALESCE(p_group->>'column', '')), '');

    -- Handle contact.id filters directly to avoid bigint/text comparison failures.
    IF v_filter_col = 'id' THEN
      IF v_filter_op = 'in' OR v_filter_op = 'not_in' THEN
        v_filter_ids := (
          SELECT COALESCE(array_agg(DISTINCT (TRIM(t))::bigint), ARRAY[]::bigint[])
          FROM unnest(string_to_array(COALESCE(v_filter_val, ''), ',')) AS t
          WHERE TRIM(t) <> ''
            AND TRIM(t) ~ '^-?[0-9]+$'
        );

        IF v_filter_op = 'in' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id = ANY(v_filter_ids);
          RETURN;
        END IF;

        RETURN QUERY
        SELECT c.id
        FROM public.contact c
        WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
          AND NOT (c.id = ANY(v_filter_ids));
        RETURN;
      END IF;

      IF v_filter_op = 'between' OR v_filter_op = 'not_between' THEN
        v_min := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 1)), '');
        v_max := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 2)), '');
        IF v_min IS NULL OR v_max IS NULL THEN
          RETURN;
        END IF;
        IF v_min !~ '^-?[0-9]+$' OR v_max !~ '^-?[0-9]+$' THEN
          RETURN;
        END IF;

        IF v_filter_op = 'between' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id BETWEEN v_min::bigint AND v_max::bigint;
          RETURN;
        END IF;

        RETURN QUERY
        SELECT c.id
        FROM public.contact c
        WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
          AND (c.id < v_min::bigint OR c.id > v_max::bigint);
        RETURN;
      END IF;

      IF v_filter_op IN ('eq', 'neq', 'gt', 'gte', 'lt', 'lte') THEN
        IF v_filter_val IS NULL OR TRIM(v_filter_val) = '' OR TRIM(v_filter_val) !~ '^-?[0-9]+$' THEN
          RETURN;
        END IF;
        v_filter_id := TRIM(v_filter_val)::bigint;

        IF v_filter_op = 'eq' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id = v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'neq' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id <> v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'gt' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id > v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'gte' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id >= v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'lt' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id < v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'lte' THEN
          RETURN QUERY
          SELECT c.id
          FROM public.contact c
          WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
            AND c.id <= v_filter_id;
          RETURN;
        END IF;
      END IF;

      IF v_filter_op = 'is_null' THEN
        RETURN;
      END IF;
      IF v_filter_op = 'is_not_null' THEN
        RETURN QUERY
        SELECT c.id
        FROM public.contact c
        WHERE c.contact_status IS NULL OR c.contact_status <> 'archived';
        RETURN;
      END IF;
    END IF;

    IF v_filter_op = 'between' OR v_filter_op = 'not_between' THEN
      v_min := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 1)), '');
      v_max := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 2)), '');
      IF v_min IS NULL OR v_max IS NULL THEN
        RETURN;
      END IF;

      IF v_filter_op = 'between' THEN
        RETURN QUERY
        WITH lower_ids AS (
          SELECT *
          FROM public.resolve_filter_node(
            jsonb_set(
              jsonb_set(p_group, '{operator}', to_jsonb('gte'::text), false),
              '{value}',
              to_jsonb(v_min),
              false
            )
          )
        ),
        upper_ids AS (
          SELECT *
          FROM public.resolve_filter_node(
            jsonb_set(
              jsonb_set(p_group, '{operator}', to_jsonb('lte'::text), false),
              '{value}',
              to_jsonb(v_max),
              false
            )
          )
        )
        SELECT * FROM lower_ids
        INTERSECT
        SELECT * FROM upper_ids;
        RETURN;
      END IF;

      RETURN QUERY
      WITH lower_ids AS (
        SELECT *
        FROM public.resolve_filter_node(
          jsonb_set(
            jsonb_set(p_group, '{operator}', to_jsonb('lt'::text), false),
            '{value}',
            to_jsonb(v_min),
            false
          )
        )
      ),
      upper_ids AS (
        SELECT *
        FROM public.resolve_filter_node(
          jsonb_set(
            jsonb_set(p_group, '{operator}', to_jsonb('gt'::text), false),
            '{value}',
            to_jsonb(v_max),
            false
          )
        )
      )
      SELECT DISTINCT id
      FROM (
        SELECT * FROM lower_ids
        UNION ALL
        SELECT * FROM upper_ids
      ) combined(id);
      RETURN;
    END IF;

    IF v_filter_op = 'not_in' THEN
      IF v_filter_col = 'id' THEN
        RETURN QUERY
        WITH id_vals AS (
          SELECT DISTINCT (TRIM(t))::bigint AS id
          FROM unnest(string_to_array(COALESCE(v_filter_val, ''), ',')) AS t
          WHERE TRIM(t) <> ''
            AND TRIM(t) ~ '^[0-9]+$'
        ),
        base_ids AS (
          SELECT c.id
          FROM public.contact c
          WHERE c.contact_status IS NULL OR c.contact_status <> 'archived'
        )
        SELECT b.id
        FROM base_ids b
        LEFT JOIN id_vals i ON i.id = b.id
        WHERE i.id IS NULL;
        RETURN;
      END IF;

      RETURN QUERY
      WITH in_ids(id) AS (
        SELECT *
        FROM public.resolve_filter_node(
          jsonb_set(p_group, '{operator}', to_jsonb('in'::text), false)
        )
      ),
      base_ids AS (
        SELECT c.id
        FROM public.contact c
        WHERE c.contact_status IS NULL OR c.contact_status <> 'archived'
      )
      SELECT b.id
      FROM base_ids b
      LEFT JOIN in_ids i ON i.id = b.id
      WHERE i.id IS NULL;
      RETURN;
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.resolve_filter_node(p_group);
    RETURN;
  END IF;

  IF v_kind <> 'group' THEN
    RETURN;
  END IF;

  v_mode := LOWER(COALESCE(p_group->>'mode', 'and'));
  IF v_mode NOT IN ('and', 'or') THEN
    v_mode := 'and';
  END IF;

  FOR v_child IN
    SELECT *
    FROM jsonb_array_elements(COALESCE(p_group->'children', '[]'::jsonb))
  LOOP
    IF v_mode = 'and' THEN
      IF v_first THEN
        v_all := COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group(v_child)),
          ARRAY[]::bigint[]
        );
        v_first := false;
      ELSE
        v_ids := COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group(v_child)),
          ARRAY[]::bigint[]
        );

        v_all := ARRAY(
          SELECT unnest(v_all)
          INTERSECT
          SELECT unnest(v_ids)
        );
      END IF;
    ELSE
      v_all :=
        v_all
        || COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group(v_child)),
          ARRAY[]::bigint[]
        );
      v_first := false;
    END IF;
  END LOOP;

  IF v_first THEN
    RETURN;
  END IF;

  IF v_mode = 'or' THEN
    v_all := ARRAY(SELECT DISTINCT unnest(v_all));
  END IF;

  RETURN QUERY
  SELECT unnest(v_all);
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_filter_group_scoped(
  p_group jsonb,
  p_candidate_ids bigint[]
)
RETURNS SETOF bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_kind text;
  v_mode text;
  v_child jsonb;
  v_ids bigint[];
  v_all bigint[] := ARRAY[]::bigint[];
  v_first boolean := true;

  v_filter_op text;
  v_filter_val text;
  v_min text;
  v_max text;
  v_filter_col text;
  v_filter_id bigint;
  v_filter_ids bigint[];
BEGIN
  IF p_group IS NULL OR jsonb_typeof(p_group) <> 'object' THEN
    RETURN;
  END IF;

  IF p_candidate_ids IS NULL OR cardinality(p_candidate_ids) = 0 THEN
    RETURN;
  END IF;

  v_kind := p_group->>'kind';

  IF v_kind = 'filter' THEN
    v_filter_op := LOWER(COALESCE(p_group->>'operator', ''));
    v_filter_val := p_group->>'value';
    v_filter_col := NULLIF(TRIM(COALESCE(p_group->>'column', '')), '');

    -- Handle contact.id filters directly to avoid bigint/text comparison failures.
    IF v_filter_col = 'id' THEN
      IF v_filter_op = 'in' OR v_filter_op = 'not_in' THEN
        v_filter_ids := (
          SELECT COALESCE(array_agg(DISTINCT (TRIM(t))::bigint), ARRAY[]::bigint[])
          FROM unnest(string_to_array(COALESCE(v_filter_val, ''), ',')) AS t
          WHERE TRIM(t) <> ''
            AND TRIM(t) ~ '^-?[0-9]+$'
        );

        IF v_filter_op = 'in' THEN
          RETURN QUERY
          SELECT cid
          FROM unnest(p_candidate_ids) AS cid
          WHERE cid = ANY(v_filter_ids);
          RETURN;
        END IF;

        RETURN QUERY
        SELECT cid
        FROM unnest(p_candidate_ids) AS cid
        WHERE NOT (cid = ANY(v_filter_ids));
        RETURN;
      END IF;

      IF v_filter_op = 'between' OR v_filter_op = 'not_between' THEN
        v_min := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 1)), '');
        v_max := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 2)), '');
        IF v_min IS NULL OR v_max IS NULL THEN
          RETURN;
        END IF;
        IF v_min !~ '^-?[0-9]+$' OR v_max !~ '^-?[0-9]+$' THEN
          RETURN;
        END IF;

        IF v_filter_op = 'between' THEN
          RETURN QUERY
          SELECT cid
          FROM unnest(p_candidate_ids) AS cid
          WHERE cid BETWEEN v_min::bigint AND v_max::bigint;
          RETURN;
        END IF;

        RETURN QUERY
        SELECT cid
        FROM unnest(p_candidate_ids) AS cid
        WHERE cid < v_min::bigint OR cid > v_max::bigint;
        RETURN;
      END IF;

      IF v_filter_op IN ('eq', 'neq', 'gt', 'gte', 'lt', 'lte') THEN
        IF v_filter_val IS NULL OR TRIM(v_filter_val) = '' OR TRIM(v_filter_val) !~ '^-?[0-9]+$' THEN
          RETURN;
        END IF;
        v_filter_id := TRIM(v_filter_val)::bigint;

        IF v_filter_op = 'eq' THEN
          RETURN QUERY SELECT cid FROM unnest(p_candidate_ids) AS cid WHERE cid = v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'neq' THEN
          RETURN QUERY SELECT cid FROM unnest(p_candidate_ids) AS cid WHERE cid <> v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'gt' THEN
          RETURN QUERY SELECT cid FROM unnest(p_candidate_ids) AS cid WHERE cid > v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'gte' THEN
          RETURN QUERY SELECT cid FROM unnest(p_candidate_ids) AS cid WHERE cid >= v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'lt' THEN
          RETURN QUERY SELECT cid FROM unnest(p_candidate_ids) AS cid WHERE cid < v_filter_id;
          RETURN;
        ELSIF v_filter_op = 'lte' THEN
          RETURN QUERY SELECT cid FROM unnest(p_candidate_ids) AS cid WHERE cid <= v_filter_id;
          RETURN;
        END IF;
      END IF;

      IF v_filter_op = 'is_null' THEN
        RETURN;
      END IF;
      IF v_filter_op = 'is_not_null' THEN
        RETURN QUERY
        SELECT cid
        FROM unnest(p_candidate_ids) AS cid;
        RETURN;
      END IF;
    END IF;

    IF v_filter_op = 'between' OR v_filter_op = 'not_between' THEN
      v_min := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 1)), '');
      v_max := NULLIF(TRIM(split_part(COALESCE(v_filter_val, ''), ',', 2)), '');
      IF v_min IS NULL OR v_max IS NULL THEN
        RETURN;
      END IF;

      IF v_filter_op = 'between' THEN
        RETURN QUERY
        WITH lower_ids AS (
          SELECT cid
          FROM unnest(p_candidate_ids) AS cid
          INTERSECT
          SELECT *
          FROM public.resolve_filter_node(
            jsonb_set(
              jsonb_set(p_group, '{operator}', to_jsonb('gte'::text), false),
              '{value}',
              to_jsonb(v_min),
              false
            )
          )
        ),
        upper_ids AS (
          SELECT cid
          FROM unnest(p_candidate_ids) AS cid
          INTERSECT
          SELECT *
          FROM public.resolve_filter_node(
            jsonb_set(
              jsonb_set(p_group, '{operator}', to_jsonb('lte'::text), false),
              '{value}',
              to_jsonb(v_max),
              false
            )
          )
        )
        SELECT * FROM lower_ids
        INTERSECT
        SELECT * FROM upper_ids;
        RETURN;
      END IF;

      RETURN QUERY
      WITH lower_ids AS (
        SELECT cid
        FROM unnest(p_candidate_ids) AS cid
        INTERSECT
        SELECT *
        FROM public.resolve_filter_node(
          jsonb_set(
            jsonb_set(p_group, '{operator}', to_jsonb('lt'::text), false),
            '{value}',
            to_jsonb(v_min),
            false
          )
        )
      ),
      upper_ids AS (
        SELECT cid
        FROM unnest(p_candidate_ids) AS cid
        INTERSECT
        SELECT *
        FROM public.resolve_filter_node(
          jsonb_set(
            jsonb_set(p_group, '{operator}', to_jsonb('gt'::text), false),
            '{value}',
            to_jsonb(v_max),
            false
          )
        )
      )
      SELECT DISTINCT id
      FROM (
        SELECT * FROM lower_ids
        UNION ALL
        SELECT * FROM upper_ids
      ) combined(id);
      RETURN;
    END IF;

    IF v_filter_op = 'not_in' THEN
      IF v_filter_col = 'id' THEN
        RETURN QUERY
        WITH id_vals AS (
          SELECT DISTINCT (TRIM(t))::bigint AS id
          FROM unnest(string_to_array(COALESCE(v_filter_val, ''), ',')) AS t
          WHERE TRIM(t) <> ''
            AND TRIM(t) ~ '^[0-9]+$'
        )
        SELECT cid
        FROM unnest(p_candidate_ids) AS cid
        LEFT JOIN id_vals i ON i.id = cid
        WHERE i.id IS NULL;
        RETURN;
      END IF;

      RETURN QUERY
      WITH in_ids(id) AS (
        SELECT *
        FROM public.resolve_filter_node(
          jsonb_set(p_group, '{operator}', to_jsonb('in'::text), false)
        )
      )
      SELECT cid
      FROM unnest(p_candidate_ids) AS cid
      LEFT JOIN in_ids i ON i.id = cid
      WHERE i.id IS NULL;
      RETURN;
    END IF;

    RETURN QUERY
    SELECT cid
    FROM unnest(p_candidate_ids) AS cid
    INTERSECT
    SELECT * FROM public.resolve_filter_node(p_group);
    RETURN;
  END IF;

  IF v_kind <> 'group' THEN
    RETURN;
  END IF;

  v_mode := LOWER(COALESCE(p_group->>'mode', 'and'));
  IF v_mode NOT IN ('and', 'or') THEN
    v_mode := 'and';
  END IF;

  FOR v_child IN
    SELECT *
    FROM jsonb_array_elements(COALESCE(p_group->'children', '[]'::jsonb))
  LOOP
    IF v_mode = 'and' THEN
      IF v_first THEN
        v_all := COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group_scoped(v_child, p_candidate_ids)),
          ARRAY[]::bigint[]
        );
        v_first := false;
      ELSE
        v_ids := COALESCE(
          ARRAY(SELECT * FROM public.resolve_filter_group_scoped(v_child, p_candidate_ids)),
          ARRAY[]::bigint[]
        );
        v_all := ARRAY(
          SELECT unnest(v_all)
          INTERSECT
          SELECT unnest(v_ids)
        );
      END IF;
    ELSE
      v_all := v_all || COALESCE(
        ARRAY(SELECT * FROM public.resolve_filter_group_scoped(v_child, p_candidate_ids)),
        ARRAY[]::bigint[]
      );
      v_first := false;
    END IF;
  END LOOP;

  IF v_first THEN
    RETURN;
  END IF;

  IF v_mode = 'or' THEN
    v_all := ARRAY(SELECT DISTINCT unnest(v_all));
  END IF;

  RETURN QUERY
  SELECT cid
  FROM unnest(v_all) AS cid
  INTERSECT
  SELECT unnest(p_candidate_ids);
END;
$$;
