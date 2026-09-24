set search_path = thebudolfinds, extensions, public;

alter table thebudolfinds.products
  add column if not exists image_url text,
  add column if not exists image_alt text;

create table if not exists thebudolfinds.homepage_feed_items (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references thebudolfinds.products(id) on delete cascade,
  collection text not null,
  collection_title text not null,
  editorial_blurb text,
  badge text,
  collection_order integer not null default 0,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (collection, product_id),
  constraint homepage_feed_items_window_check check (ends_at is null or starts_at is null or starts_at < ends_at)
);

create index if not exists homepage_feed_items_active_order_idx
  on thebudolfinds.homepage_feed_items (is_active, collection_order, sort_order);

alter table thebudolfinds.homepage_feed_items enable row level security;

drop policy if exists "homepage feed is publicly readable" on thebudolfinds.homepage_feed_items;
create policy "homepage feed is publicly readable"
  on thebudolfinds.homepage_feed_items
  for select to anon, authenticated
  using (is_active and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at > now()));

grant select on thebudolfinds.homepage_feed_items to anon, authenticated;

insert into thebudolfinds.merchants (name, slug, domain, support_status)
values
  ('Shopee', 'shopee', 'shopee.ph', 'supported'),
  ('Lazada', 'lazada', 'lazada.com.ph', 'supported')
on conflict (slug) do update set name = excluded.name, domain = excluded.domain, support_status = excluded.support_status, updated_at = now();

insert into thebudolfinds.products (name, slug, description, image_url, image_alt, source_type, freshness_at)
values
  ('Logitech Pebble M350 Wireless Mouse', 'logitech-pebble-m350-wireless-mouse', 'A quiet, low-profile mouse that makes a shared desk feel a little more considered.', '/images/logitech-pebble-m350.webp', 'White Logitech Pebble wireless mouse', 'curated', now()),
  ('Yale YDM7116A Digital Door Lock', 'yale-ydm7116a-digital-door-lock', 'A practical home upgrade for people who are tired of carrying keys everywhere.', '/images/yale-ydm7116a.webp', 'Yale digital door lock installed on a door', 'curated', now()),
  ('Microsoft Sculpt Ergonomic Mouse', 'microsoft-sculpt-ergonomic-mouse', 'The kind of desk upgrade you notice every workday.', '/images/microsoft-sculpt-ergonomic-mouse.webp', 'Microsoft Sculpt ergonomic mouse', 'curated', now()),
  ('Logitech MX Master 3', 'logitech-mx-master-3', 'A serious mouse for long work sessions, spreadsheet marathons, and shortcut devotees.', '/images/logitech-mx-master-3.webp', 'Logitech MX Master 3 wireless mouse', 'curated', now()),
  ('HP Z3700 Wireless Mouse', 'hp-z3700-wireless-mouse', 'Slim enough for a laptop bag and easy to justify as a small gift.', '/images/hp-z3700-wireless-mouse.webp', 'HP Z3700 slim wireless mouse', 'curated', now()),
  ('Xiaomi Wireless Mouse Lite', 'xiaomi-wireless-mouse-lite', 'A clean-looking budget pick when the old office mouse finally gives up.', '/images/xiaomi-wireless-mouse-lite.webp', 'Xiaomi Wireless Mouse Lite', 'curated', now()),
  ('Logitech M331 Silent Plus', 'logitech-m331-silent-plus', 'A quiet little upgrade for shared rooms, late-night work, and study corners.', '/images/logitech-m331-silent-plus.webp', 'Logitech M331 silent wireless mouse', 'curated', now()),
  ('Logitech G305 Lightspeed Wireless Gaming Mouse', 'logitech-g305-lightspeed-wireless-gaming-mouse', 'For the gamer who wants a useful gift rather than another novelty.', '/images/logitech-g305-lightspeed-wireless-gaming-mouse.webp', 'Logitech G305 wireless gaming mouse', 'curated', now()),
  ('Digital Door Lock Guide Pick', 'digital-door-lock-guide-pick', 'A practical housewarming idea that feels more thoughtful than another mug.', '/images/digital-door-locks.webp', 'Digital door lock on a home entrance', 'curated', now()),
  ('Father’s Day Tool Gift Pick', 'fathers-day-tool-gift-pick', 'A useful pick for the dad who is always fixing one more thing around the house.', '/images/tools-hardware-gifts-dad-philippines-1200x628.jpg', 'Tools and hardware arranged as a gift idea', 'curated', now()),
  ('Coffee Gift for Dad', 'coffee-gift-for-dad', 'A safe bet for the dad whose love language is offering everyone coffee.', '/images/coffee-gifts-for-dad-philippines-1200x628.jpg', 'Coffee gift ideas for Filipino dads', 'curated', now()),
  ('Something Handmade Gift Pick', 'something-handmade-gift-pick', 'A small handmade find carries more personality than a last-minute generic gift.', '/images/something-handmade-monito-monita-_kMJf4popK8.jpg', 'Handmade Monito Monita gift idea', 'curated', now())
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  image_url = excluded.image_url,
  image_alt = excluded.image_alt,
  freshness_at = excluded.freshness_at,
  updated_at = now();

