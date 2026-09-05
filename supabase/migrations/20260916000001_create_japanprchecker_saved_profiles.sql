-- Japan PR Checker saved planning data. The public schema is intentionally not used.
-- Store rule inputs and immutable snapshots; never identity-document numbers or exact home addresses.

create schema if not exists japanprchecker;

create extension if not exists pgcrypto with schema extensions;

set search_path = japanprchecker, extensions;

create table japanprchecker.pr_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  schema_version integer not null default 1 check (schema_version = 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table japanprchecker.pr_profile_snapshots (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references japanprchecker.pr_profiles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  schema_version integer not null default 1 check (schema_version = 1),
  as_of date not null,
  rule_version_ids text[] not null check (cardinality(rule_version_ids) > 0),
  source_ids text[] not null check (cardinality(source_ids) > 0),
  profile jsonb not null check (jsonb_typeof(profile) = 'object'),
  created_at timestamptz not null default now()
);

create table japanprchecker.pr_scenarios (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references japanprchecker.pr_profiles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Untitled scenario' check (char_length(name) between 1 and 120),
  target_date date not null,
  activity_category text not null check (activity_category in ('academic', 'technical', 'management')),
  overrides jsonb not null default '{}'::jsonb check (jsonb_typeof(overrides) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table japanprchecker.pr_assessment_runs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references japanprchecker.pr_profiles(id) on delete cascade,
  snapshot_id uuid not null references japanprchecker.pr_profile_snapshots(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rule_version_ids text[] not null check (cardinality(rule_version_ids) > 0),
  source_ids text[] not null check (cardinality(source_ids) > 0),
  result jsonb not null check (jsonb_typeof(result) = 'object'),
  created_at timestamptz not null default now()
);

create index pr_profile_snapshots_user_id_idx on japanprchecker.pr_profile_snapshots(user_id, created_at desc);
create index pr_profile_snapshots_profile_id_idx on japanprchecker.pr_profile_snapshots(profile_id);
create index pr_scenarios_user_id_idx on japanprchecker.pr_scenarios(user_id, updated_at desc);
create index pr_scenarios_profile_id_idx on japanprchecker.pr_scenarios(profile_id);
create index pr_assessment_runs_user_id_idx on japanprchecker.pr_assessment_runs(user_id, created_at desc);
create index pr_assessment_runs_profile_id_idx on japanprchecker.pr_assessment_runs(profile_id);
create index pr_assessment_runs_snapshot_id_idx on japanprchecker.pr_assessment_runs(snapshot_id);

alter table japanprchecker.pr_profiles enable row level security;
alter table japanprchecker.pr_profile_snapshots enable row level security;
alter table japanprchecker.pr_scenarios enable row level security;
alter table japanprchecker.pr_assessment_runs enable row level security;

create policy "profiles_select_own" on japanprchecker.pr_profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "profiles_insert_own" on japanprchecker.pr_profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "profiles_update_own" on japanprchecker.pr_profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "profiles_delete_own" on japanprchecker.pr_profiles for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "profile_snapshots_select_own" on japanprchecker.pr_profile_snapshots for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "profile_snapshots_insert_own" on japanprchecker.pr_profile_snapshots for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from japanprchecker.pr_profiles p
      where p.id = profile_id and p.user_id = (select auth.uid())
    )
  );

create policy "scenarios_select_own" on japanprchecker.pr_scenarios for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "scenarios_insert_own" on japanprchecker.pr_scenarios for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from japanprchecker.pr_profiles p
      where p.id = profile_id and p.user_id = (select auth.uid())
    )
  );
create policy "scenarios_update_own" on japanprchecker.pr_scenarios for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from japanprchecker.pr_profiles p
      where p.id = profile_id and p.user_id = (select auth.uid())
    )
  );
create policy "scenarios_delete_own" on japanprchecker.pr_scenarios for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "assessment_runs_select_own" on japanprchecker.pr_assessment_runs for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "assessment_runs_insert_own" on japanprchecker.pr_assessment_runs for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from japanprchecker.pr_profile_snapshots s
      where s.id = snapshot_id and s.profile_id = profile_id and s.user_id = (select auth.uid())
    )
  );

revoke all on schema japanprchecker from public;
grant usage on schema japanprchecker to anon, authenticated, service_role;

revoke all on all tables in schema japanprchecker from anon, authenticated;
grant select, insert, update, delete on japanprchecker.pr_profiles to authenticated;
grant select, insert on japanprchecker.pr_profile_snapshots to authenticated;
grant select, insert, update, delete on japanprchecker.pr_scenarios to authenticated;
grant select, insert on japanprchecker.pr_assessment_runs to authenticated;
grant all on all tables in schema japanprchecker to service_role;

alter default privileges in schema japanprchecker revoke execute on functions from public;
alter default privileges in schema japanprchecker revoke all on tables from public;
alter default privileges in schema japanprchecker revoke all on tables from anon, authenticated;
alter default privileges in schema japanprchecker grant all on tables to service_role;

-- Keep profile creation, its immutable input snapshot, and the recomputed result in one transaction.
-- SECURITY INVOKER leaves RLS as the authorization boundary for every table.
create or replace function japanprchecker.save_pr_profile_snapshot(
  p_schema_version integer,
  p_as_of date,
  p_rule_version_ids text[],
  p_source_ids text[],
  p_profile jsonb,
  p_assessment jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = japanprchecker, extensions
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_profile_id uuid;
  v_snapshot_id uuid;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if p_schema_version <> 1
    or cardinality(p_rule_version_ids) = 0
    or cardinality(p_source_ids) = 0
    or jsonb_typeof(p_profile) <> 'object'
    or jsonb_typeof(p_assessment) <> 'object' then
    raise exception 'invalid profile snapshot' using errcode = '22023';
  end if;

  insert into japanprchecker.pr_profiles (user_id, schema_version)
  values (v_user_id, p_schema_version)
  on conflict (user_id) do update set updated_at = now()
  returning id into v_profile_id;

  insert into japanprchecker.pr_profile_snapshots (profile_id, user_id, schema_version, as_of, rule_version_ids, source_ids, profile)
  values (v_profile_id, v_user_id, p_schema_version, p_as_of, p_rule_version_ids, p_source_ids, p_profile)
  returning id into v_snapshot_id;

  insert into japanprchecker.pr_assessment_runs (profile_id, snapshot_id, user_id, rule_version_ids, source_ids, result)
  values (v_profile_id, v_snapshot_id, v_user_id, p_rule_version_ids, p_source_ids, p_assessment);

  return v_profile_id;
end;
$$;

revoke all on function japanprchecker.save_pr_profile_snapshot(integer, date, text[], text[], jsonb, jsonb) from anon, authenticated;
grant execute on function japanprchecker.save_pr_profile_snapshot(integer, date, text[], text[], jsonb, jsonb) to authenticated;
