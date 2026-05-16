create type public.subscription_tier as enum ('free', 'pro');
create type public.entitlement_status as enum (
  'active',
  'grace_period',
  'billing_retry',
  'expired',
  'revoked'
);

create table public.user_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tier public.subscription_tier not null default 'free',
  status public.entitlement_status not null default 'active',
  product_id text,
  original_transaction_id text,
  app_account_token uuid not null unique default gen_random_uuid(),
  expires_at timestamptz,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscription_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  original_transaction_id text,
  product_id text,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now()
);

alter table public.user_entitlements enable row level security;
alter table public.subscription_events enable row level security;

grant select on table public.user_entitlements to authenticated;
revoke all on table public.subscription_events from anon, authenticated;

create policy "Users can read own entitlement"
on public.user_entitlements
for select
to authenticated
using ((select auth.uid()) = user_id);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_user_entitlements_updated_at
before update on public.user_entitlements
for each row
execute function public.set_updated_at();
