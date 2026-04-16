-- Server-side sort/paginate helper for contacts.
-- Accepts a pre-filtered ID set and sort rules, returns ordered page IDs + total count.

CREATE OR REPLACE FUNCTION public.load_contact_list_page_ids(
  p_contact_ids bigint[],
  p_sort_rules jsonb,
  p_page integer,
  p_page_size integer
)
RETURNS TABLE(contact_id bigint, total_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sql text;
  v_joins text := '';
  v_order text := '';
  v_rule jsonb;
  v_idx integer := 0;
  v_column text;
  v_db_column text;
  v_order_dir text;
  v_survey_order text;
  v_survey_id integer;
  v_latest_active_survey_id integer := NULL;
  v_custom_id integer;
  v_custom_type text;
  v_col_exists boolean;
  v_sort_expr text;
  v_offset integer := GREATEST((COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 25), 0);
  v_limit integer := GREATEST(COALESCE(p_page_size, 25), 1);
BEGIN
  IF p_contact_ids IS NULL OR cardinality(p_contact_ids) = 0 THEN
    RETURN;
  END IF;

  FOR v_rule IN
    SELECT value
    FROM jsonb_array_elements(COALESCE(p_sort_rules, '[]'::jsonb))
  LOOP
    v_idx := v_idx + 1;
    v_column := COALESCE(v_rule->>'column', '');
    v_order_dir := lower(COALESCE(v_rule->>'order', 'asc'));
    IF v_order_dir NOT IN ('asc', 'desc') THEN
      v_order_dir := 'asc';
    END IF;

    IF v_column = 'survey_status' THEN
      v_survey_order := v_rule->>'surveyStatusOrder';
      IF v_survey_order NOT IN ('completed_first', 'in_progress_first', 'not_started_first') THEN
        v_survey_order := NULL;
      END IF;

      v_survey_id := NULLIF(v_rule->>'surveyId', '')::integer;
      IF v_survey_id IS NULL OR v_survey_id <= 0 THEN
        IF v_latest_active_survey_id IS NULL THEN
          SELECT s.id
          INTO v_latest_active_survey_id
          FROM public.surveys s
          WHERE s.status = 'active'
            AND s.archived = false
          ORDER BY s.id DESC
          LIMIT 1;
        END IF;
        v_survey_id := COALESCE(v_latest_active_survey_id, 0);
      END IF;

      v_joins := v_joins || format(
        ' LEFT JOIN LATERAL (
            SELECT sr.status
            FROM public.survey_responses sr
            WHERE sr.contact_id = b.id
              AND sr.survey_id = %s
              AND sr.status IN (''in_progress'', ''completed'')
            ORDER BY sr.created_at DESC
            LIMIT 1
          ) ss_%s ON true',
        v_survey_id,
        v_idx
      );

      v_sort_expr := CASE COALESCE(v_survey_order, 'completed_first')
        WHEN 'not_started_first' THEN
          format(
            '(CASE COALESCE(ss_%s.status, ''not_started'')
               WHEN ''not_started'' THEN 0
               WHEN ''in_progress'' THEN 1
               ELSE 2
             END)',
            v_idx
          )
        WHEN 'in_progress_first' THEN
          format(
            '(CASE COALESCE(ss_%s.status, ''not_started'')
               WHEN ''in_progress'' THEN 0
               WHEN ''completed'' THEN 1
               ELSE 2
             END)',
            v_idx
          )
        ELSE
          format(
            '(CASE COALESCE(ss_%s.status, ''not_started'')
               WHEN ''completed'' THEN 0
               WHEN ''not_started'' THEN 1
               ELSE 2
             END)',
            v_idx
          )
      END;

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;

      IF v_survey_order IS NOT NULL THEN
        v_order := v_order || v_sort_expr || ' ASC';
      ELSE
        v_order := v_order || v_sort_expr || ' ' || upper(v_order_dir);
      END IF;

      CONTINUE;
    END IF;

    IF v_column = 'last_request' THEN
      v_joins := v_joins || format(
        ' LEFT JOIN LATERAL (
            SELECT MAX(r.created_at) AS created_at
            FROM public.request r
            WHERE r.contact_id = b.id
          ) lr_%s ON true',
        v_idx
      );

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'lr_%s.created_at %s NULLS %s',
        v_idx,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    END IF;

    IF v_column = 'name' OR v_column = 'surname' THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'COALESCE(b.surname, '''') %s, COALESCE(b.firstname, '''') %s',
        upper(v_order_dir),
        upper(v_order_dir)
      );
      CONTINUE;
    END IF;

    IF v_column = 'dob' THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'b.birthyear %s NULLS %s, b.birthmonth %s NULLS %s, b.birthdate %s NULLS %s',
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
      CONTINUE;
    END IF;

    IF v_column = 'id' THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format('b.id %s', upper(v_order_dir));
      CONTINUE;
    END IF;

    -- Custom column sort by custom column name.
    SELECT cc.id, cc.data_type
    INTO v_custom_id, v_custom_type
    FROM public.custom_columns cc
    WHERE cc.name = v_column
    LIMIT 1;

    IF v_custom_id IS NOT NULL THEN
      v_joins := v_joins || format(
        ' LEFT JOIN public.contact_custom_fields ccf_%s
            ON ccf_%s.contact_id = b.id
           AND ccf_%s.column_id = %s',
        v_idx,
        v_idx,
        v_idx,
        v_custom_id
      );

      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;

      v_order := v_order || format(
        'ccf_%s.%I %s NULLS %s',
        v_idx,
        CASE
          WHEN v_custom_type = 'select' THEN 'value_text'
          ELSE 'value_' || v_custom_type
        END,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );

      v_custom_id := NULL;
      v_custom_type := NULL;
      CONTINUE;
    END IF;

    -- Standard mapped/display key columns.
    v_db_column := CASE v_column
      WHEN 'riding' THEN 'division_electoral_district'
      WHEN 'campusClub' THEN 'campus_club'
      WHEN 'rideRequest' THEN 'ride_request_status'
      WHEN 'contactStatus' THEN 'contact_status'
      WHEN 'postal_code' THEN 'postcode'
      ELSE v_column
    END;

    SELECT EXISTS (
      SELECT 1
      FROM information_schema.columns c
      WHERE c.table_schema = 'public'
        AND c.table_name = 'contact'
        AND c.column_name = v_db_column
    )
    INTO v_col_exists;

    IF v_col_exists THEN
      IF v_order <> '' THEN
        v_order := v_order || ', ';
      END IF;
      v_order := v_order || format(
        'b.%I %s NULLS %s',
        v_db_column,
        upper(v_order_dir),
        CASE WHEN v_order_dir = 'asc' THEN 'LAST' ELSE 'FIRST' END
      );
    END IF;
  END LOOP;

  IF v_order = '' THEN
    v_order := 'b.id ASC';
  ELSE
    v_order := v_order || ', b.id ASC';
  END IF;

  v_sql := '
    WITH base AS (
      SELECT c.*
      FROM public.contact c
      WHERE c.id = ANY($1::bigint[])
        AND (c.contact_status IS NULL OR c.contact_status <> ''archived'')
    ),
    ordered AS (
      SELECT
        b.id AS contact_id,
        COUNT(*) OVER() AS total_count
      FROM base b
      ' || v_joins || '
      ORDER BY ' || v_order || '
    )
    SELECT o.contact_id, o.total_count
    FROM ordered o
    LIMIT $2
    OFFSET $3
  ';

  RETURN QUERY EXECUTE v_sql USING p_contact_ids, v_limit, v_offset;
END;
$$;

COMMENT ON FUNCTION public.load_contact_list_page_ids(bigint[], jsonb, integer, integer) IS
  'Returns ordered contact IDs and total_count for a pre-filtered contact ID set using server-side sort rules (survey_status, custom columns, last_request, and standard columns).';
