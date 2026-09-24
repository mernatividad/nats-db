select
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'SELECT') as service_can_read,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'INSERT') as service_can_insert,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'UPDATE') as service_can_update,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'DELETE') as service_can_delete,
  not has_table_privilege('anon', 'thebudolfinds.homepage_feed_items', 'INSERT') as anon_cannot_insert,
  not has_table_privilege('authenticated', 'thebudolfinds.homepage_feed_items', 'UPDATE') as authenticated_cannot_update,
  exists (
    select 1 from pg_class
    where oid = 'thebudolfinds.homepage_feed_items'::regclass and relrowsecurity
  ) as homepage_feed_rls_enabled;
