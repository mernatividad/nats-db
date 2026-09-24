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
grant select, insert, update, delete on thebudolfinds.homepage_feed_items to service_role;

insert into thebudolfinds.merchants (name, slug, domain, support_status)
values
  ('Shopee', 'shopee', 'shopee.ph', 'supported'),
  ('Lazada', 'lazada', 'lazada.com.ph', 'supported')
on conflict (slug) do update set
  name = excluded.name,
  domain = excluded.domain,
  support_status = excluded.support_status,
  updated_at = now();

insert into thebudolfinds.products (name, slug, description, source_type, freshness_at)
values
  ('TP-Link Tapo P105 Mini Smart Wi-Fi Plug', 'tp-link-tapo-p105-mini-smart-wifi-plug', 'A compact smart-home starter that adds remote control and voice commands to an everyday outlet.', 'curated', now()),
  ('TP-Link Tapo T315 Smart Temperature and Humidity Monitor', 'tp-link-tapo-t315-temperature-humidity-monitor', 'An e-ink room monitor for keeping an eye on the heat and humidity at home.', 'curated', now()),
  ('AUKEY PA-F1S Swift 20W USB-C Fast Charger', 'aukey-pa-f1s-swift-20w-usb-c-fast-charger', 'A small foldable charger that is easy to keep in a daily-carry pouch or work bag.', 'curated', now()),
  ('AUKEY PA-B70 140W GaN Wall Charger', 'aukey-pa-b70-140w-gan-wall-charger', 'A high-output charger for people who want one power brick for phones, tablets, and laptops.', 'curated', now()),
  ('Logitech Pebble 2 M350S Wireless Mouse', 'logitech-pebble-2-m350s-wireless-mouse', 'A quiet, slim desk upgrade that travels well with a laptop.', 'curated', now()),
  ('Logitech M330 Silent Plus Wireless Mouse', 'logitech-m330-silent-plus-wireless-mouse', 'A practical quiet-click mouse for shared rooms, study corners, and home offices.', 'curated', now()),
  ('OOKAS Rechargeable 3-Color Dimmable Desk Lamp', 'ookas-rechargeable-3-color-desk-lamp', 'A foldable touch lamp for reading, bedside use, or a softer work-from-home setup.', 'curated', now()),
  ('OPPLE Eye Protection Rechargeable Desk Lamp', 'opple-eye-protection-rechargeable-desk-lamp', 'A rechargeable lamp with adjustable brightness for desks that do double duty.', 'curated', now()),
  ('LASCO Wi-Fi Dual PH Smart Socket', 'lasco-wifi-dual-ph-smart-socket', 'A useful smart-home switch with remote control and Alexa or Google Home support.', 'curated', now()),
  ('Orocan Splendido Dish Cabinet Organizer', 'orocan-splendido-dish-cabinet-organizer', 'A space-saving kitchen organizer with two layers, a clear door, and a pull-out water catch.', 'curated', now())
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  freshness_at = excluded.freshness_at,
  updated_at = now();

insert into thebudolfinds.merchant_listings
  (product_id, merchant_id, external_id, canonical_url, title, currency, current_price, availability, source_updated_at)
