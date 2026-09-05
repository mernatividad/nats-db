create table if not exists board_pulse.notification_analytics_events (
  id uuid primary key default gen_random_uuid(),
  event_name text not null check (event_name in (
    'alert_cta_impression', 'alert_cta_click', 'permission_result',
    'verification_completed', 'delivery_queued', 'delivery_sent',
    'delivery_failed', 'delivery_retry', 'provider_revoked'
  )),
  correlation_id text,
  exam_id uuid references board_pulse.exams(id) on delete set null,
  alert_type text,
  channel text check (channel in ('email', 'push')),
  outcome text,
  latency_ms integer check (latency_ms is null or (latency_ms >= 0 and latency_ms <= 600000)),
  result_count integer check (result_count is null or (result_count >= 0 and result_count <= 100000)),
  error_code text check (error_code is null or error_code ~ '^[a-z0-9_:-]+$'),
  created_at timestamptz not null default now()
);

create index if not exists notification_analytics_events_created_at_idx
  on board_pulse.notification_analytics_events (created_at desc);

alter table board_pulse.notification_analytics_events enable row level security;
revoke all on table board_pulse.notification_analytics_events from anon, authenticated;
grant select, insert on table board_pulse.notification_analytics_events to service_role;

notify pgrst, 'reload schema';
