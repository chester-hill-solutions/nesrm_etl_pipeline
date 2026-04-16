-- Enable row level security for the donations table
alter table if exists public.donation
  enable row level security;
