-- Replace editorial guide placeholders with a 100-product retail discovery feed.
-- This migration is intentionally schema-qualified because ../nats-db is shared.
set search_path = thebudolfinds, extensions, public;

-- Guide/article cards are not products and should not remain active in the homepage feed.
update thebudolfinds.homepage_feed_items feed
set is_active = false, updated_at = now()
from thebudolfinds.products product
where product.id = feed.product_id
  and product.slug in ('fathers-day-tool-gift-pick', 'coffee-gift-for-dad', 'something-handmade-gift-pick', 'digital-door-lock-guide-pick');

insert into thebudolfinds.products (name, slug, description, source_type, freshness_at)
values
  ('Anker 323 Charger 33W', 'anker-323-charger-33w', 'Compact USB-C wall charger for phones, tablets, and everyday carry.', 'curated', now()),
  ('Anker Nano Power Bank 30W', 'anker-nano-power-bank-30w', 'Pocket power bank with USB-C charging for commutes and travel.', 'curated', now()),
  ('UGREEN Nexode 65W GaN Charger', 'ugreen-nexode-65w-gan-charger', 'Multi-port GaN charger for laptops, tablets, and phones.', 'curated', now()),
  ('Baseus 65W GaN5 Fast Charger', 'baseus-65w-gan5-fast-charger', 'Small high-output charger for a compact work bag.', 'curated', now()),
  ('Anker PowerLine III USB-C Cable', 'anker-powerline-iii-usb-c-cable', 'Durable USB-C cable for daily charging and data transfer.', 'curated', now()),
  ('UGREEN USB-C Hub 6-in-1', 'ugreen-usb-c-hub-6-in-1', 'Desktop hub with ports for displays, storage, and accessories.', 'curated', now()),
  ('TP-Link Archer AX23 Wi-Fi 6 Router', 'tp-link-archer-ax23-wifi-6-router', 'Wi-Fi 6 router for apartments, homes, and work-from-home setups.', 'curated', now()),
  ('TP-Link RE305 Wi-Fi Range Extender', 'tp-link-re305-wifi-range-extender', 'Simple range extension for rooms with weak Wi-Fi.', 'curated', now()),
  ('Xiaomi Mi WiFi Range Extender AC1200', 'xiaomi-mi-wifi-range-extender-ac1200', 'Dual-band Wi-Fi extender for home coverage gaps.', 'curated', now()),
  ('Amazon Kindle Paperwhite 16GB', 'amazon-kindle-paperwhite-16gb', 'Water-resistant e-reader with a warm-light display.', 'curated', now()),
  ('Logitech K380 Bluetooth Keyboard', 'logitech-k380-bluetooth-keyboard', 'Compact multi-device keyboard for desks and tablets.', 'curated', now()),
  ('Logitech K480 Bluetooth Keyboard', 'logitech-k480-bluetooth-keyboard', 'Multi-device keyboard with an integrated device stand.', 'curated', now()),
  ('Logitech M720 Triathlon Mouse', 'logitech-m720-triathlon-mouse', 'Multi-device mouse for switching between work computers.', 'curated', now()),
  ('Logitech G304 Lightspeed Gaming Mouse', 'logitech-g304-lightspeed-gaming-mouse', 'Wireless gaming mouse with a lightweight practical design.', 'curated', now()),
  ('Razer DeathAdder Essential Mouse', 'razer-deathadder-essential-mouse', 'Ergonomic wired gaming mouse for longer sessions.', 'curated', now()),
  ('Redragon K552 Kumara Mechanical Keyboard', 'redragon-k552-kumara-mechanical-keyboard', 'Entry-level mechanical keyboard for gaming and typing.', 'curated', now()),
  ('AOC 24B2XH 24-inch Monitor', 'aoc-24b2xh-24-inch-monitor', 'Slim full-HD monitor for home offices and study desks.', 'curated', now()),
  ('Xiaomi Mi Computer Monitor Light Bar', 'xiaomi-mi-computer-monitor-light-bar', 'Monitor-mounted task light that frees up desk space.', 'curated', now()),
  ('JBL Go 3 Portable Bluetooth Speaker', 'jbl-go-3-portable-bluetooth-speaker', 'Small waterproof speaker for rooms, picnics, and travel.', 'curated', now()),
  ('Anker Soundcore 2 Bluetooth Speaker', 'anker-soundcore-2-bluetooth-speaker', 'Portable speaker with long battery life for everyday listening.', 'curated', now()),
  ('JBL Tune 520BT Wireless Headphones', 'jbl-tune-520bt-wireless-headphones', 'Foldable wireless headphones for commutes and calls.', 'curated', now()),
  ('Anker Soundcore Q20i Headphones', 'anker-soundcore-q20i-headphones', 'Over-ear wireless headphones with active noise cancellation.', 'curated', now()),
  ('Baseus Bowie MA10 Earbuds', 'baseus-bowie-ma10-earbuds', 'Noise-cancelling true wireless earbuds for daily use.', 'curated', now()),
  ('QCY T13 ANC Earbuds', 'qcy-t13-anc-earbuds', 'Affordable wireless earbuds with noise cancellation.', 'curated', now()),
  ('TP-Link Tapo C200 Security Camera', 'tp-link-tapo-c200-security-camera', 'Pan-and-tilt indoor camera for basic home monitoring.', 'curated', now()),
  ('TP-Link Tapo C210 Security Camera', 'tp-link-tapo-c210-security-camera', 'Indoor camera with higher-resolution monitoring.', 'curated', now()),
  ('TP-Link Tapo L530 Smart Bulb', 'tp-link-tapo-l530-smart-bulb', 'Color-changing smart bulb with app and voice control.', 'curated', now()),
  ('Philips Hue White Smart Bulb', 'philips-hue-white-smart-bulb', 'Connected white-light bulb for routines and rooms.', 'curated', now()),
  ('Xiaomi Mi Smart LED Bulb Essential', 'xiaomi-mi-smart-led-bulb-essential', 'Color and temperature adjustable smart bulb.', 'curated', now()),
  ('Aqara Door and Window Sensor', 'aqara-door-window-sensor', 'Compact contact sensor for simple home automation.', 'curated', now()),
  ('Xiaomi Mi Smart Air Fryer 3.5L', 'xiaomi-mi-smart-air-fryer-35l', 'Compact air fryer for quick everyday meals.', 'curated', now()),
  ('Philips HD9200 Airfryer', 'philips-hd9200-airfryer', 'Entry-level air fryer for small households.', 'curated', now()),
  ('Tefal Easy Fry Essential 3.5L', 'tefal-easy-fry-essential-35l', 'Small countertop air fryer for weeknight cooking.', 'curated', now()),
  ('Hanabishi HAFEO-23SS Air Fryer Oven', 'hanabishi-hafeo-23ss-air-fryer-oven', 'Budget-friendly air fryer oven for Filipino kitchens.', 'curated', now()),
  ('Philips HD9306 Electric Kettle', 'philips-hd9306-electric-kettle', 'Stainless electric kettle for coffee, tea, and cooking.', 'curated', now()),
  ('Tefal KO2618 Electric Kettle', 'tefal-ko2618-electric-kettle', 'Compact kettle with a practical everyday footprint.', 'curated', now()),
  ('Xiaomi Electric Kettle 2', 'xiaomi-electric-kettle-2', 'Minimal electric kettle for hot drinks and meal prep.', 'curated', now()),
  ('Oster 1.5L Rice Cooker', 'oster-15l-rice-cooker', 'Simple rice cooker for small families and apartments.', 'curated', now()),
  ('Imarflex Electric Rice Cooker 1.8L', 'imarflex-electric-rice-cooker-18l', 'Everyday rice cooker with a generous household size.', 'curated', now()),
  ('Panasonic SR-W18G Rice Cooker', 'panasonic-sr-w18g-rice-cooker', 'Classic rice cooker for reliable daily meals.', 'curated', now()),
  ('Midea 1.7L Electric Kettle', 'midea-17l-electric-kettle', 'Large-capacity kettle for family kitchens.', 'curated', now()),
  ('Bialetti Moka Express 3-Cup', 'bialetti-moka-express-3-cup', 'Iconic stovetop brewer for strong coffee at home.', 'curated', now()),
  ('Timemore C2 Manual Coffee Grinder', 'timemore-c2-manual-coffee-grinder', 'Portable burr grinder for home and travel brewing.', 'curated', now()),
  ('Hario V60 Dripper 02', 'hario-v60-dripper-02', 'Pour-over brewer for controlled home coffee.', 'curated', now()),
  ('Hario V60 Coffee Server', 'hario-v60-coffee-server', 'Glass server for pour-over coffee and shared brews.', 'curated', now()),
  ('French Press 600ml', 'french-press-600ml', 'Straightforward coffee brewer for beginners.', 'curated', now()),
  ('Stanley Quencher H2.0 30oz', 'stanley-quencher-h20-30oz', 'Insulated tumbler for commuting, errands, and desk days.', 'curated', now()),
  ('Hydro Flask 21oz Standard Mouth', 'hydro-flask-21oz-standard-mouth', 'Reusable insulated bottle for everyday carry.', 'curated', now()),
  ('Tyeso Wonder 750ml Tumbler', 'tyeso-wonder-750ml-tumbler', 'Budget insulated tumbler for coffee and cold drinks.', 'curated', now()),
  ('LocknLock Metro Mug 475ml', 'locknlock-metro-mug-475ml', 'Leak-resistant travel mug for office and car use.', 'curated', now()),
  ('Klean Kanteen Classic 20oz', 'klean-kanteen-classic-20oz', 'Reusable stainless bottle with a simple durable design.', 'curated', now()),
  ('IKEA FROSET Chair', 'ikea-froset-chair', 'Lightweight occasional chair for compact homes.', 'curated', now()),
  ('IKEA LACK Wall Shelf', 'ikea-lack-wall-shelf', 'Minimal wall shelf for books, plants, and small decor.', 'curated', now()),
  ('IKEA RASKOG Utility Cart', 'ikea-raskog-utility-cart', 'Rolling storage cart for kitchens, crafts, and desks.', 'curated', now()),
  ('IKEA KALLAX Shelf Unit', 'ikea-kallax-shelf-unit', 'Flexible cubby storage for small-space organization.', 'curated', now()),
  ('Orocan Storage Box 30L', 'orocan-storage-box-30l', 'Stackable plastic storage for closets and utility spaces.', 'curated', now()),
  ('Lifestraw Personal Water Filter', 'lifestraw-personal-water-filter', 'Portable filter for travel, hiking, and emergency kits.', 'curated', now()),
  ('Black+Decker Dustbuster Hand Vacuum', 'black-decker-dustbuster-hand-vacuum', 'Compact handheld vacuum for crumbs and quick cleanups.', 'curated', now()),
  ('Deerma DX115C Stick Vacuum', 'deerma-dx115c-stick-vacuum', 'Lightweight vacuum for apartments and daily tidying.', 'curated', now()),
  ('Xiaomi Mi Robot Vacuum-Mop 2', 'xiaomi-mi-robot-vacuum-mop-2', 'Robot vacuum and mop for routine floor cleaning.', 'curated', now()),
  ('Karcher WV 2 Window Vacuum', 'karcher-wv-2-window-vacuum', 'Handheld window cleaner for glass and shower surfaces.', 'curated', now()),
  ('Philips GC362 Steam Iron', 'philips-gc362-steam-iron', 'Handheld steamer for quick clothing touch-ups.', 'curated', now()),
  ('Tefal Easygliss Plus Steam Iron', 'tefal-easygliss-plus-steam-iron', 'Everyday steam iron for workwear and school uniforms.', 'curated', now()),
  ('Uniqlo UV Protection Compact Umbrella', 'uniqlo-uv-protection-compact-umbrella', 'Compact umbrella for sun and sudden rain.', 'curated', now()),
  ('Naturehike Cloud-Up 2 Tent', 'naturehike-cloud-up-2-tent', 'Lightweight two-person tent for weekend trips.', 'curated', now()),
  ('Quechua NH100 Hiking Backpack 20L', 'quechua-nh100-hiking-backpack-20l', 'Daypack for short hikes, school, and travel.', 'curated', now()),
  ('CamelBak Eddy+ 750ml Bottle', 'camelbak-eddy-plus-750ml-bottle', 'Reusable bottle with a practical bite valve.', 'curated', now()),
  ('Nike Brasilia Training Duffel Bag', 'nike-brasilia-training-duffel-bag', 'Durable carry bag for gym and weekend use.', 'curated', now()),
  ('Adidas Essentials Training Backpack', 'adidas-essentials-training-backpack', 'Everyday backpack for gym gear and commuting.', 'curated', now()),
  ('Anker 622 Magnetic Battery', 'anker-622-magnetic-battery', 'Magnetic portable charger for compatible phones.', 'curated', now()),
  ('Belkin BoostCharge 10K Power Bank', 'belkin-boostcharge-10k-power-bank', 'Reliable portable battery for travel and workdays.', 'curated', now()),
  ('SanDisk Ultra 128GB microSD Card', 'sandisk-ultra-128gb-microsd-card', 'Expandable storage for phones, cameras, and consoles.', 'curated', now()),
  ('Samsung T7 Shield 1TB SSD', 'samsung-t7-shield-1tb-ssd', 'Fast portable storage with a rugged outer design.', 'curated', now()),
  ('WD Elements 2TB Portable Drive', 'wd-elements-2tb-portable-drive', 'Portable backup storage for photos and work files.', 'curated', now()),
  ('Kingston DataTraveler Exodia 128GB', 'kingston-datatraveler-exodia-128gb', 'Affordable USB storage for files and schoolwork.', 'curated', now()),
  ('Nintendo Switch Pro Controller', 'nintendo-switch-pro-controller', 'Comfortable controller for longer console sessions.', 'curated', now()),
  ('8BitDo Ultimate C Controller', '8bitdo-ultimate-c-controller', 'Affordable wireless controller for PC and console play.', 'curated', now()),
  ('LEGO Classic Medium Creative Brick Box', 'lego-classic-medium-creative-brick-box', 'Open-ended building set for children and creative adults.', 'curated', now()),
  ('LEGO Botanicals Succulents', 'lego-botanicals-succulents', 'Buildable desk decor and a low-maintenance gift idea.', 'curated', now()),
  ('Play-Doh Kitchen Creations Set', 'play-doh-kitchen-creations-set', 'Creative play set for pretend cooking and making.', 'curated', now()),
  ('Crayola Inspiration Art Case', 'crayola-inspiration-art-case', 'Portable art kit for school breaks and creative gifts.', 'curated', now()),
  ('Moleskine Classic Notebook Large', 'moleskine-classic-notebook-large', 'Hardcover notebook for notes, plans, and journaling.', 'curated', now()),
  ('Pilot FriXion Ball Clicker Set', 'pilot-frixion-ball-clicker-set', ' erasable pens for planners, notes, and schoolwork.', 'curated', now()),
  ('Zebra Mildliner Highlighter Set', 'zebra-mildliner-highlighter-set', 'Soft-color highlighters for study notes and planners.', 'curated', now()),
  ('National Book Store 2026 Planner', 'national-book-store-2026-planner', 'Practical dated planner for school, work, and home.', 'curated', now()),
  ('The Body Shop Shea Hand Balm', 'the-body-shop-shea-hand-balm', 'Small hand-care gift for desks and travel bags.', 'curated', now()),
  ('Human Nature Sunflower Beauty Oil', 'human-nature-sunflower-beauty-oil', 'Multi-use local beauty oil for simple self-care.', 'curated', now()),
  ('Belo SunExpert Face Cover SPF40', 'belo-sunexpert-face-cover-spf40', 'Daily sunscreen for commuting and outdoor errands.', 'curated', now()),
  ('Cetaphil Gentle Skin Cleanser', 'cetaphil-gentle-skin-cleanser', 'Mild cleanser for a straightforward daily routine.', 'curated', now()),
  ('Skechers Go Walk Shoes', 'skechers-go-walk-shoes', 'Comfort-focused walking shoes for errands and travel.', 'curated', now()),
  ('Crocs Classic Clog', 'crocs-classic-clog', 'Easy everyday footwear for home, errands, and travel.', 'curated', now()),
  ('Havaianas Top Flip Flops', 'havaianas-top-flip-flops', 'Simple warm-weather footwear for daily use.', 'curated', now()),
  ('Uniqlo AIRism Cotton T-Shirt', 'uniqlo-airism-cotton-t-shirt', 'Lightweight everyday shirt for warm Philippine weather.', 'curated', now()),
  ('Klean Kanteen Insulated Food Canister', 'klean-kanteen-insulated-food-canister', 'Reusable container for packed meals and snacks.', 'curated', now()),
  ('Sistema Klip It Plus Food Container Set', 'sistema-klip-it-plus-food-container-set', 'Stackable food containers for meal prep and leftovers.', 'curated', now()),
  ('Pyrex Glass Storage Set', 'pyrex-glass-storage-set', 'Oven-safe glass containers for cooking and storage.', 'curated', now()),
  ('Joseph Joseph Extend Expandable Trivet', 'joseph-joseph-extend-expandable-trivet', 'Compact kitchen trivet that expands for larger dishes.', 'curated', now()),
  ('OXO Good Grips Salad Spinner', 'oxo-good-grips-salad-spinner', 'Easy-to-use spinner for washing and drying greens.', 'curated', now()),
  ('Victorinox Swiss Classic Utility Knife', 'victorinox-swiss-classic-utility-knife', 'Reliable small kitchen knife for everyday prep.', 'curated', now()),
  ('Stanley Classic Legendary Bottle 1L', 'stanley-classic-legendary-bottle-1l', 'Large insulated bottle for workdays and outdoor trips.', 'curated', now()),
  ('Coleman 16-Can Soft Cooler', 'coleman-16-can-soft-cooler', 'Soft cooler for picnics, road trips, and family outings.', 'curated', now()),
  ('Nivea Men Sensitive Starter Kit', 'nivea-men-sensitive-starter-kit', 'Practical grooming set for simple daily routines.', 'curated', now()),
  ('Gillette Mach3 Razor Starter Pack', 'gillette-mach3-razor-starter-pack', 'Classic shaving starter set for an everyday grooming gift.', 'curated', now()),
  ('Philips OneBlade QP2724', 'philips-oneblade-qp2724', 'Compact hybrid trimmer for face and light styling.', 'curated', now()),
  ('Xiaomi Grooming Kit Pro', 'xiaomi-grooming-kit-pro', 'Multi-purpose grooming kit for home and travel.', 'curated', now()),
  ('Bellroy Card Pocket', 'bellroy-card-pocket', 'Slim leather card holder for a minimalist everyday carry.', 'curated', now()),
  ('Herschel Charlie Cardholder', 'herschel-charlie-cardholder', 'Compact card wallet for commuting and travel.', 'curated', now()),
  ('Samsonite Omni PC Spinner 20-inch', 'samsonite-omni-pc-spinner-20-inch', 'Hard-shell carry-on luggage for short trips.', 'curated', now()),
  ('American Tourister Curio Spinner 20-inch', 'american-tourister-curio-spinner-20-inch', 'Lightweight carry-on for weekend and work travel.', 'curated', now())
