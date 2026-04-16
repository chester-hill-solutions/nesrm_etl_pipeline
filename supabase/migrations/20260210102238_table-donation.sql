-- Create Stripe donation table
create table if not exists public.donation (
  id uuid primary key default gen_random_uuid(),
  contact_id bigint references public.contact(id) on delete set null,
  stripe_payment_intent_id text not null,
  status text not null default 'requires_payment_method' check (status in (
    'requires_payment_method',
    'requires_confirmation',
    'processing',
    'succeeded',
    'canceled',
    'requires_action',
    'requires_capture'
  )),
  cents bigint not null check (cents >= 0),
  currency text not null default 'usd',
  payment_method_types text[], -- nullable
  customer_id text,
  receipt_email text,
  description text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (stripe_payment_intent_id)
);

comment on table public.donation is 'Tracks Stripe PaymentIntent-backed donations.';
comment on column public.donation.contact_id is 'Optional contact associated to the donation.';
comment on column public.donation.stripe_payment_intent_id is 'Stripe PaymentIntent ID for this donation.';
comment on column public.donation.status is 'Stripe PaymentIntent status snapshot.';
comment on column public.donation.cents is 'Donation amount in the smallest currency unit (e.g., cents).';
comment on column public.donation.currency is 'ISO currency code for the donation.';
comment on column public.donation.payment_method_types is 'Stripe PaymentIntent payment_method_types snapshot.';
comment on column public.donation.customer_id is 'Stripe Customer ID if available.';
comment on column public.donation.receipt_email is 'Email to send Stripe receipts.';
comment on column public.donation.description is 'Human-readable donation description.';
comment on column public.donation.metadata is 'Arbitrary JSON metadata.';
comment on column public.donation.created_at is 'Row creation timestamp.';
comment on column public.donation.updated_at is 'Last update timestamp.';

create index if not exists donation_contact_id_idx on public.donation(contact_id);
create index if not exists donation_status_idx on public.donation(status);

create or replace trigger donation_set_updated_at
before update on public.donation
for each row
execute function public.update_updated_at_column();
