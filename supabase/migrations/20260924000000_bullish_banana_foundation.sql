-- Bullish Banana application foundation.
-- Better Auth owns identity and sessions; Supabase provides PostgreSQL and storage.
-- Keep all application objects in the bullish_banana schema.

-- The existing bullish_banana schema was verified empty before this migration.
drop schema if exists bullish_banana cascade;
create schema if not exists bullish_banana;
create extension if not exists pgcrypto with schema extensions;

set search_path = bullish_banana, extensions, public;

create table bullish_banana.users (
  id text primary key,
  name text not null,
  email text not null unique,
  email_verified boolean not null default false,
  image text,
  role text not null default 'user' check (role in ('user', 'editor', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table bullish_banana.sessions (
  id text primary key,
  expires_at timestamptz not null,
  token text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  ip_address text,
  user_agent text,
  user_id text not null references bullish_banana.users(id) on delete cascade
);

create table bullish_banana.accounts (
  id text primary key,
  account_id text not null,
  provider_id text not null,
  user_id text not null references bullish_banana.users(id) on delete cascade,
  access_token text,
  refresh_token text,
  id_token text,
  access_token_expires_at timestamptz,
  refresh_token_expires_at timestamptz,
  scope text,
  password text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider_id, account_id)
);

create table bullish_banana.verifications (
  id text primary key,
  identifier text not null,
  value text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table bullish_banana.profiles (
  id text primary key references bullish_banana.users(id) on delete cascade,
  display_name text,
  country_code text,
  notify_digest_email boolean not null default true,
  notify_watchlist_email boolean not null default true,
  anonymized_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table bullish_banana.firms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  website_url text not null,
  logo_url text,
  status text not null default 'draft' check (status in ('draft', 'in_review', 'published', 'archived')),
  ranking_score numeric(6,3),
  ranking_methodology_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  archived_at timestamptz
);

create table bullish_banana.programs (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references bullish_banana.firms(id) on delete cascade,
  name text not null,
  slug text not null,
  description text,
  program_type text not null default 'evaluation' check (program_type in ('evaluation', 'instant_funding', 'funded_account', 'other')),
  status text not null default 'draft' check (status in ('draft', 'in_review', 'published', 'archived')),
  currency text not null default 'USD',
  account_sizes jsonb not null default '[]'::jsonb,
  max_leverage numeric(8,2),
  profit_split_percent numeric(5,2),
  payout_frequency text,
  minimum_trading_days integer,
  news_allowed boolean,
  weekend_holding_allowed boolean,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  archived_at timestamptz,
  unique (firm_id, slug)
);

create table bullish_banana.program_phases (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references bullish_banana.programs(id) on delete cascade,
  phase_number integer not null check (phase_number > 0),
  name text not null,
  fee numeric(12,2),
  profit_target_percent numeric(6,3),
  daily_drawdown_percent numeric(6,3),
  maximum_drawdown_percent numeric(6,3),
  drawdown_type text,
  time_limit_days integer,
  minimum_trading_days integer,
  raw_rules jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (program_id, phase_number)
);

create table bullish_banana.platforms (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table bullish_banana.program_platforms (
  program_id uuid not null references bullish_banana.programs(id) on delete cascade,
  platform_id uuid not null references bullish_banana.platforms(id) on delete restrict,
  primary key (program_id, platform_id)
);

create table bullish_banana.restrictions (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references bullish_banana.firms(id) on delete cascade,
  country_code text not null,
  restriction_type text not null default 'restricted' check (restriction_type in ('restricted', 'allowed', 'unknown')),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (firm_id, country_code)
);

create table bullish_banana.sources (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid references bullish_banana.firms(id) on delete cascade,
  program_id uuid references bullish_banana.programs(id) on delete cascade,
  source_url text not null,
  source_label text not null,
  notes text,
  captured_at timestamptz not null default now(),
  created_by text references bullish_banana.users(id) on delete set null,
  check (firm_id is not null or program_id is not null)
);

create table bullish_banana.data_verifications (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid references bullish_banana.firms(id) on delete cascade,
  program_id uuid references bullish_banana.programs(id) on delete cascade,
  verified_at timestamptz not null default now(),
  verified_by text references bullish_banana.users(id) on delete set null,
  notes text,
  check (firm_id is not null or program_id is not null)
);

create table bullish_banana.affiliate_destinations (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references bullish_banana.firms(id) on delete cascade,
  program_id uuid references bullish_banana.programs(id) on delete cascade,
  kind text not null check (kind in ('affiliate', 'official_site')),
  label text not null,
  destination_url text not null,
  network text,
  is_primary boolean not null default false,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (destination_url ~ '^https://'),
  check (kind = 'official_site' or network is not null)
);

create table bullish_banana.affiliate_clicks (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid references bullish_banana.affiliate_destinations(id) on delete set null,
  firm_id uuid references bullish_banana.firms(id) on delete set null,
  program_id uuid references bullish_banana.programs(id) on delete set null,
  page_path text not null,
  placement text not null,
  destination_kind text not null check (destination_kind in ('affiliate', 'official_site')),
  anonymous_id text,
  created_at timestamptz not null default now()
);

create table bullish_banana.data_reports (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid references bullish_banana.firms(id) on delete set null,
  program_id uuid references bullish_banana.programs(id) on delete set null,
  field_name text,
  details text not null,
  reporter_id text references bullish_banana.users(id) on delete set null,
  status text not null default 'open' check (status in ('open', 'triaged', 'resolved', 'rejected')),
  resolved_by text references bullish_banana.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check (firm_id is not null or program_id is not null)
);

create table bullish_banana.reviews (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references bullish_banana.firms(id) on delete cascade,
  program_id uuid references bullish_banana.programs(id) on delete set null,
  author_id text not null references bullish_banana.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  title text not null,
  body text not null,
  status text not null default 'pending' check (status in ('pending', 'published', 'rejected', 'removed')),
  moderated_by text references bullish_banana.users(id) on delete set null,
  moderated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table bullish_banana.saved_items (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references bullish_banana.users(id) on delete cascade,
  firm_id uuid references bullish_banana.firms(id) on delete cascade,
  program_id uuid references bullish_banana.programs(id) on delete cascade,
  created_at timestamptz not null default now(),
  check ((firm_id is not null) <> (program_id is not null))
);

create unique index saved_firm_unique_idx on bullish_banana.saved_items (user_id, firm_id)
  where firm_id is not null;
create unique index saved_program_unique_idx on bullish_banana.saved_items (user_id, program_id)
  where program_id is not null;

create table bullish_banana.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id text references bullish_banana.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  before_state jsonb,
  after_state jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create index sessions_user_id_idx on bullish_banana.sessions (user_id);
create index accounts_user_id_idx on bullish_banana.accounts (user_id);
create index verifications_identifier_idx on bullish_banana.verifications (identifier);
create index firms_status_idx on bullish_banana.firms (status);
create index programs_firm_status_idx on bullish_banana.programs (firm_id, status);
create index program_phases_program_idx on bullish_banana.program_phases (program_id, phase_number);
create index restrictions_country_idx on bullish_banana.restrictions (country_code);
create index sources_firm_idx on bullish_banana.sources (firm_id, captured_at desc);
create index sources_program_idx on bullish_banana.sources (program_id, captured_at desc);
create index data_verifications_firm_idx on bullish_banana.data_verifications (firm_id, verified_at desc);
create index data_verifications_program_idx on bullish_banana.data_verifications (program_id, verified_at desc);
create index affiliate_destinations_firm_idx on bullish_banana.affiliate_destinations (firm_id, status);
create index affiliate_clicks_firm_time_idx on bullish_banana.affiliate_clicks (firm_id, created_at desc);
create index affiliate_clicks_program_time_idx on bullish_banana.affiliate_clicks (program_id, created_at desc);
create index data_reports_status_time_idx on bullish_banana.data_reports (status, created_at desc);
create index reviews_firm_status_idx on bullish_banana.reviews (firm_id, status, created_at desc);
create index reviews_program_status_idx on bullish_banana.reviews (program_id, status, created_at desc);
create index audit_logs_target_time_idx on bullish_banana.audit_logs (target_type, target_id, created_at desc);

alter table bullish_banana.users enable row level security;
alter table bullish_banana.sessions enable row level security;
alter table bullish_banana.accounts enable row level security;
alter table bullish_banana.verifications enable row level security;
alter table bullish_banana.profiles enable row level security;
alter table bullish_banana.firms enable row level security;
alter table bullish_banana.programs enable row level security;
alter table bullish_banana.program_phases enable row level security;
alter table bullish_banana.platforms enable row level security;
alter table bullish_banana.program_platforms enable row level security;
alter table bullish_banana.restrictions enable row level security;
alter table bullish_banana.sources enable row level security;
alter table bullish_banana.data_verifications enable row level security;
alter table bullish_banana.affiliate_destinations enable row level security;
alter table bullish_banana.affiliate_clicks enable row level security;
alter table bullish_banana.data_reports enable row level security;
alter table bullish_banana.reviews enable row level security;
alter table bullish_banana.saved_items enable row level security;
alter table bullish_banana.audit_logs enable row level security;

-- Application access is server-side. Better Auth and privileged repositories use service_role.
revoke all on all tables in schema bullish_banana from anon, authenticated;
grant usage on schema bullish_banana to service_role;
grant all on all tables in schema bullish_banana to service_role;
grant all on all sequences in schema bullish_banana to service_role;

grant usage on schema bullish_banana to anon, authenticated;
grant select on bullish_banana.firms, bullish_banana.programs, bullish_banana.program_phases,
  bullish_banana.platforms, bullish_banana.program_platforms, bullish_banana.restrictions,
  bullish_banana.sources, bullish_banana.data_verifications, bullish_banana.affiliate_destinations,
  bullish_banana.reviews to anon, authenticated;
grant insert on bullish_banana.affiliate_clicks, bullish_banana.data_reports to anon, authenticated;

alter role authenticator set pgrst.db_schemas = 'public, graphql_public, board_pulse, wheretayo, japanprchecker, bullish_banana';
notify pgrst, 'reload config';
