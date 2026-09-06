-- Run after the TheBudolFinds Better Auth migrations with a role that can inspect
-- catalog metadata. This verifies the server-owned identity boundary and exposed
-- browser permissions without printing credentials or user data.

select table_name
from information_schema.tables
where table_schema = 'thebudolfinds'
  and table_name in ('users', 'sessions', 'accounts', 'verifications')
order by table_name;

select schemaname as table_schema, tablename as table_name, rowsecurity
from pg_catalog.pg_tables
where schemaname = 'thebudolfinds'
  and tablename in ('users', 'sessions', 'accounts', 'verifications', 'profiles', 'reports', 'audit_logs')
order by tablename;

select has_table_privilege('anon', 'thebudolfinds.users', 'SELECT') as anon_can_read_users,
       has_table_privilege('authenticated', 'thebudolfinds.users', 'SELECT') as authenticated_can_read_users,
       has_table_privilege('service_role', 'thebudolfinds.users', 'SELECT') as service_can_read_users,
       has_table_privilege('authenticated', 'thebudolfinds.products', 'SELECT') as authenticated_can_read_catalog;

select n.nspname as schema_name,
       c.relname as table_name,
       p.polname as policy_name
from pg_catalog.pg_policy p
join pg_catalog.pg_class c on c.oid = p.polrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'thebudolfinds'
  and c.relname in ('users', 'sessions', 'accounts', 'verifications', 'profiles', 'reports', 'audit_logs')
order by c.relname, p.polname;

select column_name, data_type
from information_schema.columns
where table_schema = 'thebudolfinds'
  and table_name in ('users', 'profiles', 'reports', 'audit_logs')
  and column_name in ('id', 'role', 'reporter_id', 'actor_id')
order by table_name, column_name;

-- Assertion-style live authorization checks. Any violation aborts the query.
do $$
declare
  public_table text;
begin
  foreach public_table in array array['products', 'product_variants', 'merchant_listings', 'price_observations', 'score_snapshots'] loop
    if not has_table_privilege('anon', format('thebudolfinds.%I', public_table), 'SELECT') then
      raise exception 'anon cannot read intended public catalog table %', public_table;
    end if;
    if not has_table_privilege('authenticated', format('thebudolfinds.%I', public_table), 'SELECT') then
      raise exception 'authenticated cannot read intended public catalog table %', public_table;
    end if;
  end loop;

  foreach public_table in array array['users', 'sessions', 'accounts', 'verifications', 'profiles', 'reports', 'audit_logs', 'import_runs', 'import_quarantine'] loop
    if has_table_privilege('anon', format('thebudolfinds.%I', public_table), 'SELECT') then
      raise exception 'anon can read private table %', public_table;
    end if;
    if has_table_privilege('authenticated', format('thebudolfinds.%I', public_table), 'SELECT') then
      raise exception 'authenticated can read private table %', public_table;
    end if;
  end loop;
end $$;
