create table if not exists thebudolfinds.seo_daily_runs (
  run_date date not null,
  site_url text not null,
  evidence jsonb not null default '{}'::jsonb,
  decisions jsonb not null default '[]'::jsonb,
  actions jsonb not null default '[]'::jsonb,
  validation jsonb not null default '{}'::jsonb,
  next_action text not null,
  created_at timestamptz not null default now(),
  primary key (run_date, site_url)
);

alter table thebudolfinds.seo_daily_runs enable row level security;
revoke all on table thebudolfinds.seo_daily_runs from public, anon, authenticated;
grant select, insert, update, delete on table thebudolfinds.seo_daily_runs to service_role;
