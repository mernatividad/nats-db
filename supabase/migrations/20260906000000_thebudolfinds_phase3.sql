create table if not exists thebudolfinds.import_runs (
  id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('manual_json', 'manual_csv')),
  status text not null check (status in ('completed', 'quarantined', 'failed')),
  accepted_count integer not null default 0,
  quarantined_count integer not null default 0,
  errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists thebudolfinds.import_quarantine (
  id uuid primary key default gen_random_uuid(),
  import_run_id uuid not null references thebudolfinds.import_runs(id) on delete cascade,
  record_index integer not null,
  payload jsonb not null,
  error_message text not null,
  created_at timestamptz not null default now()
);

alter table thebudolfinds.import_runs enable row level security;
alter table thebudolfinds.import_quarantine enable row level security;
revoke all on thebudolfinds.import_runs, thebudolfinds.import_quarantine from anon, authenticated;
grant all on thebudolfinds.import_runs, thebudolfinds.import_quarantine to service_role;

create index if not exists import_quarantine_run_idx on thebudolfinds.import_quarantine (import_run_id, record_index);
