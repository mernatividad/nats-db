-- JapanPRChecker uses Better Auth for identity/session management.
-- Supabase hosts PostgreSQL only; Supabase Auth is intentionally not used.
create schema if not exists japanprchecker;

set search_path = japanprchecker, extensions;

create table if not exists japanprchecker."user" (
  "id" text primary key,
  "name" text not null,
  "email" text not null unique,
  "emailVerified" boolean not null default false,
  "image" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists japanprchecker."session" (
  "id" text primary key,
  "expiresAt" timestamptz not null,
  "token" text not null unique,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  "ipAddress" text,
  "userAgent" text,
  "userId" text not null references japanprchecker."user" ("id") on delete cascade
);

create index if not exists better_auth_session_user_id_idx
  on japanprchecker."session" ("userId");

create table if not exists japanprchecker."account" (
  "id" text primary key,
  "accountId" text not null,
  "providerId" text not null,
  "userId" text not null references japanprchecker."user" ("id") on delete cascade,
  "accessToken" text,
  "refreshToken" text,
  "idToken" text,
  "accessTokenExpiresAt" timestamptz,
  "refreshTokenExpiresAt" timestamptz,
  "scope" text,
  "password" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint better_auth_account_provider_account_unique unique ("providerId", "accountId")
);

create index if not exists better_auth_account_user_id_idx
  on japanprchecker."account" ("userId");

create table if not exists japanprchecker."verification" (
  "id" text primary key,
  "identifier" text not null,
  "value" text not null,
  "expiresAt" timestamptz not null,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists better_auth_verification_identifier_idx
  on japanprchecker."verification" ("identifier");

-- Better Auth IDs are text, unlike Supabase Auth UUIDs. Existing PR data is
-- retained, but ownership is now keyed to the Better Auth user ID.
drop function if exists japanprchecker.save_pr_profile_snapshot(integer, date, text[], text[], jsonb, jsonb);

drop policy if exists profiles_select_own on japanprchecker.pr_profiles;
drop policy if exists profiles_insert_own on japanprchecker.pr_profiles;
drop policy if exists profiles_update_own on japanprchecker.pr_profiles;
drop policy if exists profiles_delete_own on japanprchecker.pr_profiles;
drop policy if exists profile_snapshots_select_own on japanprchecker.pr_profile_snapshots;
drop policy if exists profile_snapshots_insert_own on japanprchecker.pr_profile_snapshots;
drop policy if exists scenarios_select_own on japanprchecker.pr_scenarios;
drop policy if exists scenarios_insert_own on japanprchecker.pr_scenarios;
drop policy if exists scenarios_update_own on japanprchecker.pr_scenarios;
drop policy if exists scenarios_delete_own on japanprchecker.pr_scenarios;
drop policy if exists assessment_runs_select_own on japanprchecker.pr_assessment_runs;
drop policy if exists assessment_runs_insert_own on japanprchecker.pr_assessment_runs;

alter table japanprchecker.pr_profiles
  drop constraint if exists pr_profiles_user_id_fkey;
alter table japanprchecker.pr_profile_snapshots
  drop constraint if exists pr_profile_snapshots_user_id_fkey;
alter table japanprchecker.pr_scenarios
  drop constraint if exists pr_scenarios_user_id_fkey;
alter table japanprchecker.pr_assessment_runs
  drop constraint if exists pr_assessment_runs_user_id_fkey;

alter table japanprchecker.pr_profiles
  alter column user_id type text using user_id::text;
alter table japanprchecker.pr_profile_snapshots
  alter column user_id type text using user_id::text;
alter table japanprchecker.pr_scenarios
  alter column user_id type text using user_id::text;
alter table japanprchecker.pr_assessment_runs
  alter column user_id type text using user_id::text;

-- These tables are accessed only by the server-side pg pool. No Better Auth
-- session is forwarded as a Supabase JWT, so PostgREST roles must not have
-- access to private profile or authentication data.
alter table japanprchecker.pr_profiles enable row level security;
alter table japanprchecker.pr_profile_snapshots enable row level security;
alter table japanprchecker.pr_scenarios enable row level security;
alter table japanprchecker.pr_assessment_runs enable row level security;
alter table japanprchecker."user" enable row level security;
alter table japanprchecker."session" enable row level security;
alter table japanprchecker."account" enable row level security;
alter table japanprchecker."verification" enable row level security;

revoke all on all tables in schema japanprchecker from anon, authenticated;
revoke all on all functions in schema japanprchecker from anon, authenticated;
