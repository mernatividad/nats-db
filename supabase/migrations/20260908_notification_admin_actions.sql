create table if not exists board_pulse.notification_admin_actions (
  id uuid primary key default gen_random_uuid(),
  action text not null check (action in ('test_send')),
  channel text not null check (channel in ('email', 'push')),
  outcome text not null check (outcome in ('sent', 'failed')),
  created_at timestamptz not null default now()
);

create index if not exists notification_admin_actions_created_at_idx
  on board_pulse.notification_admin_actions (created_at desc);

alter table board_pulse.notification_admin_actions enable row level security;
revoke all on table board_pulse.notification_admin_actions from anon, authenticated;
grant insert, select on table board_pulse.notification_admin_actions to service_role;

notify pgrst, 'reload schema';
