-- Idempotency records for signed email provider bounce/complaint webhooks.

create table if not exists board_pulse.email_webhook_events (
  id text primary key,
  event_type text not null check (event_type in ('email.bounced', 'email.complained')),
  email_normalized text not null,
  payload_hash text not null,
  received_at timestamptz not null default now()
);

alter table board_pulse.email_webhook_events enable row level security;

drop policy if exists "service role manages email webhook events" on board_pulse.email_webhook_events;
create policy "service role manages email webhook events"
  on board_pulse.email_webhook_events for all
  to service_role
  using (true)
  with check (true);

grant select, insert on board_pulse.email_webhook_events to service_role;

notify pgrst, 'reload schema';
