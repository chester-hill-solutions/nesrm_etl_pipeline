-- Global app settings for CRM.
-- Used initially for storing editable default survey button status rules.

create table if not exists "public"."app_settings" (
  "key" text primary key,
  "value" jsonb not null,
  "updated_at" timestamptz not null default now()
);

alter table "public"."app_settings" enable row level security;

create or replace function "public"."get_app_setting"("p_key" text)
  returns jsonb
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_value jsonb;
begin
  select "value"
  into v_value
  from "public"."app_settings"
  where "key" = p_key;

  return v_value;
end;
$$;

grant execute on function "public"."get_app_setting"("p_key" text) to "anon", "authenticated", "service_role";

