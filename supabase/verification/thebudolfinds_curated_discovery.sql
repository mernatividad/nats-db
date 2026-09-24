-- Curated product-discovery contract verification.
-- Run against the linked project with a role allowed to inspect metadata.

select
  to_regnamespace('thebudolfinds') is not null as schema_exists,
  to_regclass('thebudolfinds.products') is not null as products_exists,
  to_regclass('thebudolfinds.merchants') is not null as merchants_exists,
  to_regclass('thebudolfinds.merchant_listings') is not null as listings_exists,
  to_regclass('thebudolfinds.homepage_feed_items') is not null as homepage_feed_exists,
  to_regclass('thebudolfinds.affiliate_clicks') is not null as affiliate_clicks_exists,
  to_regclass('thebudolfinds.audit_logs') is not null as audit_logs_exists,
  to_regclass('thebudolfinds.users') is not null as better_auth_users_exists,
  to_regclass('thebudolfinds.import_runs') is not null as import_runs_exists,
  to_regclass('thebudolfinds.import_quarantine') is not null as import_quarantine_exists;

do $$
declare
  required_table text;
begin
  if to_regnamespace('thebudolfinds') is null then
    raise exception 'thebudolfinds schema is missing';
  end if;
  foreach required_table in array array[
    'products', 'merchants', 'merchant_listings', 'homepage_feed_items',
    'affiliate_clicks', 'audit_logs', 'users', 'import_runs', 'import_quarantine'
  ] loop
    if to_regclass('thebudolfinds.' || required_table) is null then
      raise exception 'thebudolfinds.% is missing', required_table;
    end if;
  end loop;
end
$$;

select
  table_name,
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_schema = 'thebudolfinds'
  and (
    (table_name = 'products' and column_name in ('image_url', 'image_alt'))
    or (table_name = 'homepage_feed_items' and column_name in ('product_id', 'collection', 'collection_title', 'editorial_blurb', 'badge', 'collection_order', 'sort_order', 'is_active', 'starts_at', 'ends_at', 'created_at', 'updated_at'))
    or (table_name = 'affiliate_clicks' and column_name = 'disclosure_shown')
    or (table_name = 'audit_logs' and column_name = 'actor_id')
    or (table_name = 'import_runs' and column_name in ('source_type', 'status', 'accepted_count', 'quarantined_count', 'errors'))
    or (table_name = 'import_quarantine' and column_name in ('import_run_id', 'record_index', 'payload', 'error_message'))
  )
order by table_name, ordinal_position;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'thebudolfinds' and table_name = 'products' and column_name = 'image_url'
  ) or not exists (
    select 1 from information_schema.columns
    where table_schema = 'thebudolfinds' and table_name = 'products' and column_name = 'image_alt'
  ) then
    raise exception 'product image columns are missing';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'thebudolfinds' and table_name = 'affiliate_clicks' and column_name = 'disclosure_shown' and is_nullable = 'NO'
  ) then
    raise exception 'affiliate_clicks.disclosure_shown is missing or nullable';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%starts_at%'
      and pg_get_constraintdef(oid) like '%ends_at%'
  ) then
    raise exception 'homepage feed window check is missing';
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and contype = 'u'
      and pg_get_constraintdef(oid) like '%collection%'
      and pg_get_constraintdef(oid) like '%product_id%'
  ) then
    raise exception 'homepage feed collection/product uniqueness is missing';
  end if;
end
$$;

select
  has_schema_privilege('anon', 'thebudolfinds', 'USAGE') as anon_schema_usage,
  has_schema_privilege('authenticated', 'thebudolfinds', 'USAGE') as authenticated_schema_usage,
  has_schema_privilege('service_role', 'thebudolfinds', 'USAGE') as service_schema_usage,
  has_table_privilege('anon', 'thebudolfinds.homepage_feed_items', 'SELECT') as anon_feed_select,
  has_table_privilege('authenticated', 'thebudolfinds.homepage_feed_items', 'SELECT') as authenticated_feed_select,
  has_table_privilege('anon', 'thebudolfinds.homepage_feed_items', 'INSERT') as anon_feed_insert,
  has_table_privilege('authenticated', 'thebudolfinds.homepage_feed_items', 'UPDATE') as authenticated_feed_update,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'SELECT') as service_feed_select,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'INSERT') as service_feed_insert,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'UPDATE') as service_feed_update,
  has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'DELETE') as service_feed_delete,
  has_table_privilege('service_role', 'thebudolfinds.affiliate_clicks', 'INSERT') as service_click_insert,
  has_table_privilege('service_role', 'thebudolfinds.import_runs', 'INSERT') as service_import_insert,
  has_table_privilege('anon', 'thebudolfinds.import_runs', 'SELECT') as anon_import_select,
  has_table_privilege('authenticated', 'thebudolfinds.import_quarantine', 'SELECT') as authenticated_quarantine_select;