insert into thebudolfinds.merchant_listings
  (product_id, merchant_id, external_id, canonical_url, title, currency, current_price, availability, source_updated_at)
select product.id, merchant.id, 'thebudolfinds-seed-' || product.slug, 'https://shopee.ph/search?keyword=' || replace(product.name, ' ', '%20'), product.name, 'PHP', seed.current_price, 'in_stock', now()
from (values
  ('logitech-pebble-m350-wireless-mouse', 899.00::numeric),
  ('yale-ydm7116a-digital-door-lock', 8499.00::numeric),
  ('microsoft-sculpt-ergonomic-mouse', 1699.00::numeric),
  ('logitech-mx-master-3', 3999.00::numeric),
  ('hp-z3700-wireless-mouse', 799.00::numeric),
  ('xiaomi-wireless-mouse-lite', 499.00::numeric),
  ('logitech-m331-silent-plus', 1099.00::numeric),
  ('logitech-g305-lightspeed-wireless-gaming-mouse', 1999.00::numeric),
  ('digital-door-lock-guide-pick', 4999.00::numeric),
  ('fathers-day-tool-gift-pick', 1299.00::numeric),
  ('coffee-gift-for-dad', 650.00::numeric),
  ('something-handmade-gift-pick', 350.00::numeric)
) as seed(slug, current_price)
join thebudolfinds.products product on product.slug = seed.slug
join thebudolfinds.merchants merchant on merchant.slug = 'shopee'
on conflict (merchant_id, external_id) do update set
  current_price = excluded.current_price,
  availability = excluded.availability,
  source_updated_at = excluded.source_updated_at,
  updated_at = now();

insert into thebudolfinds.homepage_feed_items
  (product_id, collection, collection_title, editorial_blurb, badge, collection_order, sort_order)
select product.id, feed.collection, feed.collection_title, feed.editorial_blurb, feed.badge, feed.collection_order, feed.sort_order
from (values
  ('latest-finds', 'Latest finds', 'The small upgrades currently earning a spot in our carts.', 'Editor pick', 1, 1, 'logitech-pebble-m350-wireless-mouse'),
  ('latest-finds', 'Latest finds', 'A little more convenience at the front door.', 'Home upgrade', 1, 2, 'yale-ydm7116a-digital-door-lock'),
  ('latest-finds', 'Latest finds', 'A better desk day starts with the things your hands use most.', 'Desk upgrade', 1, 3, 'microsoft-sculpt-ergonomic-mouse'),
  ('latest-finds', 'Latest finds', 'For the person who has a shortcut for everything.', 'Worth the splurge', 1, 4, 'logitech-mx-master-3'),
  ('under-500', 'Under ₱500', 'Useful little wins that stay kind to the budget.', 'Budget win', 2, 1, 'xiaomi-wireless-mouse-lite'),
  ('under-500', 'Under ₱500', 'A tiny gift that feels more useful than random.', '₱500 and below', 2, 2, 'something-handmade-gift-pick'),
  ('under-500', 'Under ₱500', 'A simple desk refresh without the guilt spiral.', '₱500 and below', 2, 3, 'hp-z3700-wireless-mouse'),
  ('under-500', 'Under ₱500', 'For the gamer on a practical gift budget.', '₱500 and below', 2, 4, 'logitech-m331-silent-plus'),
  ('for-your-desk', 'For your desk', 'Quiet, useful, and easy to live with every day.', 'Workday pick', 3, 1, 'logitech-pebble-m350-wireless-mouse'),
  ('for-your-desk', 'For your desk', 'The serious upgrade for serious screen time.', 'Workday pick', 3, 2, 'logitech-mx-master-3'),
  ('for-your-desk', 'For your desk', 'A comfortable shape for long afternoons.', 'Comfort pick', 3, 3, 'microsoft-sculpt-ergonomic-mouse'),
  ('for-your-desk', 'For your desk', 'The laptop-bag-friendly option.', 'Small footprint', 3, 4, 'hp-z3700-wireless-mouse'),
  ('gifts-that-dont-feel-generic', 'Gifts that don’t feel generic', 'A practical surprise for the person who is always fixing something.', 'For dads', 4, 1, 'fathers-day-tool-gift-pick'),
  ('gifts-that-dont-feel-generic', 'Gifts that don’t feel generic', 'A gift for someone whose day starts with coffee.', 'For dads', 4, 2, 'coffee-gift-for-dad'),
  ('gifts-that-dont-feel-generic', 'Gifts that don’t feel generic', 'A housewarming idea with actual daily payoff.', 'Housewarming', 4, 3, 'digital-door-lock-guide-pick'),
  ('gifts-that-dont-feel-generic', 'Gifts that don’t feel generic', 'A handmade touch for the Monito Monita exchange.', 'Made with feeling', 4, 4, 'something-handmade-gift-pick')
) as feed(collection, collection_title, editorial_blurb, badge, collection_order, sort_order, slug)
join thebudolfinds.products product on product.slug = feed.slug
on conflict (collection, product_id) do update set
  collection_title = excluded.collection_title,
  editorial_blurb = excluded.editorial_blurb,
  badge = excluded.badge,
  collection_order = excluded.collection_order,
  sort_order = excluded.sort_order,
  is_active = true,
  updated_at = now();
