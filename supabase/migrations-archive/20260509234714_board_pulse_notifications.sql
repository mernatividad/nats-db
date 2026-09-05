-- Notification and alert infrastructure for PRC Board Pulse.

create extension if not exists pgcrypto;

create table if not exists board_pulse.email_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  email_normalized text not null,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'unsubscribed', 'bounced', 'complained')),
  verification_token_hash text null,
  verified_at timestamptz null,
  created_at timestamptz not null default now(),
  unsubscribed_at timestamptz null
);

create unique index if not exists email_subscribers_email_normalized_key
  on board_pulse.email_subscribers (email_normalized);

create table if not exists board_pulse.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  user_agent text null,
  created_at timestamptz not null default now(),
  last_used_at timestamptz null,
  revoked_at timestamptz null
);

create unique index if not exists push_subscriptions_endpoint_key
  on board_pulse.push_subscriptions (endpoint);

create table if not exists board_pulse.alert_subscriptions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references board_pulse.exams(id) on delete cascade,
  alert_type text not null
    check (alert_type in ('result_release', 'name_match', 'room_assignment', 'application_deadline')),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'triggered', 'cancelled', 'expired')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz null,
  cancelled_at timestamptz null,
  expires_at timestamptz null
);

create index if not exists alert_subscriptions_exam_status_idx
  on board_pulse.alert_subscriptions (exam_id, alert_type, status);

create table if not exists board_pulse.alert_channels (
  id uuid primary key default gen_random_uuid(),
  alert_subscription_id uuid not null references board_pulse.alert_subscriptions(id) on delete cascade,
  channel text not null check (channel in ('email', 'push')),
  email_subscriber_id uuid null references board_pulse.email_subscribers(id) on delete cascade,
  push_subscription_id uuid null references board_pulse.push_subscriptions(id) on delete cascade,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  check (
    (channel = 'email' and email_subscriber_id is not null and push_subscription_id is null)
    or
    (channel = 'push' and push_subscription_id is not null and email_subscriber_id is null)
  )
);

create index if not exists alert_channels_subscription_idx
  on board_pulse.alert_channels (alert_subscription_id, enabled);

create table if not exists board_pulse.name_alerts (
  id uuid primary key default gen_random_uuid(),
  alert_subscription_id uuid not null references board_pulse.alert_subscriptions(id) on delete cascade,
  full_name text not null,
  normalized_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists name_alerts_normalized_name_idx
  on board_pulse.name_alerts (normalized_name);

create table if not exists board_pulse.notification_events (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references board_pulse.exams(id) on delete cascade,
  event_type text not null,
  event_key text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  processed_at timestamptz null,
  unique (event_key)
);

create index if not exists notification_events_unprocessed_idx
  on board_pulse.notification_events (created_at)
  where processed_at is null;

create table if not exists board_pulse.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  event_id uuid null references board_pulse.notification_events(id) on delete cascade,
  subscription_id uuid not null references board_pulse.alert_subscriptions(id) on delete cascade,
  channel text not null check (channel in ('email', 'push')),
  destination_id uuid not null,
  status text not null default 'queued'
    check (status in ('queued', 'sending', 'sent', 'failed', 'suppressed')),
  attempt_count integer not null default 0,
  provider_message_id text null,
  payload jsonb not null default '{}'::jsonb,
  next_attempt_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  sent_at timestamptz null,
  failed_at timestamptz null,
  error text null
);

create index if not exists notification_deliveries_queue_idx
  on board_pulse.notification_deliveries (status, next_attempt_at);

create table if not exists board_pulse.notification_settings (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('global', 'exam')),
  exam_id uuid null references board_pulse.exams(id) on delete cascade,
  email_enabled boolean not null default true,
  push_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((scope = 'global' and exam_id is null) or (scope = 'exam' and exam_id is not null))
);

create unique index if not exists notification_settings_global_key
  on board_pulse.notification_settings (scope)
  where scope = 'global';

create unique index if not exists notification_settings_exam_key
  on board_pulse.notification_settings (exam_id)
  where scope = 'exam';

alter table board_pulse.alert_subscriptions enable row level security;
alter table board_pulse.email_subscribers enable row level security;
alter table board_pulse.push_subscriptions enable row level security;
alter table board_pulse.alert_channels enable row level security;
alter table board_pulse.name_alerts enable row level security;
alter table board_pulse.notification_events enable row level security;
alter table board_pulse.notification_deliveries enable row level security;
alter table board_pulse.notification_settings enable row level security;

drop policy if exists "service role manages alert subscriptions" on board_pulse.alert_subscriptions;
create policy "service role manages alert subscriptions"
  on board_pulse.alert_subscriptions for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages email subscribers" on board_pulse.email_subscribers;
create policy "service role manages email subscribers"
  on board_pulse.email_subscribers for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages push subscriptions" on board_pulse.push_subscriptions;
create policy "service role manages push subscriptions"
  on board_pulse.push_subscriptions for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages alert channels" on board_pulse.alert_channels;
create policy "service role manages alert channels"
  on board_pulse.alert_channels for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages name alerts" on board_pulse.name_alerts;
create policy "service role manages name alerts"
  on board_pulse.name_alerts for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages notification events" on board_pulse.notification_events;
create policy "service role manages notification events"
  on board_pulse.notification_events for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages notification deliveries" on board_pulse.notification_deliveries;
create policy "service role manages notification deliveries"
  on board_pulse.notification_deliveries for all
  to service_role
  using (true)
  with check (true);

drop policy if exists "service role manages notification settings" on board_pulse.notification_settings;
create policy "service role manages notification settings"
  on board_pulse.notification_settings for all
  to service_role
  using (true)
  with check (true);

grant select, insert, update, delete on board_pulse.alert_subscriptions to service_role;
grant select, insert, update, delete on board_pulse.email_subscribers to service_role;
grant select, insert, update, delete on board_pulse.push_subscriptions to service_role;
grant select, insert, update, delete on board_pulse.alert_channels to service_role;
grant select, insert, update, delete on board_pulse.name_alerts to service_role;
grant select, insert, update, delete on board_pulse.notification_events to service_role;
grant select, insert, update, delete on board_pulse.notification_deliveries to service_role;
grant select, insert, update, delete on board_pulse.notification_settings to service_role;

notify pgrst, 'reload schema';