on conflict (slug) do update set
  name = excluded.name,
  description = excluded.description,
  source_type = excluded.source_type,
  freshness_at = excluded.freshness_at,
  updated_at = now();

-- Give each new product a concrete marketplace destination. The catalog URL is stable
-- across seller changes and keeps the listing usable while SKU-level links are refreshed.
insert into thebudolfinds.merchant_listings
  (product_id, merchant_id, external_id, canonical_url, title, currency, current_price, availability, source_updated_at)
select product.id, merchant.id, 'catalog-' || product.slug,
       'https://www.lazada.com.ph/catalog/?q=' || replace(product.name, ' ', '%20'),
       product.name, 'PHP', null, 'unknown', now()
from thebudolfinds.products product
join thebudolfinds.merchants merchant on merchant.slug = 'lazada'
where product.slug in (
  'anker-323-charger-33w','anker-nano-power-bank-30w','ugreen-nexode-65w-gan-charger','baseus-65w-gan5-fast-charger','anker-powerline-iii-usb-c-cable','ugreen-usb-c-hub-6-in-1','tp-link-archer-ax23-wifi-6-router','tp-link-re305-wifi-range-extender','xiaomi-mi-wifi-range-extender-ac1200','amazon-kindle-paperwhite-16gb','logitech-k380-bluetooth-keyboard','logitech-k480-bluetooth-keyboard','logitech-m720-triathlon-mouse','logitech-g304-lightspeed-gaming-mouse','razer-deathadder-essential-mouse','redragon-k552-kumara-mechanical-keyboard','aoc-24b2xh-24-inch-monitor','xiaomi-mi-computer-monitor-light-bar','jbl-go-3-portable-bluetooth-speaker','anker-soundcore-2-bluetooth-speaker','jbl-tune-520bt-wireless-headphones','anker-soundcore-q20i-headphones','baseus-bowie-ma10-earbuds','qcy-t13-anc-earbuds','tp-link-tapo-c200-security-camera','tp-link-tapo-c210-security-camera','tp-link-tapo-l530-smart-bulb','philips-hue-white-smart-bulb','xiaomi-mi-smart-led-bulb-essential','aqara-door-window-sensor','xiaomi-mi-smart-air-fryer-35l','philips-hd9200-airfryer','tefal-easy-fry-essential-35l','hanabishi-hafeo-23ss-air-fryer-oven','philips-hd9306-electric-kettle','tefal-ko2618-electric-kettle','xiaomi-electric-kettle-2','oster-15l-rice-cooker','imarflex-electric-rice-cooker-18l','panasonic-sr-w18g-rice-cooker','midea-17l-electric-kettle','bialetti-moka-express-3-cup','timemore-c2-manual-coffee-grinder','hario-v60-dripper-02','hario-v60-coffee-server','french-press-600ml','stanley-quencher-h20-30oz','hydro-flask-21oz-standard-mouth','tyeso-wonder-750ml-tumbler','locknlock-metro-mug-475ml','klean-kanteen-classic-20oz','ikea-froset-chair','ikea-lack-wall-shelf','ikea-raskog-utility-cart','ikea-kallax-shelf-unit','orocan-storage-box-30l','lifestraw-personal-water-filter','black-decker-dustbuster-hand-vacuum','deerma-dx115c-stick-vacuum','xiaomi-mi-robot-vacuum-mop-2','karcher-wv-2-window-vacuum','philips-gc362-steam-iron','tefal-easygliss-plus-steam-iron','uniqlo-uv-protection-compact-umbrella','naturehike-cloud-up-2-tent','quechua-nh100-hiking-backpack-20l','camelbak-eddy-plus-750ml-bottle','nike-brasilia-training-duffel-bag','adidas-essentials-training-backpack','anker-622-magnetic-battery','belkin-boostcharge-10k-power-bank','sandisk-ultra-128gb-microsd-card','samsung-t7-shield-1tb-ssd','wd-elements-2tb-portable-drive','kingston-datatraveler-exodia-128gb','nintendo-switch-pro-controller','8bitdo-ultimate-c-controller','lego-classic-medium-creative-brick-box','lego-botanicals-succulents','play-doh-kitchen-creations-set','crayola-inspiration-art-case','moleskine-classic-notebook-large','pilot-frixion-ball-clicker-set','zebra-mildliner-highlighter-set','national-book-store-2026-planner','the-body-shop-shea-hand-balm','human-nature-sunflower-beauty-oil','belo-sunexpert-face-cover-spf40','cetaphil-gentle-skin-cleanser','skechers-go-walk-shoes','crocs-classic-clog','havaianas-top-flip-flops','uniqlo-airism-cotton-t-shirt','klean-kanteen-insulated-food-canister','sistema-klip-it-plus-food-container-set','pyrex-glass-storage-set','joseph-joseph-extend-expandable-trivet','oxo-good-grips-salad-spinner','victorinox-swiss-classic-utility-knife','stanley-classic-legendary-bottle-1l','coleman-16-can-soft-cooler','nivea-men-sensitive-starter-kit','gillette-mach3-razor-starter-pack','philips-oneblade-qp2724','xiaomi-grooming-kit-pro','bellroy-card-pocket','herschel-charlie-cardholder','samsonite-omni-pc-spinner-20-inch','american-tourister-curio-spinner-20-inch'
)
on conflict (merchant_id, external_id) do update set
  canonical_url = excluded.canonical_url,
  title = excluded.title,
  current_price = excluded.current_price,
  availability = excluded.availability,
  source_updated_at = excluded.source_updated_at,
  updated_at = now();