do $$
begin
  if not has_schema_privilege('anon', 'thebudolfinds', 'USAGE')
     or not has_schema_privilege('authenticated', 'thebudolfinds', 'USAGE')
     or not has_schema_privilege('service_role', 'thebudolfinds', 'USAGE') then
    raise exception 'public catalog schema usage is missing';
  end if;
  if not has_table_privilege('anon', 'thebudolfinds.homepage_feed_items', 'SELECT')
     or not has_table_privilege('authenticated', 'thebudolfinds.homepage_feed_items', 'SELECT') then
    raise exception 'public homepage feed SELECT is missing';
  end if;
  if has_table_privilege('anon', 'thebudolfinds.homepage_feed_items', 'INSERT')
     or has_table_privilege('authenticated', 'thebudolfinds.homepage_feed_items', 'UPDATE') then
    raise exception 'public homepage feed mutation privilege is present';
  end if;
  if not has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'SELECT')
     or not has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'INSERT')
     or not has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'UPDATE')
     or not has_table_privilege('service_role', 'thebudolfinds.homepage_feed_items', 'DELETE') then
    raise exception 'service_role homepage feed CRUD is incomplete';
  end if;
  if has_table_privilege('anon', 'thebudolfinds.import_runs', 'SELECT')
     or has_table_privilege('authenticated', 'thebudolfinds.import_quarantine', 'SELECT') then
    raise exception 'import persistence is publicly readable';
  end if;
end
$$;

select
  c.conname,
  c.conrelid::regclass as table_name,
  c.confrelid::regclass as referenced_table,
  pg_get_constraintdef(c.oid) as definition
from pg_constraint c
where c.conrelid in (
  'thebudolfinds.audit_logs'::regclass,
  'thebudolfinds.import_quarantine'::regclass,
  'thebudolfinds.homepage_feed_items'::regclass
)
  and c.contype in ('f', 'u', 'c')
order by table_name, c.conname;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'thebudolfinds.audit_logs'::regclass
      and confrelid = 'thebudolfinds.users'::regclass
      and contype = 'f'
  ) then
    raise exception 'audit_logs.actor_id does not reference Better Auth users';
  end if;

  if not exists (
    select 1
    from pg_class
    where oid = 'thebudolfinds.homepage_feed_items'::regclass
      and relrowsecurity
  ) then
    raise exception 'homepage feed RLS is disabled';
  end if;

  if not exists (
    select 1 from pg_policy
    where polrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and polname = 'homepage feed is publicly readable'
  ) then
    raise exception 'active-only homepage feed policy is missing';
  end if;

  if not exists (
    select 1 from pg_class
    where oid = 'thebudolfinds.import_runs'::regclass and relrowsecurity
  ) or not exists (
    select 1 from pg_class
    where oid = 'thebudolfinds.import_quarantine'::regclass and relrowsecurity
  ) then
    raise exception 'import table RLS is disabled';
  end if;
end
$$;

select
  count(*) as active_feed_items,
  count(*) filter (where product_id is null) as orphaned_product_ids,
  count(*) filter (where collection is null or collection_title is null) as incomplete_collections,
  count(*) filter (where ends_at is not null and starts_at is not null and starts_at >= ends_at) as invalid_windows
from thebudolfinds.homepage_feed_items
where is_active;

select
  count(*) as seeded_listings,
  count(*) filter (where merchant_id is null) as listings_without_merchants,
  count(*) filter (where canonical_url is null or canonical_url = '') as listings_without_urls,
  count(*) filter (where merchants.domain not in ('shopee.ph', 'lazada.com.ph')) as listings_outside_supported_merchants
from thebudolfinds.merchant_listings listings
left join thebudolfinds.merchants merchants on merchants.id = listings.merchant_id;

select
  merchant.slug,
  merchant.domain,
  merchant.support_status,
  count(listing.id) as listing_count
from thebudolfinds.merchants merchant
left join thebudolfinds.merchant_listings listing on listing.merchant_id = merchant.id
where merchant.slug in ('shopee', 'lazada')
group by merchant.slug, merchant.domain, merchant.support_status
order by merchant.slug;

do $$
begin
  if exists (
    select 1 from thebudolfinds.homepage_feed_items
    where is_active and (product_id is null or collection is null or collection_title is null)
  ) then
    raise exception 'active homepage feed has incomplete rows';
  end if;
  if exists (
    select 1 from thebudolfinds.homepage_feed_items
    where is_active and starts_at is not null and ends_at is not null and starts_at >= ends_at
  ) then
    raise exception 'active homepage feed has invalid windows';
  end if;
  if exists (
    select 1 from thebudolfinds.merchant_listings listings
    left join thebudolfinds.merchants merchants on merchants.id = listings.merchant_id
    where merchants.id is null
  ) then
    raise exception 'merchant listing has no merchant';
  end if;
end
$$;
