create table if not exists board_pulse.notification_admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('global', 'exam')),
  exam_id uuid references board_pulse.exams(id) on delete set null,
  channel text not null check (channel in ('all', 'email', 'push')),
  enabled boolean not null,
  reason text not null check (char_length(reason) between 10 and 500),
  created_at timestamptz not null default now(),
  check ((scope = 'global' and exam_id is null) or (scope = 'exam' and exam_id is not null))
);

create index if not exists notification_admin_audit_logs_created_at_idx
  on board_pulse.notification_admin_audit_logs (created_at desc);

alter table board_pulse.notification_admin_audit_logs enable row level security;
revoke all on table board_pulse.notification_admin_audit_logs from anon, authenticated;
grant insert, select on table board_pulse.notification_admin_audit_logs to service_role;

notify pgrst, 'reload schema';
