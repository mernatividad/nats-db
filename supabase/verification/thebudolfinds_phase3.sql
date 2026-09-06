select schemaname as table_schema, tablename as table_name, rowsecurity
from pg_catalog.pg_tables
where schemaname = 'thebudolfinds'
  and tablename in ('import_runs', 'import_quarantine', 'affiliate_clicks')
order by tablename;

select has_table_privilege('anon', 'thebudolfinds.import_runs', 'SELECT') as anon_can_read_imports,
       has_table_privilege('authenticated', 'thebudolfinds.import_quarantine', 'SELECT') as authenticated_can_read_quarantine,
       has_table_privilege('service_role', 'thebudolfinds.import_runs', 'INSERT') as service_can_write_imports;
