-- Homepage feed population verification.
do $$
declare
  active_count integer;
  unique_count integer;
  missing_links integer;
begin
  select count(*), count(distinct product_id)
    into active_count, unique_count
  from thebudolfinds.homepage_feed_items
  where is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now());

  if active_count <> 100 or unique_count <> 100 then
    raise exception 'homepage feed expected 100 active unique products, found % rows and % products', active_count, unique_count;
  end if;

  select count(*) into missing_links
  from thebudolfinds.homepage_feed_items feed
  left join thebudolfinds.merchant_listings listing on listing.product_id = feed.product_id
  where feed.is_active
    and (listing.canonical_url is null or listing.canonical_url = '');

  if missing_links <> 0 then
    raise exception 'homepage feed has % active products without a merchant link', missing_links;
  end if;
end
$$;

select
  count(*) filter (where feed.is_active) as active_feed_items,
  count(distinct feed.product_id) filter (where feed.is_active) as unique_active_products,
  count(*) filter (where feed.is_active and listing.canonical_url like 'https://%') as active_products_with_https_links,
  count(*) filter (where feed.is_active and listing.canonical_url like '%/catalog/?q=%') as active_catalog_search_links
from thebudolfinds.homepage_feed_items feed
left join lateral (
  select canonical_url
  from thebudolfinds.merchant_listings
  where product_id = feed.product_id
  order by updated_at desc
  limit 1
) listing on true;
