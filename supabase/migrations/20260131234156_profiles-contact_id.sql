-- Add contact linkage to profiles
alter table public.profiles
  add column if not exists contact_id bigint;

alter table public.profiles
  add constraint profiles_contact_id_fkey
    foreign key (contact_id) references public.contact(id)
    on update cascade
    on delete set null;

create index if not exists profiles_contact_id_idx
  on public.profiles(contact_id);
