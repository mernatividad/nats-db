-- WhereTayo application schema. The public schema is intentionally not used.
create schema if not exists wheretayo;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists postgis with schema extensions;

set search_path = wheretayo, extensions, public;

create table wheretayo.neighborhoods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text not null,
  slug text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table wheretayo.venues (
  id uuid primary key default gen_random_uuid(),
  neighborhood_id uuid not null references wheretayo.neighborhoods(id),
  name text not null,
  slug text not null unique,
  address text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  location extensions.geography(point, 4326),
  price_tier smallint not null check (price_tier between 1 and 4),
  cover_image_url text,
  operating_hours jsonb not null default '{}'::jsonb,
  wifi_status text not null default 'unknown' check (wifi_status in ('yes', 'no', 'unknown')),
  sockets_status text not null default 'unknown' check (sockets_status in ('yes', 'no', 'unknown')),
  noise_level text not null default 'unknown' check (noise_level in ('quiet', 'moderate', 'lively', 'unknown')),
  outdoor_status text not null default 'unknown' check (outdoor_status in ('yes', 'no', 'unknown')),
  parking_status text not null default 'unknown' check (parking_status in ('yes', 'no', 'unknown')),
  work_friendly_status text not null default 'unknown' check (work_friendly_status in ('yes', 'no', 'unknown')),
  publication_status text not null default 'draft' check (publication_status in ('draft', 'review', 'published', 'archived')),
  is_verified boolean not null default false,
  last_verified_at timestamptz,
  source_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table wheretayo.vibes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  category text not null check (category in ('amenity', 'mood', 'crowd')),
  created_at timestamptz not null default now()
);

create table wheretayo.venue_vibes (
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  vibe_id uuid not null references wheretayo.vibes(id) on delete cascade,
  weight smallint not null check (weight between 1 and 10),
  primary key (venue_id, vibe_id)
);

create table wheretayo.venue_sources (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  provider text not null,
  provider_record_id text not null,
  source_url text,
  raw_payload jsonb not null default '{}'::jsonb,
  observed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (provider, provider_record_id)
);

create table wheretayo.venue_attribute_evidence (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  attribute_name text not null,
  attribute_value text not null,
  evidence_type text not null check (evidence_type in ('admin', 'provider', 'user_report', 'inference')),
  confidence text not null default 'unknown' check (confidence in ('verified', 'reported', 'inferred', 'unknown')),
  source_url text,
  observed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index venues_neighborhood_id_idx on wheretayo.venues (neighborhood_id);
create index venues_publication_status_idx on wheretayo.venues (publication_status);
create index venues_name_trgm_idx on wheretayo.venues using gin (name gin_trgm_ops);
create index venues_location_idx on wheretayo.venues using gist (location);
create index venue_vibes_vibe_id_idx on wheretayo.venue_vibes (vibe_id);

-- Keep location queries and URL-facing reads available, but keep provenance internal.
alter table wheretayo.neighborhoods enable row level security;
alter table wheretayo.venues enable row level security;
alter table wheretayo.vibes enable row level security;
alter table wheretayo.venue_vibes enable row level security;
alter table wheretayo.venue_sources enable row level security;
alter table wheretayo.venue_attribute_evidence enable row level security;

create policy "published neighborhoods are readable"
  on wheretayo.neighborhoods for select to anon, authenticated
  using (true);

create policy "published venues are readable"
  on wheretayo.venues for select to anon, authenticated
  using (publication_status = 'published');

create policy "vibes are readable"
  on wheretayo.vibes for select to anon, authenticated
  using (true);

create policy "published venue vibes are readable"
  on wheretayo.venue_vibes for select to anon, authenticated
  using (exists (
    select 1 from wheretayo.venues
    where venues.id = venue_vibes.venue_id
      and venues.publication_status = 'published'
  ));

revoke all on schema wheretayo from public;
grant usage on schema wheretayo to anon, authenticated, service_role;

revoke all on all tables in schema wheretayo from public;
grant select on wheretayo.neighborhoods, wheretayo.venues, wheretayo.vibes, wheretayo.venue_vibes to anon, authenticated;
grant all on all tables in schema wheretayo to service_role;

alter default privileges in schema wheretayo revoke execute on functions from public;
alter default privileges in schema wheretayo revoke all on tables from public;
alter default privileges in schema wheretayo grant select on tables to anon, authenticated;
alter default privileges in schema wheretayo grant all on tables to service_role;
