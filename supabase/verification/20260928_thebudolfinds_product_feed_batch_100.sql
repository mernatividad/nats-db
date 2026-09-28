-- Verify all 100 newly added feed items have a local image and tracked affiliate URL.
select count(*) as feed_items, count(distinct product.id) as distinct_products, count(*) filter (where product.image_url is not null and product.image_source_url is not null) as imaged_products, count(*) filter (where listing.affiliate_url like 'https://invl.me/%' and listing.affiliate_network='involve-asia') as affiliate_linked_products
from "thebudolfinds".homepage_feed_items feed
join "thebudolfinds".products product on product.id=feed.product_id
join "thebudolfinds".merchant_listings listing on listing.product_id=product.id
where listing.external_id='editorial-batch-20260928-' || product.slug;

select product.name, product.image_url, listing.canonical_url, listing.affiliate_url
from "thebudolfinds".homepage_feed_items feed
join "thebudolfinds".products product on product.id=feed.product_id
join "thebudolfinds".merchant_listings listing on listing.product_id=product.id
where listing.external_id='editorial-batch-20260928-' || product.slug
order by feed.collection, feed.sort_order;