-- Keep exactly 100 unique real products active, with one homepage placement each.
update thebudolfinds.homepage_feed_items set is_active = false, updated_at = now();

with chosen as (
  select product.id, row_number() over (order by product.name, product.id) as position
  from thebudolfinds.products product
  where product.slug not in ('fathers-day-tool-gift-pick', 'coffee-gift-for-dad', 'something-handmade-gift-pick', 'digital-door-lock-guide-pick')
    and exists (select 1 from thebudolfinds.merchant_listings listing where listing.product_id = product.id and listing.canonical_url like 'https://%')
  order by product.name, product.id
  limit 100
)
insert into thebudolfinds.homepage_feed_items
  (product_id, collection, collection_title, editorial_blurb, badge, collection_order, sort_order, is_active)
select chosen.id,
       case when chosen.position % 5 = 0 then 'home' when chosen.position % 5 = 1 then 'latest-finds' when chosen.position % 5 = 2 then 'for-your-desk' when chosen.position % 5 = 3 then 'gifts-that-dont-feel-generic' else 'under-500' end,
       case when chosen.position % 5 = 0 then 'Home' when chosen.position % 5 = 1 then 'Latest finds' when chosen.position % 5 = 2 then 'For your desk' when chosen.position % 5 = 3 then 'Gifts that don’t feel generic' else 'Under ₱500' end,
       'A real product listing selected for everyday use.',
       case when chosen.position % 5 = 3 then 'Giftable' else 'Editor pick' end,
       chosen.position % 5,
       chosen.position,
       true
from chosen
on conflict (collection, product_id) do update set is_active = true, updated_at = now();
