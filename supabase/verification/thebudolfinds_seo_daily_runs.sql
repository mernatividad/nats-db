select
  has_table_privilege('service_role', 'thebudolfinds.seo_daily_runs', 'SELECT') as service_can_read,
  has_table_privilege('service_role', 'thebudolfinds.seo_daily_runs', 'INSERT') as service_can_insert,
  has_table_privilege('service_role', 'thebudolfinds.seo_daily_runs', 'UPDATE') as service_can_update,
  has_table_privilege('service_role', 'thebudolfinds.seo_daily_runs', 'DELETE') as service_can_delete,
  not has_table_privilege('anon', 'thebudolfinds.seo_daily_runs', 'SELECT') as anon_cannot_read,
  not has_table_privilege('authenticated', 'thebudolfinds.seo_daily_runs', 'SELECT') as authenticated_cannot_read,
  exists (
    select 1 from pg_class
    where oid = 'thebudolfinds.seo_daily_runs'::regclass and relrowsecurity
  ) as row_level_security_enabled;

select run_date, site_url, evidence, decisions, actions, validation, next_action, created_at
from thebudolfinds.seo_daily_runs
order by run_date desc
limit 10;