select product.id, merchant.id, listing.external_id, listing.canonical_url, listing.title, 'PHP', listing.current_price, 'unknown', now()
from (values
  ('tp-link-tapo-p105-mini-smart-wifi-plug', '1192536292', 'https://www.lazada.com.ph/products/tp-link-official-store-tapo-p105-mini-smart-home-remote-and-voice-control-easy-setup-alexa-voice-command-system-set-wi-fi-switch-switchbot-socket-outlet-plug-i1192536292.html', 'TP-Link Official Store Tapo P105 Mini Smart Wi-Fi Plug', 479.00::numeric, 'lazada'),
  ('tp-link-tapo-t315-temperature-humidity-monitor', '3890290006', 'https://www.lazada.com.ph/products/tp-link-official-store-tapo-t315-27-e-ink-display-real-time-accurate-monitoring-smart-humidity-temperature-monitor-tapo-hub-required-i3890290006.html', 'TP-Link Official Store Tapo T315 Smart Temperature and Humidity Monitor', 1290.00::numeric, 'lazada'),
  ('aukey-pa-f1s-swift-20w-usb-c-fast-charger', '2403451068', 'https://www.lazada.com.ph/products/aukey-pa-f1s-swift-20w-upgraded-fast-charger-usb-c-pd-30-foldable-plug-for-apple-series-samsung-and-android-all-gadgets-multi-device-charging-adapter-local-manufacturer-warranty-i2403451068.html', 'AUKEY PA-F1S Swift 20W USB-C Fast Charger', null::numeric, 'lazada'),
  ('aukey-pa-b70-140w-gan-wall-charger', '3753489033', 'https://www.lazada.com.ph/products/aukey-pa-b70-140w-wall-charger-pd-31-gan-for-iphones-ipads-android-macbook-and-pro-type-c-laptops-i3753489033.html', 'AUKEY PA-B70 140W GaN Wall Charger', null::numeric, 'lazada'),
  ('logitech-pebble-2-m350s-wireless-mouse', '4099822952', 'https://www.lazada.com.ph/products/logitech-pebble-2-m350s-wireless-mouse-graphite-i4099822952.html', 'Logitech Pebble 2 M350S Wireless Mouse Graphite', null::numeric, 'lazada'),
  ('logitech-m330-silent-plus-wireless-mouse', '261491677', 'https://www.lazada.com.ph/products/logitech-m330-silent-plus-wireless-mouse-24-ghz-usb-nano-receiver-usb-1000-dpi-3-buttons-pcmaclaptopchromebook-black-i261491677.html', 'Logitech M330 Silent Plus Wireless Mouse', 955.00::numeric, 'lazada'),
  ('ookas-rechargeable-3-color-desk-lamp', '5240216648', 'https://www.lazada.com.ph/products/ookas-desk-lamp-chargeable-lamp-3-color-stepless-dimmable-table-desk-touch-foldable-table-lamp-bedside-reading-eye-protection-night-light-usb-chargeable-desk-lamp-table-lamp-study-lamp-desk-lamp-i5240216648.html', 'OOKAS Rechargeable 3-Color Dimmable Desk Lamp', null::numeric, 'lazada'),
  ('opple-eye-protection-rechargeable-desk-lamp', '5397660071', 'https://www.lazada.com.ph/products/opple-eye-protection-desk-lamp-i5397660071.html', 'OPPLE Eye Protection Rechargeable Desk Lamp', null::numeric, 'lazada'),
  ('lasco-wifi-dual-ph-smart-socket', '296882848', 'https://www.lazada.com.ph/products/lasco-wifi-dual-ph-plug-plus-smart-socket-wireless-plug-socket-powerful-15a-3300-watts-outlet-remote-control-power-socket-smart-timer-plug-for-smart-home-works-with-amazon-echo-alexa-and-google-home-i296882848.html', 'LASCO Wi-Fi Dual PH Smart Socket', null::numeric, 'lazada'),
  ('orocan-splendido-dish-cabinet-organizer', '4948208802', 'https://shopee.ph/Orocan-Splendido-Dish-Cabinet-Dish-Organizer-Dish-rack-(Metro-Manila-only-SF-C-O-Buyer)-i.293250348.4948208802', 'Orocan Splendido Dish Cabinet Dish Organizer', null::numeric, 'shopee')
) as listing(slug, external_id, canonical_url, title, current_price, merchant_slug)
join thebudolfinds.products product on product.slug = listing.slug
join thebudolfinds.merchants merchant on merchant.slug = listing.merchant_slug
on conflict (merchant_id, external_id) do update set
  canonical_url = excluded.canonical_url,
  title = excluded.title,
  current_price = excluded.current_price,
  availability = excluded.availability,
  source_updated_at = excluded.source_updated_at,
  updated_at = now();

insert into thebudolfinds.homepage_feed_items
  (product_id, collection, collection_title, editorial_blurb, badge, collection_order, sort_order)
select product.id, feed.collection, feed.collection_title, feed.editorial_blurb, feed.badge, feed.collection_order, feed.sort_order
from (values
  ('latest-finds', 'Latest finds', 'A tiny smart-home upgrade with a very reasonable price tag.', 'Under ₱500', 1, 1, 'tp-link-tapo-p105-mini-smart-wifi-plug'),
  ('latest-finds', 'Latest finds', 'A calmer way to keep tabs on the room you are actually living in.', 'Home upgrade', 1, 2, 'tp-link-tapo-t315-temperature-humidity-monitor'),
  ('latest-finds', 'Latest finds', 'A quiet desk essential that disappears into the workday.', 'Desk upgrade', 1, 3, 'logitech-pebble-2-m350s-wireless-mouse'),
  ('latest-finds', 'Latest finds', 'A practical kitchen organizer for small-space living.', 'Kitchen win', 1, 4, 'orocan-splendido-dish-cabinet-organizer'),
  ('under-500', 'Under ₱500', 'The easiest useful gift in this batch.', '₱500 and below', 2, 1, 'tp-link-tapo-p105-mini-smart-wifi-plug'),
  ('under-500', 'Under ₱500', 'A small desk upgrade that earns its keep.', 'Budget win', 2, 2, 'logitech-m330-silent-plus-wireless-mouse'),
  ('for-your-desk', 'For your desk', 'One charger for the phone, tablet, and laptop crowd.', 'Workday pick', 3, 1, 'aukey-pa-b70-140w-gan-wall-charger'),
  ('for-your-desk', 'For your desk', 'Softer light for late-night work and reading.', 'Desk upgrade', 3, 2, 'ookas-rechargeable-3-color-desk-lamp'),
  ('gifts-that-dont-feel-generic', 'Gifts that don’t feel generic', 'A helpful little gadget for someone building a smarter home.', 'Useful gift', 4, 1, 'lasco-wifi-dual-ph-smart-socket'),
  ('gifts-that-dont-feel-generic', 'Gifts that don’t feel generic', 'The kind of kitchen gift that gets used every day.', 'Housewarming', 4, 2, 'orocan-splendido-dish-cabinet-organizer')
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
