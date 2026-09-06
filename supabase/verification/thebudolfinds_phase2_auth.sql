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
