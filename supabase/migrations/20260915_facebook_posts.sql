create table if not exists board_pulse.facebook_posts (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null unique references board_pulse.notification_events(id) on delete cascade,
  exam_id uuid not null references board_pulse.exams(id) on delete cascade,
  status text not null default 'queued' check (status in ('queued', 'sending', 'sent', 'failed')),
  attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  facebook_post_id text,
  facebook_permalink text,
  error text,
  lease_until timestamptz,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  failed_at timestamptz
);

create index if not exists facebook_posts_queue_idx
  on board_pulse.facebook_posts (status, next_attempt_at);

alter table board_pulse.facebook_posts enable row level security;
drop policy if exists "service role manages facebook posts" on board_pulse.facebook_posts;
create policy "service role manages facebook posts"
  on board_pulse.facebook_posts for all to service_role using (true) with check (true);
grant select, insert, update on board_pulse.facebook_posts to service_role;

alter table board_pulse.notification_admin_audit_logs
  drop constraint if exists notification_admin_audit_logs_channel_check;
alter table board_pulse.notification_admin_audit_logs
  add constraint notification_admin_audit_logs_channel_check check (channel in ('all', 'email', 'push', 'facebook'));
alter table board_pulse.notification_admin_actions
  drop constraint if exists notification_admin_actions_action_check;
alter table board_pulse.notification_admin_actions
  add constraint notification_admin_actions_action_check check (action in ('test_send', 'retry_facebook'));
alter table board_pulse.notification_admin_actions
  drop constraint if exists notification_admin_actions_channel_check;
alter table board_pulse.notification_admin_actions
  add constraint notification_admin_actions_channel_check check (channel in ('email', 'push', 'facebook'));

notify pgrst, 'reload schema';
