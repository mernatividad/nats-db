-- Run after the foundation migration with a role that can inspect catalog metadata.
select schema_name
from information_schema.schemata
where schema_name = 'thebudolfinds';

select table_name
from information_schema.tables
where table_schema = 'thebudolfinds'
order by table_name;

select schemaname, tablename, rowsecurity
from pg_catalog.pg_tables
where schemaname = 'thebudolfinds'
order by tablename;

select n.nspname as schema_name, c.relname as table_name, p.polname as policy_name
from pg_catalog.pg_policy p
join pg_catalog.pg_class c on c.oid = p.polrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'thebudolfinds'
order by c.relname, p.polname;

select has_schema_privilege('anon', 'thebudolfinds', 'USAGE') as anon_schema_usage,
       has_schema_privilege('authenticated', 'thebudolfinds', 'USAGE') as authenticated_schema_usage;
