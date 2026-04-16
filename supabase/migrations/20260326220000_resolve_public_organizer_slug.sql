-- Public-site short links: resolve URL slug to canonical profiles.organizer_tag.
-- Used by public_site_api GET /organizers/resolve (service role only).

create or replace function public.resolve_public_organizer_slug(p_input text)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_raw text := nullif(trim(p_input), '');
  v_low text;
  v_canonical text;
begin
  if v_raw is null then
    return null;
  end if;
  v_low := lower(v_raw);

  -- 1) Active organizer short code -> linked profile's primary organizer tag
  select p.organizer_tag into v_canonical
  from organizer_code oc
  join organizer_code_profiles ocp on ocp.code = oc.code
  join profiles p on p.id = ocp.profile_id
  where oc.is_active = true
    and lower(oc.code) = v_low
    and p.organizer_tag is not null
    and p.organizer_tag != ''
  order by ocp.profile_id
  limit 1;

  if v_canonical is not null then
    return v_canonical;
  end if;

  -- 2) Primary organizer tag on profile (case-insensitive)
  select p.organizer_tag into v_canonical
  from profiles p
  where lower(p.organizer_tag) = v_low
    and p.organizer_tag is not null
    and p.organizer_tag != ''
  order by p.id
  limit 1;

  if v_canonical is not null then
    return v_canonical;
  end if;

  -- 3) Secondary organizer tags -> that profile's primary organizer tag
  select p.organizer_tag into v_canonical
  from profile_organizer_tags pot
  join profiles p on p.id = pot.profile_id
  where lower(pot.tag) = v_low
    and p.organizer_tag is not null
    and p.organizer_tag != ''
  order by p.id
  limit 1;

  return v_canonical;
end;
$$;

revoke all on function public.resolve_public_organizer_slug(text) from public;
grant execute on function public.resolve_public_organizer_slug(text) to service_role;
