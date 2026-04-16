-- Fix: resolve_filter_node must cast filter values for non-text contact columns.
-- Without explicit casts, dynamic SQL binds $1 as text which breaks comparisons like bigint = text.
-- This is especially visible when filtering by contact.id (bigint) via resolve_filter_group.

CREATE OR REPLACE FUNCTION public.resolve_filter_node(p_node jsonb)
RETURNS SETOF bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_col text;
  v_op text;
  v_val text;

  v_custom_id bigint;
  v_custom_type text;
  v_val_col text;

  v_db_col text;
  v_param_cast text;

  v_esc_ilike text;
  v_sql_op text;
BEGIN
  IF p_node IS NULL OR (p_node->>'kind') <> 'filter' THEN
    RETURN;
  END IF;

  v_col := NULLIF(TRIM(p_node->>'column'), '');
  v_op := NULLIF(LOWER(TRIM(COALESCE(p_node->>'operator', ''))), '');
  v_val := p_node->>'value';
  IF v_val IS NOT NULL THEN
    v_val := TRIM(v_val);
  END IF;

  IF v_col IS NULL OR v_op IS NULL THEN
    RETURN;
  END IF;

  -- Custom column lookup by name
  SELECT cc.id, cc.data_type
  INTO v_custom_id, v_custom_type
  FROM public.custom_columns cc
  WHERE cc.name = v_col
  LIMIT 1;

  IF v_custom_id IS NOT NULL THEN
    -- Custom column filter (contact_custom_fields)
    v_val_col := CASE v_custom_type
      WHEN 'select' THEN 'value_text'
      ELSE 'value_' || v_custom_type
    END;

    -- Special semantics: eq "any" / empty = has any non-empty value
    IF v_op = 'eq'
      AND (v_val IS NULL OR v_val = '' OR LOWER(v_val) = 'any')
    THEN
      RETURN QUERY EXECUTE format(
        'SELECT ccf.contact_id
         FROM public.contact_custom_fields ccf
         WHERE ccf.column_id = $1
           AND ccf.%I IS NOT NULL
           AND TRIM(COALESCE(ccf.%I::text, '''')) <> ''''',
        v_val_col,
        v_val_col
      )
      USING v_custom_id;
      RETURN;
    END IF;

    -- neq "any" for select = has no value (missing row or null/empty)
    IF v_op = 'neq'
      AND (v_val IS NULL OR v_val = '' OR LOWER(v_val) = 'any')
      AND v_custom_type = 'select'
    THEN
      RETURN QUERY
      SELECT c.id
      FROM public.contact c
      WHERE (c.contact_status IS NULL OR c.contact_status <> 'archived')
        AND NOT EXISTS (
          SELECT 1
          FROM public.contact_custom_fields ccf
          WHERE ccf.contact_id = c.id
            AND ccf.column_id = v_custom_id
            AND ccf.value_text IS NOT NULL
            AND TRIM(ccf.value_text) <> ''
        );
      RETURN;
    END IF;

    -- is_null for custom: include contacts with missing row or null/empty value
    IF v_op = 'is_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND NOT EXISTS (
             SELECT 1
             FROM public.contact_custom_fields ccf
             WHERE ccf.contact_id = c.id
               AND ccf.column_id = $1
               AND ccf.%I IS NOT NULL
               AND TRIM(COALESCE(ccf.%I::text, '''')) <> ''''
           )',
        v_val_col,
        v_val_col
      )
      USING v_custom_id;
      RETURN;
    END IF;

    -- Other operators on custom column
    CASE v_op
      WHEN 'is_not_null' THEN
        RETURN QUERY EXECUTE format(
          'SELECT ccf.contact_id
           FROM public.contact_custom_fields ccf
           WHERE ccf.column_id = $1
             AND ccf.%I IS NOT NULL',
          v_val_col
        )
        USING v_custom_id;

      WHEN 'eq' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2',
            v_val_col
          )
          USING v_custom_id, v_val;
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2',
            v_val_col
          )
          USING v_custom_id, (v_val::numeric);
        ELSIF v_custom_type = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2',
            v_val_col
          )
          USING v_custom_id, (v_val IN ('true', '1'));
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = $2::date',
            v_val_col
          )
          USING v_custom_id, v_val;
        END IF;

      WHEN 'neq' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, v_val;
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, (v_val::numeric);
        ELSIF v_custom_type = 'boolean' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, (v_val IN ('true', '1'));
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I <> $2::date)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, v_val;
        END IF;

      WHEN 'contains' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike || '%';
        END IF;

      WHEN 'not_contains' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND (ccf.%I IS NULL OR ccf.%I NOT ILIKE $2)',
            v_val_col,
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike || '%';
        END IF;

      WHEN 'starts_with' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, v_esc_ilike || '%';
        END IF;

      WHEN 'ends_with' THEN
        IF v_custom_type IN ('text', 'select') THEN
          v_esc_ilike := public.escape_search_for_ilike(v_val);
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I ILIKE $2',
            v_val_col
          )
          USING v_custom_id, '%' || v_esc_ilike;
        END IF;

      WHEN 'gt', 'gte', 'lt', 'lte' THEN
        v_sql_op := CASE v_op
          WHEN 'gt' THEN '>'
          WHEN 'gte' THEN '>='
          WHEN 'lt' THEN '<'
          WHEN 'lte' THEN '<='
        END;

        IF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I %s $2',
            v_val_col,
            v_sql_op
          )
          USING v_custom_id, (v_val::numeric);
        ELSIF v_custom_type = 'date' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I %s $2::date',
            v_val_col,
            v_sql_op
          )
          USING v_custom_id, v_val;
        ELSIF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I %s $2',
            v_val_col,
            v_sql_op
          )
          USING v_custom_id, v_val;
        END IF;

      WHEN 'in' THEN
        IF v_custom_type IN ('text', 'select') THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = ANY($2::text[])',
            v_val_col
          )
          USING v_custom_id,
            (
              SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
            );
        ELSIF v_custom_type = 'number' THEN
          RETURN QUERY EXECUTE format(
            'SELECT ccf.contact_id
             FROM public.contact_custom_fields ccf
             WHERE ccf.column_id = $1
               AND ccf.%I = ANY($2::numeric[])',
            v_val_col
          )
          USING v_custom_id,
            (
              SELECT COALESCE(array_agg((TRIM(t))::numeric), ARRAY[]::numeric[])
              FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
              WHERE TRIM(t) <> ''
                AND TRIM(t) ~ '^-?[0-9]+(\.[0-9]+)?$'
            );
        END IF;

      ELSE
        NULL;
    END CASE;

    RETURN;
  END IF;

  -- Standard contact column: map display key to db column
  v_db_col := CASE v_col
    WHEN 'riding' THEN 'division_electoral_district'
    WHEN 'campusClub' THEN 'campus_club'
    WHEN 'rideRequest' THEN 'ride_request_status'
    WHEN 'contactStatus' THEN 'contact_status'
    WHEN 'postal_code' THEN 'postcode'
    ELSE v_col
  END;

  -- Validate v_db_col exists on contact (allowlist for safety)
  IF v_db_col NOT IN (
    'id',
    'firstname',
    'surname',
    'email',
    'phone',
    'division_electoral_district',
    'campus_club',
    'organizer',
    'ride_request_status',
    'contact_status',
    'postcode',
    'street_address',
    'municipality',
    'birthyear',
    'birthmonth',
    'birthdate',
    'tags',
    'member',
    'olp23_member',
    'region',
    'comms_consent',
    'signup_consent',
    'research_status',
    'research_updated_at'
  ) THEN
    RETURN;
  END IF;

  -- Special: "name" column (firstname + surname)
  IF v_col = 'name' AND v_val IS NOT NULL AND v_val <> '' THEN
    v_esc_ilike := public.escape_search_for_ilike(v_val);

    IF v_op IN ('contains', 'eq', 'starts_with', 'ends_with') THEN
      RETURN QUERY EXECUTE
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.firstname ILIKE $1 OR c.surname ILIKE $1)'
      USING
        CASE v_op
          WHEN 'starts_with' THEN v_esc_ilike || '%'
          WHEN 'ends_with' THEN '%' || v_esc_ilike
          WHEN 'eq' THEN v_esc_ilike
          ELSE '%' || v_esc_ilike || '%'
        END;
    END IF;

    RETURN;
  END IF;

  -- Cast filter values for non-text columns (avoids bigint = text errors)
  v_param_cast := CASE v_db_col
    WHEN 'id' THEN 'bigint'
    WHEN 'birthyear' THEN 'smallint'
    WHEN 'birthmonth' THEN 'smallint'
    WHEN 'birthdate' THEN 'smallint'
    WHEN 'comms_consent' THEN 'boolean'
    WHEN 'signup_consent' THEN 'boolean'
    WHEN 'member' THEN 'boolean'
    WHEN 'research_updated_at' THEN 'timestamptz'
    ELSE NULL
  END;

  IF v_param_cast IS NOT NULL
    AND v_op IN ('eq', 'neq', 'gt', 'gte', 'lt', 'lte')
    AND (v_val IS NULL OR v_val = '')
  THEN
    RETURN;
  END IF;

  -- Standard column operators
  v_esc_ilike := public.escape_search_for_ilike(v_val);

  CASE v_op
    WHEN 'eq' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I = $1::%s',
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I = $1',
        v_db_col
      )
      USING v_val;

    WHEN 'neq' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND (c.%I IS NULL OR c.%I <> $1::%s)',
          v_db_col,
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.%I IS NULL OR c.%I <> $1)',
        v_db_col,
        v_db_col
      )
      USING v_val;

    WHEN 'contains' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';

    WHEN 'not_contains' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND (c.%I IS NULL OR c.%I NOT ILIKE $1)',
        v_db_col,
        v_db_col
      )
      USING '%' || v_esc_ilike || '%';

    WHEN 'starts_with' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING v_esc_ilike || '%';

    WHEN 'ends_with' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I ILIKE $1',
        v_db_col
      )
      USING '%' || v_esc_ilike;

    WHEN 'gt' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I > $1::%s',
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I > $1',
        v_db_col
      )
      USING v_val;

    WHEN 'gte' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I >= $1::%s',
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I >= $1',
        v_db_col
      )
      USING v_val;

    WHEN 'lt' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I < $1::%s',
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I < $1',
        v_db_col
      )
      USING v_val;

    WHEN 'lte' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I <= $1::%s',
          v_db_col,
          v_param_cast
        )
        USING v_val;
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I <= $1',
        v_db_col
      )
      USING v_val;

    WHEN 'is_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I IS NULL',
        v_db_col
      );

    WHEN 'is_not_null' THEN
      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I IS NOT NULL',
        v_db_col
      );

    WHEN 'in' THEN
      IF v_param_cast IS NOT NULL THEN
        RETURN QUERY EXECUTE format(
          'SELECT c.id
           FROM public.contact c
           WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
             AND c.%I = ANY($1::%s[])',
          v_db_col,
          v_param_cast
        )
        USING
          (
            SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
            FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
            WHERE TRIM(t) <> ''
          );
        RETURN;
      END IF;

      RETURN QUERY EXECUTE format(
        'SELECT c.id
         FROM public.contact c
         WHERE (c.contact_status IS NULL OR c.contact_status <> ''archived'')
           AND c.%I = ANY($1::text[])',
        v_db_col
      )
      USING
        (
          SELECT COALESCE(array_agg(TRIM(t)), ARRAY[]::text[])
          FROM unnest(string_to_array(COALESCE(v_val, ''), ',')) t
          WHERE TRIM(t) <> ''
        );

    ELSE
      NULL;
  END CASE;
END;
$$;

