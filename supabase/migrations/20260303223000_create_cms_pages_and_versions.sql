-- Migration: Create CMS page + version tables for nes-olp26 CMS editor
-- Used by: /Users/ladmin/WebProjects/nes-olp26/app/utils/cms.server.ts

begin;

-- ============================================================================
-- CMS PAGES
-- ============================================================================

create table if not exists public.cms_pages (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  published_version_id uuid,
  draft_version_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cms_pages_slug_format_chk check (slug ~ '^[a-zA-Z0-9][a-zA-Z0-9/-]{0,64}$')
);

create unique index if not exists cms_pages_slug_uniq_idx on public.cms_pages (slug);

comment on table public.cms_pages is 'CMS page pointers. published_version_id is what the site serves; draft_version_id is what admins edit.';
comment on column public.cms_pages.slug is 'URL slug (e.g. home, about/team).';

-- ============================================================================
-- CMS PAGE VERSIONS
-- ============================================================================

create table if not exists public.cms_page_versions (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.cms_pages(id) on delete cascade,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  notes text,
  blocks jsonb not null default '[]'::jsonb,
  page_css text,
  page_js text,
  seo jsonb not null default '{}'::jsonb,
  constraint cms_page_versions_blocks_json_chk check (jsonb_typeof(blocks) = 'array'),
  constraint cms_page_versions_seo_json_chk check (jsonb_typeof(seo) = 'object')
);

create index if not exists cms_page_versions_page_id_created_at_idx
  on public.cms_page_versions (page_id, created_at desc);

comment on table public.cms_page_versions is 'Immutable CMS page versions. Saving creates a new row and updates cms_pages.draft_version_id.';

-- ============================================================================
-- FOREIGN KEYS (added after both tables exist to avoid circular creation issues)
-- ============================================================================

alter table public.cms_pages
  add constraint cms_pages_published_version_fk
  foreign key (published_version_id) references public.cms_page_versions(id) on delete set null;

alter table public.cms_pages
  add constraint cms_pages_draft_version_fk
  foreign key (draft_version_id) references public.cms_page_versions(id) on delete set null;

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

create or replace function public.set_updated_at_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_cms_pages_updated_at on public.cms_pages;
create trigger set_cms_pages_updated_at
before update on public.cms_pages
for each row execute function public.set_updated_at_timestamp();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

alter table public.cms_pages enable row level security;
alter table public.cms_page_versions enable row level security;

drop policy if exists "Allow service manage cms_pages" on public.cms_pages;
create policy "Allow service manage cms_pages" on public.cms_pages
  to service_role using (true) with check (true);

drop policy if exists "Allow service manage cms_page_versions" on public.cms_page_versions;
create policy "Allow service manage cms_page_versions" on public.cms_page_versions
  to service_role using (true) with check (true);

grant all on public.cms_pages to service_role;
grant all on public.cms_page_versions to service_role;
grant all on public.cms_pages to anon, authenticated;
grant all on public.cms_page_versions to anon, authenticated;

commit;

