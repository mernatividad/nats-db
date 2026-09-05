-- Better Auth owns identity and sessions. Supabase provides PostgreSQL only.
set search_path = thebudolfinds, extensions, public;

create table thebudolfinds.users (
  id text primary key,
  name text not null,
  email text not null unique,
  email_verified boolean not null default false,
  image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table thebudolfinds.sessions (
  id text primary key,
  expires_at timestamptz not null,
  token text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  ip_address text,
  user_agent text,
  user_id text not null references thebudolfinds.users(id) on delete cascade
);

create table thebudolfinds.accounts (
  id text primary key,
  account_id text not null,
  provider_id text not null,
  user_id text not null references thebudolfinds.users(id) on delete cascade,
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

create table thebudolfinds.verifications (
  id text primary key,
  identifier text not null,
  value text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop policy if exists "profiles are self readable" on thebudolfinds.profiles;
drop policy if exists "profiles are self editable" on thebudolfinds.profiles;
drop policy if exists "reports are self readable" on thebudolfinds.reports;
drop policy if exists "reports are anonymously insertable" on thebudolfinds.reports;
drop policy if exists "affiliate clicks are insertable" on thebudolfinds.affiliate_clicks;
drop policy if exists "affiliate clicks are self readable" on thebudolfinds.affiliate_clicks;
drop policy if exists "moderators can manage reports" on thebudolfinds.reports;
drop policy if exists "admins can read audit logs" on thebudolfinds.audit_logs;
drop function if exists thebudolfinds.is_admin_or_moderator();

alter table thebudolfinds.profiles add column user_id_new text;
alter table thebudolfinds.reports add column reporter_id_new text;
alter table thebudolfinds.affiliate_clicks add column user_id_new text;
alter table thebudolfinds.audit_logs add column actor_id_new text;
alter table thebudolfinds.profiles drop constraint profiles_id_fkey;
alter table thebudolfinds.profiles drop constraint profiles_pkey;
alter table thebudolfinds.reports drop constraint reports_reporter_id_fkey;
alter table thebudolfinds.affiliate_clicks drop constraint affiliate_clicks_user_id_fkey;
alter table thebudolfinds.audit_logs drop constraint audit_logs_actor_id_fkey;
alter table thebudolfinds.profiles drop column id;
alter table thebudolfinds.reports drop column reporter_id;
alter table thebudolfinds.affiliate_clicks drop column user_id;
alter table thebudolfinds.audit_logs drop column actor_id;
alter table thebudolfinds.profiles rename column user_id_new to id;
alter table thebudolfinds.reports rename column reporter_id_new to reporter_id;
alter table thebudolfinds.affiliate_clicks rename column user_id_new to user_id;
alter table thebudolfinds.audit_logs rename column actor_id_new to actor_id;
alter table thebudolfinds.profiles add primary key (id);
alter table thebudolfinds.profiles add constraint profiles_user_fkey foreign key (id) references thebudolfinds.users(id) on delete cascade;
alter table thebudolfinds.reports add constraint reports_user_fkey foreign key (reporter_id) references thebudolfinds.users(id) on delete set null;
alter table thebudolfinds.affiliate_clicks add constraint affiliate_clicks_user_fkey foreign key (user_id) references thebudolfinds.users(id) on delete set null;
alter table thebudolfinds.audit_logs add constraint audit_logs_user_fkey foreign key (actor_id) references thebudolfinds.users(id) on delete set null;

alter table thebudolfinds.users enable row level security;
alter table thebudolfinds.sessions enable row level security;
alter table thebudolfinds.accounts enable row level security;
alter table thebudolfinds.verifications enable row level security;

create index sessions_user_id_idx on thebudolfinds.sessions (user_id);
create index accounts_user_id_idx on thebudolfinds.accounts (user_id);
create index verifications_identifier_idx on thebudolfinds.verifications (identifier);

-- Better Auth uses the server database role; browser roles cannot impersonate sessions.
revoke all on all tables in schema thebudolfinds from anon, authenticated;
grant usage on schema thebudolfinds to service_role;
grant all on all tables in schema thebudolfinds to service_role;
grant all on all sequences in schema thebudolfinds to service_role;
grant select on thebudolfinds.products, thebudolfinds.product_variants, thebudolfinds.merchant_listings, thebudolfinds.price_observations, thebudolfinds.score_snapshots to anon, authenticated;
