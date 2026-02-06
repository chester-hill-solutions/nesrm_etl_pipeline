-- Allow authenticated users to read contacts assigned to their organizer tags
create policy "allow authenticated contacts by tag"
  on public.contact
  for select
  to authenticated
  using (
    contact.organizer is not null
    and (
      exists (
        select 1
        from public.profiles p
        where p.id = auth.uid()
          and p.organizer_tag is not null
          and contact.organizer ilike '%' || p.organizer_tag || '%'
      )
      or exists (
        select 1
        from public.profile_organizer_tags pot
        where pot.profile_id = auth.uid()
          and pot.tag is not null
          and contact.organizer ilike '%' || pot.tag || '%'
      )
    )
  );
