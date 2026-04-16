-- Fill migration gaps: events.visible_to_roles
ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS visible_to_roles public.role_type[]
  NOT NULL
  DEFAULT ARRAY['super_admin', 'admin', 'member', 'developer']::public.role_type[];

-- Fill migration gaps: events_sync_config.ics_urls
ALTER TABLE public.events_sync_config
  ADD COLUMN IF NOT EXISTS ics_urls text[]
  NOT NULL
  DEFAULT '{}'::text[];

-- Fill migration gaps: events_sync_config.auth_token nullability
ALTER TABLE public.events_sync_config
  ALTER COLUMN auth_token DROP NOT NULL;

-- Fill migration gaps: i18n catalogs
CREATE TABLE IF NOT EXISTS public.i18n_catalog_versions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  catalog_locale text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  created_by uuid,
  notes text,
  strings jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE IF NOT EXISTS public.i18n_catalogs (
  locale text NOT NULL,
  published_version_id uuid,
  draft_version_id uuid,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'i18n_catalog_versions_pkey'
      AND conrelid = 'public.i18n_catalog_versions'::regclass
  ) THEN
    ALTER TABLE ONLY public.i18n_catalog_versions
      ADD CONSTRAINT i18n_catalog_versions_pkey PRIMARY KEY (id);
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'i18n_catalogs_pkey'
      AND conrelid = 'public.i18n_catalogs'::regclass
  ) THEN
    ALTER TABLE ONLY public.i18n_catalogs
      ADD CONSTRAINT i18n_catalogs_pkey PRIMARY KEY (locale);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS i18n_catalog_versions_locale_created_at_idx
  ON public.i18n_catalog_versions USING btree (catalog_locale, created_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'i18n_catalog_versions_catalog_locale_fkey'
      AND conrelid = 'public.i18n_catalog_versions'::regclass
  ) THEN
    ALTER TABLE ONLY public.i18n_catalog_versions
      ADD CONSTRAINT i18n_catalog_versions_catalog_locale_fkey
      FOREIGN KEY (catalog_locale) REFERENCES public.i18n_catalogs(locale) ON DELETE CASCADE;
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'i18n_catalogs_draft_version_id_fkey'
      AND conrelid = 'public.i18n_catalogs'::regclass
  ) THEN
    ALTER TABLE ONLY public.i18n_catalogs
      ADD CONSTRAINT i18n_catalogs_draft_version_id_fkey
      FOREIGN KEY (draft_version_id) REFERENCES public.i18n_catalog_versions(id) ON DELETE SET NULL;
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'i18n_catalogs_published_version_id_fkey'
      AND conrelid = 'public.i18n_catalogs'::regclass
  ) THEN
    ALTER TABLE ONLY public.i18n_catalogs
      ADD CONSTRAINT i18n_catalogs_published_version_id_fkey
      FOREIGN KEY (published_version_id) REFERENCES public.i18n_catalog_versions(id) ON DELETE SET NULL;
  END IF;
END;
$$;

ALTER TABLE public.i18n_catalog_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.i18n_catalogs ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.i18n_catalog_versions TO anon;
GRANT ALL ON TABLE public.i18n_catalog_versions TO authenticated;
GRANT ALL ON TABLE public.i18n_catalog_versions TO service_role;

GRANT ALL ON TABLE public.i18n_catalogs TO anon;
GRANT ALL ON TABLE public.i18n_catalogs TO authenticated;
GRANT ALL ON TABLE public.i18n_catalogs TO service_role;
