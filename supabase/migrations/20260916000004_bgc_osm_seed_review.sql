-- Initial BGC discovery queue sourced from OpenStreetMap.
-- These records intentionally remain in review until a human verifies price,
-- amenities, operating hours, and current availability.
with neighborhood as (
  insert into wheretayo.neighborhoods (name, city, slug)
  values ('Bonifacio Global City', 'Taguig', 'bonifacio-global-city')
  on conflict (slug) do update set name = excluded.name
  returning id
)
insert into wheretayo.venues (
  neighborhood_id, name, slug, address, latitude, longitude, location,
  price_tier, publication_status, is_verified
)
select
  neighborhood.id,
  seed.name,
  seed.slug,
  seed.address,
  seed.latitude,
  seed.longitude,
  extensions.st_setsrid(extensions.st_makepoint(seed.longitude, seed.latitude), 4326)::extensions.geography,
  2,
  'review',
  false
from neighborhood
cross join (values
  ('Phò Bac', 'pho-bac', '32nd Street, Bonifacio Global City, Taguig', 14.5539473, 121.0479247),
  ('Zhu', 'zhu', '5th Avenue, Bonifacio Global City, Taguig', 14.5539752, 121.0483780),
  ('Pancake House', 'pancake-house', '7th Avenue, Bonifacio Global City, Taguig', 14.5511979, 121.0498801),
  ('Starbucks · 7th Avenue', 'starbucks-7th-avenue', '7th Avenue, Bonifacio Global City, Taguig', 14.5511801, 121.0499456),
  ('Krispy Kreme', 'krispy-kreme-9th-avenue', '9th Avenue, Bonifacio Global City, Taguig', 14.5503625, 121.0509495),
  ('Texas Roadhouse Grill', 'texas-roadhouse-grill', 'Bonifacio Global City, Taguig', 14.5506953, 121.0498979),
  ('McDonald''s · 32nd Street', 'mcdonalds-32nd-street', '32nd Street, Bonifacio Global City, Taguig', 14.5541303, 121.0482454),
  ('Pound by Todd English', 'pound-by-todd-english', '7th Avenue, Bonifacio Global City, Taguig', 14.5510574, 121.0503647),
  ('TGI Fridays', 'tgi-fridays-9th-avenue', '9th Avenue, Bonifacio Global City, Taguig', 14.5510342, 121.0506370),
  ('UCC Coffee Café Terrace', 'ucc-coffee-cafe-terrace', '26th Street, Bonifacio Global City, Taguig', 14.5502274, 121.0447164),
  ('St. Marc Café', 'st-marc-cafe-7th-avenue', '7th Avenue, Bonifacio Global City, Taguig', 14.5502388, 121.0494648),
  ('Pizza Hut · 32nd Street', 'pizza-hut-32nd-street', '32nd Street, Bonifacio Global City, Taguig', 14.5541045, 121.0496632),
  ('Brother''s Burger', 'brothers-burger-9th-avenue', '9th Avenue, Bonifacio Global City, Taguig', 14.5501827, 121.0515374),
  ('Jones all day', 'jones-all-day', 'McKinley Parkway, Bonifacio Global City, Taguig', 14.5494552, 121.0541381)
) as seed(name, slug, address, latitude, longitude)
on conflict (slug) do nothing;

insert into wheretayo.venue_sources (venue_id, provider, provider_record_id, source_url, raw_payload)
select
  venues.id,
  'openstreetmap',
  seed.osm_id,
  'https://www.openstreetmap.org/node/' || seed.osm_id,
  jsonb_build_object('amenity', seed.amenity, 'import_status', 'review')
from wheretayo.venues
join (values
  ('pho-bac', '251456679', 'restaurant'),
  ('zhu', '251456682', 'restaurant'),
  ('pancake-house', '251456684', 'restaurant'),
  ('starbucks-7th-avenue', '251456685', 'cafe'),
  ('krispy-kreme-9th-avenue', '255056800', 'fast_food'),
  ('texas-roadhouse-grill', '255058205', 'restaurant'),
  ('mcdonalds-32nd-street', '255058509', 'fast_food'),
  ('pound-by-todd-english', '255058768', 'restaurant'),
  ('tgi-fridays-9th-avenue', '255059462', 'restaurant'),
  ('ucc-coffee-cafe-terrace', '255060418', 'cafe'),
  ('st-marc-cafe-7th-avenue', '255062506', 'cafe'),
  ('pizza-hut-32nd-street', '255064744', 'restaurant'),
  ('brothers-burger-9th-avenue', '255064955', 'fast_food'),
  ('jones-all-day', '255070297', 'restaurant')
) as seed(slug, osm_id, amenity) on seed.slug = venues.slug
on conflict (provider, provider_record_id) do nothing;
