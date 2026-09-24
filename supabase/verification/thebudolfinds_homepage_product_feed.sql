select
  to_regclass('thebudolfinds.homepage_feed_items') is not null as homepage_feed_table_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'thebudolfinds' and table_name = 'products' and column_name = 'image_url'
  ) as product_image_column_exists,
  has_table_privilege('anon', 'thebudolfinds.homepage_feed_items', 'SELECT') as anon_can_read_homepage_feed,
  (select count(*) from thebudolfinds.homepage_feed_items where is_active) >= 12 as seeded_feed_items_present;
