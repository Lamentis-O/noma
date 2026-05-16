alter table public.user_entitlements
  add column if not exists transaction_id text;

alter table public.subscription_events
  add column if not exists event_id text,
  add column if not exists transaction_id text,
  add column if not exists environment text,
  add column if not exists processed_at timestamptz not null default now();

create unique index if not exists subscription_events_event_id_unique
on public.subscription_events (event_id);

create index if not exists subscription_events_transaction_id_idx
on public.subscription_events (transaction_id)
where transaction_id is not null;

create index if not exists subscription_events_original_transaction_id_idx
on public.subscription_events (original_transaction_id)
where original_transaction_id is not null;

create index if not exists user_entitlements_original_transaction_id_idx
on public.user_entitlements (original_transaction_id)
where original_transaction_id is not null;

revoke all on table public.subscription_events from anon, authenticated;
revoke all on table public.user_entitlements from anon, authenticated;
grant select on table public.user_entitlements to authenticated;
