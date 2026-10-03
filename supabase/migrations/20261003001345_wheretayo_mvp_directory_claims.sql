-- Make the public listing minimum usable with broad, source-backed coverage.
alter table wheretayo.venues
  add column category text
    check (category in ('cafe', 'restaurant', 'quick_bite', 'bar', 'coffee_shop', 'bakery', 'shop', 'other')),
  add column website_url text check (website_url is null or website_url ~ '^https?://'),
  add column phone text,
  add column short_description text check (short_description is null or char_length(short_description) <= 280),
  add column owner_claimed_at timestamptz;

alter table wheretayo.venues
  alter column price_tier drop not null,
  alter column price_tier drop default;

alter table wheretayo.venue_sources
  add column license_name text,
  add column license_url text,
  add column import_batch text;

update wheretayo.venue_sources
   set license_name = 'Open Database License (ODbL) 1.0',
       license_url = 'https://opendatacommons.org/licenses/odbl/1-0/'
 where provider = 'openstreetmap' and license_name is null;

-- Qualify older numeric OSM IDs with their element type before the importer refreshes records.
update wheretayo.venue_sources source
   set provider_record_id = regexp_replace(source.source_url, '^https://www[.]openstreetmap[.]org/', '')
 where source.provider = 'openstreetmap'
   and source.provider_record_id !~ '/'
   and source.source_url ~ '^https://www[.]openstreetmap[.]org/(node|way|relation)/[0-9]+$'
   and not exists (
     select 1 from wheretayo.venue_sources existing
      where existing.provider = 'openstreetmap'
        and existing.provider_record_id = regexp_replace(source.source_url, '^https://www[.]openstreetmap[.]org/', '')
   );

-- Older unreviewed imports used the schema default as if price had been checked.
update wheretayo.venues venue
   set price_tier = null
 where venue.publication_status in ('review', 'draft')
   and venue.price_tier = 2
   and exists (
     select 1 from wheretayo.venue_sources source
      where source.venue_id = venue.id
        and source.provider = 'openstreetmap'
   )
   and not exists (
     select 1 from wheretayo.venue_attribute_evidence evidence
      where evidence.venue_id = venue.id
        and evidence.attribute_name = 'price_tier'
        and evidence.confidence = 'verified'
   );

-- Normalize the limited OSM category set already accepted by the importer.
update wheretayo.venues venue
   set category = case
     when lower(coalesce(source.raw_payload->>'amenity', '')) = 'cafe' then 'cafe'
     when lower(coalesce(source.raw_payload->>'amenity', '')) = 'restaurant' then 'restaurant'
     when lower(coalesce(source.raw_payload->>'amenity', '')) = 'fast_food' then 'quick_bite'
     when lower(coalesce(source.raw_payload->>'amenity', '')) in ('bar', 'pub') then 'bar'
     when lower(coalesce(source.raw_payload->>'shop', '')) = 'coffee' then 'coffee_shop'
     else 'other'
   end,
       source_updated_at = greatest(venue.source_updated_at, source.observed_at)
  from wheretayo.venue_sources source
 where source.venue_id = venue.id
   and source.provider = 'openstreetmap'
   and venue.category is null;

insert into wheretayo.venue_attribute_evidence (
  venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url, observed_at
)
select venue.id, 'category', venue.category, 'provider', 'reported', source.source_url, source.observed_at
  from wheretayo.venues venue
  join wheretayo.venue_sources source on source.venue_id = venue.id
 where source.provider = 'openstreetmap'
   and venue.category is not null
   and not exists (
     select 1 from wheretayo.venue_attribute_evidence evidence
      where evidence.venue_id = venue.id
        and evidence.attribute_name = 'category'
        and evidence.evidence_type = 'provider'
   );

-- Public clients may see attribution metadata for published places, but never raw payloads.
create policy "published venue source attribution is readable"
  on wheretayo.venue_sources for select to anon, authenticated
  using (exists (
    select 1 from wheretayo.venues venue
     where venue.id = venue_sources.venue_id
       and venue.publication_status = 'published'
  ));

grant select (venue_id, provider, source_url, observed_at)
  on wheretayo.venue_sources to anon, authenticated;
revoke select (raw_payload, provider_record_id, license_name, license_url, import_batch)
  on wheretayo.venue_sources from anon, authenticated;

-- Private submission tables are only reachable through server-side actions.
create table wheretayo.venue_suggestions (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  suggestion_type text not null check (suggestion_type in ('correction', 'closure', 'accuracy')),
  field_name text check (field_name in ('name', 'category', 'address', 'price_tier', 'operating_hours', 'wifi_status', 'sockets_status', 'noise_level', 'outdoor_status', 'parking_status', 'work_friendly_status', 'website_url', 'phone', 'short_description')),
  suggested_value text,
  is_accurate boolean,
  details text,
  contact_email text,
  status text not null default 'pending' check (status in ('pending', 'resolved', 'declined')),
  reviewer text,
  review_notes text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  check (
    (suggestion_type = 'correction' and field_name is not null and nullif(trim(suggested_value), '') is not null)
    or (suggestion_type = 'closure')
    or (suggestion_type = 'accuracy' and field_name is not null and is_accurate is not null)
  )
);

create index venue_suggestions_status_created_idx
  on wheretayo.venue_suggestions (status, created_at desc);

create table wheretayo.venue_claim_requests (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  claimant_name text not null check (char_length(trim(claimant_name)) between 2 and 120),
  contact_email text not null check (char_length(trim(contact_email)) between 3 and 254),
  contact_phone text,
  business_role text not null check (business_role in ('owner', 'manager', 'authorized_representative')),
  verification_channel text not null check (verification_channel in ('business_email', 'business_phone', 'business_social', 'local_visit')),
  notes text,
  status text not null default 'pending' check (status in ('pending', 'reviewing', 'approved', 'denied', 'revoked')),
  reviewed_by text,
  review_notes text,
  reviewed_at timestamptz,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table wheretayo.venue_claim_events (
  id uuid primary key default gen_random_uuid(),
  claim_request_id uuid not null references wheretayo.venue_claim_requests(id) on delete cascade,
  previous_status text,
  new_status text not null check (new_status in ('pending', 'reviewing', 'approved', 'denied', 'revoked')),
  reviewer text not null,
  notes text,
  created_at timestamptz not null default now()
);

alter table wheretayo.venue_claim_requests alter column contact_email drop not null;

create index venue_claim_requests_status_created_idx
  on wheretayo.venue_claim_requests (status, created_at desc);
create unique index venue_claim_requests_one_active_per_venue_idx
  on wheretayo.venue_claim_requests (venue_id)
  where status in ('pending', 'reviewing', 'approved');

create table wheretayo.venue_change_proposals (
  id uuid primary key default gen_random_uuid(),
  claim_request_id uuid not null references wheretayo.venue_claim_requests(id) on delete cascade,
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  changes jsonb not null check (
    jsonb_typeof(changes) = 'object'
    and changes <> '{}'::jsonb
    and changes - array['name', 'category', 'address', 'price_tier', 'operating_hours', 'wifi_status', 'sockets_status', 'noise_level', 'outdoor_status', 'parking_status', 'work_friendly_status', 'website_url', 'phone', 'short_description']::text[] = '{}'::jsonb
  ),
  notes text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied')),
  reviewed_by text,
  review_notes text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index venue_change_proposals_status_created_idx
  on wheretayo.venue_change_proposals (status, created_at desc);

create table wheretayo.venue_field_change_events (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  change_source text not null check (change_source in ('public_correction', 'owner_proposal')),
  actor text not null,
  previous_values jsonb not null check (jsonb_typeof(previous_values) = 'object'),
  new_values jsonb not null check (jsonb_typeof(new_values) = 'object'),
  source_url text,
  suggestion_id uuid references wheretayo.venue_suggestions(id),
  proposal_id uuid references wheretayo.venue_change_proposals(id),
  created_at timestamptz not null default now(),
  check ((suggestion_id is not null and proposal_id is null) or (suggestion_id is null and proposal_id is not null))
);
create index venue_field_change_events_venue_idx on wheretayo.venue_field_change_events (venue_id, created_at desc);

create table wheretayo.venue_contact_messages (
  id uuid primary key default gen_random_uuid(),
  contact_name text check (contact_name is null or char_length(contact_name) <= 120),
  contact_email text check (contact_email is null or char_length(contact_email) <= 254),
  subject text not null check (subject in ('general', 'privacy', 'access', 'removal', 'other')),
  message text not null check (char_length(trim(message)) between 10 and 3000),
  status text not null default 'pending' check (status in ('pending', 'resolved', 'declined')),
  reviewer text,
  review_notes text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
create index venue_contact_messages_queue_idx on wheretayo.venue_contact_messages (status, created_at desc);

create table wheretayo.public_daily_metrics (
  metric_date date not null default current_date,
  event_name text not null check (event_name in ('directory_search', 'listing_view', 'directions_click', 'official_site_click', 'correction_start', 'correction_submit', 'claim_start', 'claim_submit', 'claim_approved', 'claim_denied', 'owner_edit_start', 'owner_edit_submit', 'owner_edit_approved', 'contact_submit')),
  area_slug text not null default 'bonifacio-global-city',
  venue_slug text not null default '',
  event_count bigint not null default 1 check (event_count > 0),
  updated_at timestamptz not null default now(),
  primary key (metric_date, event_name, area_slug, venue_slug)
);

create table wheretayo.public_request_limits (
  bucket_hash text primary key check (char_length(bucket_hash) = 64),
  window_started_at timestamptz not null,
  request_count integer not null check (request_count > 0),
  updated_at timestamptz not null default now()
);

alter table wheretayo.venue_suggestions enable row level security;
alter table wheretayo.venue_claim_requests enable row level security;
alter table wheretayo.venue_claim_events enable row level security;
alter table wheretayo.venue_change_proposals enable row level security;
alter table wheretayo.venue_field_change_events enable row level security;
alter table wheretayo.venue_contact_messages enable row level security;
alter table wheretayo.public_daily_metrics enable row level security;
alter table wheretayo.public_request_limits enable row level security;

revoke all on wheretayo.venue_suggestions, wheretayo.venue_claim_requests, wheretayo.venue_claim_events,
  wheretayo.venue_change_proposals, wheretayo.venue_field_change_events, wheretayo.public_request_limits,
  wheretayo.venue_contact_messages, wheretayo.public_daily_metrics
  from public, anon, authenticated;
grant all on wheretayo.venue_suggestions, wheretayo.venue_claim_requests, wheretayo.venue_claim_events,
  wheretayo.venue_change_proposals, wheretayo.venue_field_change_events, wheretayo.public_request_limits to service_role;
grant all on wheretayo.venue_contact_messages, wheretayo.public_daily_metrics to service_role;

-- Atomic rate-limit consumption for server-side public forms; the raw IP never enters the database.
create or replace function wheretayo.consume_public_request_limit(
  p_bucket_hash text,
  p_limit integer,
  p_window_seconds integer
)
returns boolean
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_count integer;
begin
  if p_bucket_hash !~ '^[a-f0-9]{64}$' then
    raise exception 'A hashed rate-limit bucket is required';
  end if;
  if p_limit < 1 or p_window_seconds < 1 then
    raise exception 'Rate-limit settings must be positive';
  end if;

  insert into wheretayo.public_request_limits as current_limit (
    bucket_hash, window_started_at, request_count, updated_at
  ) values (p_bucket_hash, now(), 1, now())
  on conflict (bucket_hash) do update
    set window_started_at = case
          when current_limit.window_started_at <= now() - make_interval(secs => p_window_seconds) then now()
          else current_limit.window_started_at
        end,
        request_count = case
          when current_limit.window_started_at <= now() - make_interval(secs => p_window_seconds) then 1
          else current_limit.request_count + 1
        end,
        updated_at = now()
  where current_limit.window_started_at <= now() - make_interval(secs => p_window_seconds)
     or current_limit.request_count < p_limit
  returning request_count into v_count;

  delete from wheretayo.public_request_limits
   where window_started_at < now() - interval '2 days';

  return v_count is not null;
end;
$$;

revoke all on function wheretayo.consume_public_request_limit(text, integer, integer) from public, anon, authenticated;
grant execute on function wheretayo.consume_public_request_limit(text, integer, integer) to service_role;

create or replace function wheretayo.record_public_metric(p_event_name text, p_area_slug text, p_venue_slug text default null)
returns void
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
begin
  if p_event_name not in ('directory_search', 'listing_view', 'directions_click', 'official_site_click', 'correction_start', 'correction_submit', 'claim_start', 'claim_submit', 'claim_approved', 'claim_denied', 'owner_edit_start', 'owner_edit_submit', 'owner_edit_approved', 'contact_submit') then
    raise exception 'Unsupported event';
  end if;
  if char_length(coalesce(p_area_slug, '')) > 80 or char_length(coalesce(p_venue_slug, '')) > 160 then raise exception 'Invalid event dimensions'; end if;
  insert into wheretayo.public_daily_metrics (metric_date, event_name, area_slug, venue_slug, event_count, updated_at)
  values (current_date, p_event_name, coalesce(nullif(p_area_slug, ''), 'unknown'), coalesce(p_venue_slug, ''), 1, now())
  on conflict (metric_date, event_name, area_slug, venue_slug)
  do update set event_count = wheretayo.public_daily_metrics.event_count + 1, updated_at = now();
end;
$$;
revoke all on function wheretayo.record_public_metric(text, text, text) from public, anon, authenticated;
grant execute on function wheretayo.record_public_metric(text, text, text) to service_role;

create or replace function wheretayo.review_venue_contact_message(p_message_id uuid, p_reviewer text, p_status text, p_notes text default null)
returns void
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
begin
  if nullif(trim(p_reviewer), '') is null then raise exception 'Reviewer is required'; end if;
  if p_status not in ('resolved', 'declined') then raise exception 'Invalid contact message status'; end if;
  update wheretayo.venue_contact_messages set status = p_status, reviewer = trim(p_reviewer), review_notes = nullif(trim(p_notes), ''), reviewed_at = now()
   where id = p_message_id and status = 'pending';
  if not found then raise exception 'Pending contact message not found'; end if;
end;
$$;
revoke all on function wheretayo.review_venue_contact_message(uuid, text, text, text) from public, anon, authenticated;
grant execute on function wheretayo.review_venue_contact_message(uuid, text, text, text) to service_role;

create or replace function wheretayo.submit_venue_claim(
  p_venue_id uuid,
  p_claimant_name text,
  p_contact_email text,
  p_contact_phone text,
  p_business_role text,
  p_verification_channel text,
  p_notes text
)
returns uuid
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_claim_id uuid;
begin
  if not exists (select 1 from wheretayo.venues where id = p_venue_id and publication_status = 'published' and owner_claimed_at is null) then
    raise exception 'This listing cannot accept a new claim request';
  end if;
  insert into wheretayo.venue_claim_requests (
    venue_id, claimant_name, contact_email, contact_phone, business_role, verification_channel, notes
  ) values (
    p_venue_id, trim(p_claimant_name), lower(trim(p_contact_email)), nullif(trim(p_contact_phone), ''),
    p_business_role, p_verification_channel, nullif(trim(p_notes), '')
  ) returning id into v_claim_id;
  insert into wheretayo.venue_claim_events (claim_request_id, previous_status, new_status, reviewer, notes)
  values (v_claim_id, null, 'pending', 'system', 'Claim request submitted; business verification is pending.');
  return v_claim_id;
end;
$$;
revoke all on function wheretayo.submit_venue_claim(uuid, text, text, text, text, text, text) from public, anon, authenticated;
grant execute on function wheretayo.submit_venue_claim(uuid, text, text, text, text, text, text) to service_role;

-- Imports remain in review; prices stay unknown until a source actually establishes them.
create or replace function wheretayo.import_review_venues(
  p_neighborhood_id uuid,
  p_records jsonb
)
returns integer
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_imported integer;
begin
  if p_neighborhood_id is null then
    raise exception 'A neighborhood is required';
  end if;
  if p_records is null or jsonb_typeof(p_records) <> 'array' then
    raise exception 'Review venue records must be a JSON array';
  end if;
  if jsonb_array_length(p_records) > 1000 then
    raise exception 'A review import may contain at most 1000 records';
  end if;

  with records as (
    select distinct on (record.source_record_id)
      record.source_record_id,
      record.source_type,
      record.source_url,
      record.raw_payload,
      record.name,
      record.slug,
      record.address,
      record.latitude,
      record.longitude,
      record.category,
      record.import_batch
    from jsonb_to_recordset(p_records) as record(
      source_record_id text,
      source_type text,
      source_url text,
      raw_payload jsonb,
      name text,
      slug text,
      address text,
      latitude double precision,
      longitude double precision,
      category text,
      import_batch text
    )
    where nullif(trim(record.source_record_id), '') is not null
      and nullif(trim(record.name), '') is not null
      and nullif(trim(record.slug), '') is not null
      and record.latitude between -90 and 90
      and record.longitude between -180 and 180
    order by record.source_record_id
  ),
  fresh as (
    select records.*
      from records
     where not exists (
       select 1 from wheretayo.venue_sources source
        where source.provider = 'openstreetmap'
          and source.provider_record_id = records.source_record_id
     )
  ),
  inserted as (
    insert into wheretayo.venues (
      neighborhood_id, name, slug, address, latitude, longitude, category,
      price_tier, publication_status, is_verified, source_updated_at
    )
    select p_neighborhood_id, fresh.name, fresh.slug,
      coalesce(nullif(trim(fresh.address), ''), 'Address needs checking'),
      fresh.latitude, fresh.longitude, fresh.category,
      null, 'review', false, now()
      from fresh
    on conflict (slug) do nothing
    returning id, slug
  )
  insert into wheretayo.venue_sources (
    venue_id, provider, provider_record_id, source_url, raw_payload, license_name, license_url, import_batch
  )
  select inserted.id, 'openstreetmap', fresh.source_record_id, fresh.source_url,
    coalesce(fresh.raw_payload, '{}'::jsonb), 'Open Database License (ODbL) 1.0',
    'https://opendatacommons.org/licenses/odbl/1-0/', fresh.import_batch
    from fresh
    join inserted on inserted.slug = fresh.slug
  on conflict (provider, provider_record_id) do nothing;

  get diagnostics v_imported = row_count;
  insert into wheretayo.venue_attribute_evidence (
    venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url, observed_at
  )
  select venue.id, 'category', venue.category, 'provider', 'reported', source.source_url, source.observed_at
    from jsonb_to_recordset(p_records) submitted(source_record_id text)
    join wheretayo.venue_sources source on source.provider = 'openstreetmap' and source.provider_record_id = submitted.source_record_id
    join wheretayo.venues venue on venue.id = source.venue_id
   where venue.category is not null
     and not exists (
       select 1 from wheretayo.venue_attribute_evidence evidence
        where evidence.venue_id = venue.id and evidence.attribute_name = 'category' and evidence.evidence_type = 'provider'
     );
  return v_imported;
end;
$$;

revoke all on function wheretayo.import_review_venues(uuid, jsonb) from public, anon, authenticated;
grant execute on function wheretayo.import_review_venues(uuid, jsonb) to service_role;

create or replace function wheretayo.refresh_review_venue(
  p_source_record_id text,
  p_name text,
  p_address text,
  p_latitude double precision,
  p_longitude double precision,
  p_category text,
  p_source_url text,
  p_raw_payload jsonb,
  p_import_batch text
)
returns jsonb
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_source wheretayo.venue_sources%rowtype;
  v_venue wheretayo.venues%rowtype;
  v_next_category text;
begin
  if nullif(trim(p_source_record_id), '') is null or nullif(trim(p_name), '') is null then raise exception 'Source identity and business name are required'; end if;
  if p_latitude is null or p_latitude not between -90 and 90 or p_longitude is null or p_longitude not between -180 and 180 then raise exception 'Valid source coordinates are required'; end if;
  if p_category not in ('cafe', 'restaurant', 'quick_bite', 'bar', 'coffee_shop', 'bakery', 'shop', 'other') then raise exception 'Unsupported source category'; end if;
  if trim(coalesce(p_source_url, '')) !~ '^https?://' then raise exception 'Source URL is required'; end if;

  select * into v_source from wheretayo.venue_sources
   where provider = 'openstreetmap' and provider_record_id = p_source_record_id for update;
  if v_source.id is null then raise exception 'Source record not found: %', p_source_record_id; end if;
  select * into v_venue from wheretayo.venues where id = v_source.venue_id for update;
  if v_venue.publication_status not in ('review', 'draft') then
    return jsonb_build_object('refreshed', false, 'reason', 'published or archived listings are protected');
  end if;

  v_next_category := case
    when exists (select 1 from wheretayo.venue_attribute_evidence where venue_id = v_venue.id and attribute_name = 'category' and evidence_type = 'admin' and confidence = 'verified') then v_venue.category
    else p_category
  end;
  update wheretayo.venues venue set
    name = case when exists (select 1 from wheretayo.venue_attribute_evidence where venue_id = v_venue.id and attribute_name = 'name' and evidence_type = 'admin' and confidence = 'verified') then venue.name else trim(p_name) end,
    address = case when p_address <> 'Address needs checking' and not exists (select 1 from wheretayo.venue_attribute_evidence where venue_id = v_venue.id and attribute_name = 'address' and evidence_type = 'admin' and confidence = 'verified') then p_address else venue.address end,
    latitude = p_latitude,
    longitude = p_longitude,
    category = v_next_category,
    source_updated_at = now(),
    updated_at = now()
   where venue.id = v_venue.id;
  update wheretayo.venue_sources
     set source_url = p_source_url, raw_payload = coalesce(p_raw_payload, '{}'::jsonb), observed_at = now(), import_batch = p_import_batch,
         license_name = 'Open Database License (ODbL) 1.0', license_url = 'https://opendatacommons.org/licenses/odbl/1-0/'
   where id = v_source.id;
  if v_next_category is distinct from v_venue.category then
    insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
    values (v_venue.id, 'category', v_next_category, 'provider', 'reported', p_source_url);
  end if;
  return jsonb_build_object('refreshed', true, 'venue_id', v_venue.id, 'category_updated', v_next_category is distinct from v_venue.category);
end;
$$;
revoke all on function wheretayo.refresh_review_venue(text, text, text, double precision, double precision, text, text, jsonb, text) from public, anon, authenticated;
grant execute on function wheretayo.refresh_review_venue(text, text, text, double precision, double precision, text, text, jsonb, text) to service_role;

-- Publishing now means the place has a usable identity and location, not that every
-- practical detail or vibe has been independently verified.
create or replace function wheretayo.publish_venue(
  p_slug text,
  p_reviewer text,
  p_notes text,
  p_source_url text,
  p_facts jsonb,
  p_vibes jsonb
)
returns uuid
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_venue_id uuid;
  v_status text;
  v_category text;
  v_fully_reviewed_facts constant text[] := array[
    'price_tier', 'wifi_status', 'sockets_status', 'noise_level',
    'outdoor_status', 'parking_status', 'work_friendly_status',
    'address', 'operating_hours'
  ];
  v_all_facts_reviewed boolean := false;
begin
  if char_length(trim(coalesce(p_reviewer, ''))) < 2 then
    raise exception 'A reviewer name is required';
  end if;
  if trim(coalesce(p_source_url, '')) !~ '^https?://' then
    raise exception 'A supporting source URL is required';
  end if;
  if jsonb_typeof(coalesce(p_facts, '{}'::jsonb)) <> 'object'
     or jsonb_typeof(coalesce(p_vibes, '{}'::jsonb)) <> 'object' then
    raise exception 'Venue facts and vibes must be JSON objects';
  end if;
  if exists (
    select 1 from jsonb_object_keys(coalesce(p_facts, '{}'::jsonb)) requested(name)
     where requested.name <> all (array['category', 'price_tier', 'wifi_status', 'sockets_status', 'noise_level', 'outdoor_status', 'parking_status', 'work_friendly_status', 'address', 'operating_hours']::text[])
  ) then raise exception 'One or more publication facts are not supported'; end if;
  if p_facts ? 'price_tier'
     and nullif(p_facts->>'price_tier', '') is not null
     and (p_facts->>'price_tier')::smallint not between 1 and 4 then
    raise exception 'Price tier must be between 1 and 4 or unknown';
  end if;
  if p_facts ? 'operating_hours' and jsonb_typeof(p_facts->'operating_hours') <> 'object' then
    raise exception 'Operating hours must be a JSON object';
  end if;

  select id, publication_status, category
    into v_venue_id, v_status, v_category
    from wheretayo.venues
   where slug = p_slug
   for update;

  if v_venue_id is null then
    raise exception 'Venue not found: %', p_slug;
  end if;
  if v_status <> 'review' then
    raise exception 'Only review venues can be published';
  end if;

  v_category := coalesce(nullif(trim(p_facts->>'category'), ''), v_category);
  if v_category is null then
    raise exception 'A verified or source-backed venue category is required';
  end if;
  v_all_facts_reviewed := coalesce(p_facts ?& v_fully_reviewed_facts
    and nullif(trim(p_facts->>'address'), '') is not null
    and (p_facts->>'price_tier') ~ '^[1-4]$'
    and p_facts->>'wifi_status' in ('yes', 'no')
    and p_facts->>'sockets_status' in ('yes', 'no')
    and p_facts->>'noise_level' in ('quiet', 'moderate', 'lively')
    and p_facts->>'outdoor_status' in ('yes', 'no')
    and p_facts->>'parking_status' in ('yes', 'no')
    and p_facts->>'work_friendly_status' in ('yes', 'no')
    and jsonb_typeof(p_facts->'operating_hours') = 'object'
    and p_facts->'operating_hours' <> '{}'::jsonb, false);
  if exists (
    select 1 from jsonb_object_keys(coalesce(p_vibes, '{}'::jsonb)) requested(slug)
      left join wheretayo.vibes vibe on vibe.slug = requested.slug
     where vibe.id is null
  ) then
    raise exception 'One or more vibe slugs do not exist';
  end if;

  update wheretayo.venues
     set category = v_category,
         price_tier = case when p_facts ? 'price_tier' then nullif(p_facts->>'price_tier', '')::smallint else price_tier end,
         wifi_status = coalesce(p_facts->>'wifi_status', wifi_status),
         sockets_status = coalesce(p_facts->>'sockets_status', sockets_status),
         noise_level = coalesce(p_facts->>'noise_level', noise_level),
         outdoor_status = coalesce(p_facts->>'outdoor_status', outdoor_status),
         parking_status = coalesce(p_facts->>'parking_status', parking_status),
         work_friendly_status = coalesce(p_facts->>'work_friendly_status', work_friendly_status),
         address = coalesce(nullif(trim(p_facts->>'address'), ''), address),
         operating_hours = coalesce(p_facts->'operating_hours', operating_hours),
         publication_status = 'published',
         is_verified = v_all_facts_reviewed,
         last_verified_at = case when v_all_facts_reviewed then now() else null end,
         updated_at = now()
   where id = v_venue_id;

  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, fact.key, fact.value, 'admin', 'verified', trim(p_source_url)
    from jsonb_each_text(coalesce(p_facts, '{}'::jsonb)) fact
   where fact.key <> 'operating_hours';

  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, 'operating_hours', (p_facts->'operating_hours')::text, 'admin', 'verified', trim(p_source_url)
   where p_facts ? 'operating_hours';

  insert into wheretayo.venue_vibes (venue_id, vibe_id, weight)
  select v_venue_id, vibe.id, (requested.value)::smallint
    from jsonb_each_text(coalesce(p_vibes, '{}'::jsonb)) requested
    join wheretayo.vibes vibe on vibe.slug = requested.key
  on conflict (venue_id, vibe_id) do update set weight = excluded.weight;

  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, 'vibe:' || requested.key, requested.value, 'admin', 'verified', trim(p_source_url)
    from jsonb_each_text(coalesce(p_vibes, '{}'::jsonb)) requested;

  insert into wheretayo.venue_review_events (venue_id, previous_status, new_status, reviewer, notes)
  values (v_venue_id, 'review', 'published', trim(p_reviewer), nullif(trim(p_notes), ''));

  return v_venue_id;
end;
$$;

revoke all on function wheretayo.publish_venue(text, text, text, text, jsonb, jsonb) from public, anon, authenticated;
grant execute on function wheretayo.publish_venue(text, text, text, text, jsonb, jsonb) to service_role;

-- Save review progress with source-backed categories while leaving unsupported values unknown.
create or replace function wheretayo.save_review_facts(
  p_slug text,
  p_reviewer text,
  p_source_url text,
  p_facts jsonb,
  p_vibes jsonb,
  p_notes text
)
returns uuid
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_venue_id uuid;
  v_status text;
  v_allowed_facts constant text[] := array[
    'category', 'price_tier', 'wifi_status', 'sockets_status', 'noise_level',
    'outdoor_status', 'parking_status', 'work_friendly_status',
    'address', 'operating_hours'
  ];
begin
  if char_length(trim(coalesce(p_reviewer, ''))) < 2 then
    raise exception 'A reviewer name is required';
  end if;
  if trim(coalesce(p_source_url, '')) !~ '^https?://' then
    raise exception 'A supporting source URL is required';
  end if;
  if jsonb_typeof(coalesce(p_facts, '{}'::jsonb)) <> 'object'
     or jsonb_typeof(coalesce(p_vibes, '{}'::jsonb)) <> 'object' then
    raise exception 'Review facts and vibes must be JSON objects';
  end if;
  if exists (
    select 1 from jsonb_object_keys(coalesce(p_facts, '{}'::jsonb)) requested(name)
     where requested.name <> all (v_allowed_facts)
  ) then
    raise exception 'One or more review facts are not supported';
  end if;
  if p_facts ? 'operating_hours' and jsonb_typeof(p_facts->'operating_hours') <> 'object' then
    raise exception 'Operating hours must be a JSON object';
  end if;
  if p_facts ? 'price_tier'
     and nullif(p_facts->>'price_tier', '') is not null
     and (p_facts->>'price_tier')::smallint not between 1 and 4 then
    raise exception 'Price tier must be between 1 and 4 or unknown';
  end if;

  select id, publication_status into v_venue_id, v_status
    from wheretayo.venues where slug = p_slug for update;
  if v_venue_id is null then raise exception 'Venue not found: %', p_slug; end if;
  if v_status not in ('review', 'draft') then raise exception 'Only review or draft venues can save facts'; end if;
  if exists (
    select 1 from jsonb_object_keys(coalesce(p_vibes, '{}'::jsonb)) requested(slug)
      left join wheretayo.vibes vibe on vibe.slug = requested.slug
     where vibe.id is null
  ) then
    raise exception 'One or more vibe slugs do not exist';
  end if;

  update wheretayo.venues
     set category = case when p_facts ? 'category' then p_facts->>'category' else category end,
         price_tier = case when p_facts ? 'price_tier' then nullif(p_facts->>'price_tier', '')::smallint else price_tier end,
         wifi_status = case when p_facts ? 'wifi_status' then p_facts->>'wifi_status' else wifi_status end,
         sockets_status = case when p_facts ? 'sockets_status' then p_facts->>'sockets_status' else sockets_status end,
         noise_level = case when p_facts ? 'noise_level' then p_facts->>'noise_level' else noise_level end,
         outdoor_status = case when p_facts ? 'outdoor_status' then p_facts->>'outdoor_status' else outdoor_status end,
         parking_status = case when p_facts ? 'parking_status' then p_facts->>'parking_status' else parking_status end,
         work_friendly_status = case when p_facts ? 'work_friendly_status' then p_facts->>'work_friendly_status' else work_friendly_status end,
         address = case when p_facts ? 'address' then p_facts->>'address' else address end,
         operating_hours = case when p_facts ? 'operating_hours' then p_facts->'operating_hours' else operating_hours end,
         updated_at = now()
   where id = v_venue_id;

  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, fact.key, fact.value, 'admin', 'verified', trim(p_source_url)
    from jsonb_each_text(coalesce(p_facts, '{}'::jsonb)) fact
   where fact.key <> 'operating_hours';
  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, 'operating_hours', (p_facts->'operating_hours')::text, 'admin', 'verified', trim(p_source_url)
   where p_facts ? 'operating_hours';

  insert into wheretayo.venue_vibes (venue_id, vibe_id, weight)
  select v_venue_id, vibe.id, requested.value::smallint
    from jsonb_each_text(coalesce(p_vibes, '{}'::jsonb)) requested
    join wheretayo.vibes vibe on vibe.slug = requested.key
  on conflict (venue_id, vibe_id) do update set weight = excluded.weight;
  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, 'vibe:' || requested.key, requested.value, 'admin', 'verified', trim(p_source_url)
    from jsonb_each_text(coalesce(p_vibes, '{}'::jsonb)) requested;

  insert into wheretayo.venue_review_events (venue_id, previous_status, new_status, reviewer, notes)
  values (v_venue_id, v_status, v_status, trim(p_reviewer), nullif(trim(coalesce(p_notes, '')), ''));
  return v_venue_id;
end;
$$;

revoke all on function wheretayo.save_review_facts(text, text, text, jsonb, jsonb, text) from public, anon, authenticated;
grant execute on function wheretayo.save_review_facts(text, text, text, jsonb, jsonb, text) to service_role;

-- Preserve the optional matcher while filtering to listings that meet the public category gate.
drop function if exists wheretayo.match_venues(smallint, text, text, text, uuid, integer);
create function wheretayo.match_venues(
  p_price_tier smallint,
  p_energy text,
  p_non_negotiable text,
  p_party text,
  p_neighborhood_id uuid default null,
  p_limit integer default 3
)
returns table (
  id uuid, slug text, name text, price_tier smallint, is_verified boolean,
  sockets_status text, noise_level text, work_friendly_status text,
  outdoor_status text, parking_status text, wifi_status text,
  cover_image_url text, match_score integer
)
language sql
stable
set search_path = wheretayo, extensions, public
as $$
  with scored as (
    select venue.id, venue.slug, venue.name, venue.price_tier, venue.is_verified,
      venue.sockets_status, venue.noise_level, venue.work_friendly_status,
      venue.outdoor_status, venue.parking_status, venue.wifi_status, venue.cover_image_url,
      least(99, 50
        + case when venue.is_verified then 10 else 0 end
        + case when venue.price_tier = p_price_tier then 20 when abs(venue.price_tier - p_price_tier) = 1 then 5 else 0 end
        + case
            when p_energy = 'work' then (case when venue.work_friendly_status = 'yes' then 12 else 0 end) + (case when venue.sockets_status = 'yes' then 6 else 0 end) + (case when venue.noise_level = 'quiet' then 5 else 0 end)
            when p_energy = 'slow' then (case when venue.noise_level = 'quiet' then 10 else 0 end) + (case when venue.outdoor_status = 'yes' then 5 else 0 end)
            when p_energy = 'night' then (case when venue.noise_level = 'lively' then 10 else 0 end) + (case when venue.price_tier >= 3 then 5 else 0 end)
            when p_energy = 'meetup' then case when venue.category in ('restaurant', 'cafe', 'quick_bite', 'bar', 'coffee_shop') then 10 else 0 end
            else 0
          end
        + case
            when p_non_negotiable = 'sockets' and venue.sockets_status = 'yes' then 15
            when p_non_negotiable = 'outdoor' and venue.outdoor_status = 'yes' then 15
            else 0
          end
        + coalesce(vibe.vibe_score, 0)
      )::integer as match_score
    from wheretayo.venues venue
    left join lateral (
      select coalesce(sum(case
        when p_energy = 'work' and vibe.slug = 'work-friendly' then venue_vibe.weight * 3
        when p_energy = 'slow' and vibe.slug = 'slow-afternoons' then venue_vibe.weight * 3
        when p_energy = 'night' and vibe.slug = 'late-night-buzz' then venue_vibe.weight * 3
        when p_non_negotiable = 'outdoor' and vibe.slug = 'outdoor-tables' then venue_vibe.weight * 3
        when p_party in ('pair', 'small') and vibe.slug = 'good-for-groups' then venue_vibe.weight * 3
        else 0
      end), 0)::integer as vibe_score
      from wheretayo.venue_vibes venue_vibe
      join wheretayo.vibes vibe on vibe.id = venue_vibe.vibe_id
      where venue_vibe.venue_id = venue.id
    ) vibe on true
    where venue.publication_status = 'published'
      and venue.category is not null
      and (p_neighborhood_id is null or venue.neighborhood_id = p_neighborhood_id)
  )
  select * from scored
   order by match_score desc, is_verified desc, name asc
   limit greatest(1, least(coalesce(p_limit, 3), 20));
$$;
revoke all on function wheretayo.match_venues(smallint, text, text, text, uuid, integer) from public;
grant execute on function wheretayo.match_venues(smallint, text, text, text, uuid, integer) to anon, authenticated, service_role;

-- Every public intake decision is performed atomically and leaves an audit record.
create or replace function wheretayo.review_claim_request(
  p_request_id uuid,
  p_reviewer text,
  p_status text,
  p_notes text default null
)
returns void
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_venue_id uuid;
  v_previous text;
begin
  if nullif(trim(p_reviewer), '') is null then raise exception 'Reviewer is required'; end if;
  if p_status not in ('reviewing', 'approved', 'denied', 'revoked') then raise exception 'Invalid claim status'; end if;
  select venue_id, status into v_venue_id, v_previous
    from wheretayo.venue_claim_requests where id = p_request_id for update;
  if v_venue_id is null then raise exception 'Claim request not found'; end if;
  if v_previous in ('denied', 'revoked') then raise exception 'This claim request is already closed'; end if;
  if v_previous = 'approved' and p_status <> 'revoked' then raise exception 'An approved claim can only be revoked'; end if;
  if p_status = 'revoked' and v_previous <> 'approved' then raise exception 'Only an approved claim can be revoked'; end if;
  if p_status = 'approved' and v_previous not in ('pending', 'reviewing') then raise exception 'Only a pending claim can be approved'; end if;

  update wheretayo.venue_claim_requests
     set status = p_status, reviewed_by = trim(p_reviewer), review_notes = nullif(trim(p_notes), ''),
         reviewed_at = now(), verified_at = case when p_status = 'approved' then now() when p_status = 'revoked' then null else verified_at end,
         updated_at = now()
   where id = p_request_id;
  if p_status in ('approved', 'revoked') then
    update wheretayo.venues set owner_claimed_at = case when p_status = 'approved' then now() else null end, updated_at = now() where id = v_venue_id;
  end if;
  insert into wheretayo.venue_claim_events (claim_request_id, previous_status, new_status, reviewer, notes)
  values (p_request_id, v_previous, p_status, trim(p_reviewer), nullif(trim(p_notes), ''));
end;
$$;
revoke all on function wheretayo.review_claim_request(uuid, text, text, text) from public, anon, authenticated;
grant execute on function wheretayo.review_claim_request(uuid, text, text, text) to service_role;

create or replace function wheretayo.review_venue_suggestion(
  p_suggestion_id uuid,
  p_reviewer text,
  p_status text,
  p_notes text default null,
  p_source_url text default null
)
returns void
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_suggestion wheretayo.venue_suggestions%rowtype;
  v_venue wheretayo.venues%rowtype;
  v_value text;
  v_next_status text;
  v_previous_values jsonb;
  v_new_values jsonb;
begin
  if nullif(trim(p_reviewer), '') is null then raise exception 'Reviewer is required'; end if;
  if p_status not in ('resolved', 'declined') then raise exception 'Invalid suggestion status'; end if;
  select * into v_suggestion from wheretayo.venue_suggestions where id = p_suggestion_id and status = 'pending' for update;
  if v_suggestion.id is null then raise exception 'Pending suggestion not found'; end if;
  select * into v_venue from wheretayo.venues where id = v_suggestion.venue_id for update;
  if v_venue.id is null then raise exception 'Venue not found'; end if;
  v_next_status := v_venue.publication_status;

  if p_status = 'resolved' and v_suggestion.suggestion_type in ('closure', 'correction', 'accuracy') then
    if trim(coalesce(p_source_url, '')) !~ '^https?://' then raise exception 'A source checked by the reviewer is required to resolve this report'; end if;
  end if;
  if p_status = 'resolved' and v_suggestion.suggestion_type = 'closure' then
    update wheretayo.venues set publication_status = 'archived', is_verified = false, last_verified_at = null, updated_at = now() where id = v_venue.id;
    insert into wheretayo.venue_field_change_events (venue_id, change_source, actor, previous_values, new_values, source_url, suggestion_id)
    values (v_venue.id, 'public_correction', trim(p_reviewer), jsonb_build_object('publication_status', v_venue.publication_status), jsonb_build_object('publication_status', 'archived'), trim(p_source_url), v_suggestion.id);
    v_next_status := 'archived';
  elsif p_status = 'resolved' and v_suggestion.suggestion_type = 'correction' then
    v_value := trim(coalesce(v_suggestion.suggested_value, ''));
    case v_suggestion.field_name
      when 'name' then if char_length(v_value) not between 1 and 160 then raise exception 'Name must be 1 to 160 characters'; end if;
      when 'category' then if v_value not in ('cafe', 'restaurant', 'quick_bite', 'bar', 'coffee_shop', 'bakery', 'shop', 'other') then raise exception 'Unsupported category'; end if;
      when 'address' then if char_length(v_value) not between 1 and 300 then raise exception 'Address must be 1 to 300 characters'; end if;
      when 'price_tier' then if v_value not in ('1', '2', '3', '4') then raise exception 'Price tier must be 1 to 4'; end if;
      when 'operating_hours' then if jsonb_typeof(v_value::jsonb) <> 'object' then raise exception 'Hours must be a JSON object'; end if;
      when 'wifi_status' then if v_value not in ('yes', 'no', 'unknown') then raise exception 'Unsupported Wi-Fi status'; end if;
      when 'sockets_status' then if v_value not in ('yes', 'no', 'unknown') then raise exception 'Unsupported socket status'; end if;
      when 'noise_level' then if v_value not in ('quiet', 'moderate', 'lively', 'unknown') then raise exception 'Unsupported noise level'; end if;
      when 'outdoor_status' then if v_value not in ('yes', 'no', 'unknown') then raise exception 'Unsupported outdoor status'; end if;
      when 'parking_status' then if v_value not in ('yes', 'no', 'unknown') then raise exception 'Unsupported parking status'; end if;
      when 'work_friendly_status' then if v_value not in ('yes', 'no', 'unknown') then raise exception 'Unsupported work-friendly status'; end if;
      when 'website_url' then if v_value !~ '^https?://' then raise exception 'Website must use an http or https URL'; end if;
      when 'phone' then if char_length(v_value) > 40 then raise exception 'Phone must be 40 characters or fewer'; end if;
      when 'short_description' then if char_length(v_value) > 280 then raise exception 'Short description must be 280 characters or fewer'; end if;
      else raise exception 'Unsupported correction field';
    end case;
    update wheretayo.venues venue set
      name = case when v_suggestion.field_name = 'name' then v_value else venue.name end,
      category = case when v_suggestion.field_name = 'category' then v_value else venue.category end,
      address = case when v_suggestion.field_name = 'address' then v_value else venue.address end,
      price_tier = case when v_suggestion.field_name = 'price_tier' then v_value::smallint else venue.price_tier end,
      operating_hours = case when v_suggestion.field_name = 'operating_hours' then v_value::jsonb else venue.operating_hours end,
      wifi_status = case when v_suggestion.field_name = 'wifi_status' then v_value else venue.wifi_status end,
      sockets_status = case when v_suggestion.field_name = 'sockets_status' then v_value else venue.sockets_status end,
      noise_level = case when v_suggestion.field_name = 'noise_level' then v_value else venue.noise_level end,
      outdoor_status = case when v_suggestion.field_name = 'outdoor_status' then v_value else venue.outdoor_status end,
      parking_status = case when v_suggestion.field_name = 'parking_status' then v_value else venue.parking_status end,
      work_friendly_status = case when v_suggestion.field_name = 'work_friendly_status' then v_value else venue.work_friendly_status end,
      website_url = case when v_suggestion.field_name = 'website_url' then v_value else venue.website_url end,
      phone = case when v_suggestion.field_name = 'phone' then v_value else venue.phone end,
      short_description = case when v_suggestion.field_name = 'short_description' then v_value else venue.short_description end,
      source_updated_at = now(), is_verified = false, last_verified_at = null, updated_at = now()
     where venue.id = v_venue.id;
    insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
    values (v_venue.id, v_suggestion.field_name, v_value, 'admin', 'verified', trim(p_source_url));
    v_previous_values := jsonb_build_object(v_suggestion.field_name, to_jsonb(v_venue)->v_suggestion.field_name);
    v_new_values := jsonb_build_object(v_suggestion.field_name, case when v_suggestion.field_name = 'operating_hours' then v_value::jsonb else to_jsonb(v_value) end);
    insert into wheretayo.venue_field_change_events (venue_id, change_source, actor, previous_values, new_values, source_url, suggestion_id)
    values (v_venue.id, 'public_correction', trim(p_reviewer), v_previous_values, v_new_values, trim(p_source_url), v_suggestion.id);
  elsif p_status = 'resolved' and v_suggestion.suggestion_type = 'accuracy' and v_suggestion.is_accurate then
    v_value := to_jsonb(v_venue)->>v_suggestion.field_name;
    insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
    values (v_venue.id, v_suggestion.field_name, coalesce(v_value, ''), 'admin', 'verified', trim(p_source_url));
  elsif p_status = 'resolved' and v_suggestion.suggestion_type = 'accuracy' and not v_suggestion.is_accurate then
    v_value := to_jsonb(v_venue)->>v_suggestion.field_name;
    update wheretayo.venues set is_verified = false, last_verified_at = null, updated_at = now() where id = v_venue.id;
    insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
    values (v_venue.id, v_suggestion.field_name, coalesce(v_value, ''), 'user_report', 'reported', trim(p_source_url));
  end if;

  update wheretayo.venue_suggestions
     set status = p_status, reviewer = trim(p_reviewer), review_notes = nullif(trim(p_notes), ''), reviewed_at = now()
   where id = p_suggestion_id and status = 'pending';
  if not found then raise exception 'Pending suggestion not found'; end if;
  if v_next_status <> v_venue.publication_status then
    insert into wheretayo.venue_review_events (venue_id, previous_status, new_status, reviewer, notes)
    values (v_venue.id, v_venue.publication_status, v_next_status, trim(p_reviewer), nullif(trim(p_notes), ''));
  end if;
end;
$$;
revoke all on function wheretayo.review_venue_suggestion(uuid, text, text, text, text) from public, anon, authenticated;
grant execute on function wheretayo.review_venue_suggestion(uuid, text, text, text, text) to service_role;

create or replace function wheretayo.review_venue_change_proposal(
  p_proposal_id uuid,
  p_reviewer text,
  p_approve boolean,
  p_notes text default null
)
returns void
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_proposal wheretayo.venue_change_proposals%rowtype;
  v_venue wheretayo.venues%rowtype;
  v_changes jsonb;
  v_change_status text;
  v_previous_values jsonb;
begin
  if nullif(trim(p_reviewer), '') is null then raise exception 'Reviewer is required'; end if;
  select * into v_proposal from wheretayo.venue_change_proposals where id = p_proposal_id for update;
  if v_proposal.id is null or v_proposal.status <> 'pending' then raise exception 'Pending update proposal not found'; end if;
  if p_approve and not exists (
    select 1 from wheretayo.venue_claim_requests claim
     where claim.id = v_proposal.claim_request_id and claim.venue_id = v_proposal.venue_id and claim.status = 'approved'
  ) then raise exception 'The related business claim is not currently approved'; end if;
  if p_approve and v_proposal.changes ? 'operating_hours' and jsonb_typeof(v_proposal.changes->'operating_hours') <> 'object' then
    raise exception 'Operating hours must be a JSON object';
  end if;
  if p_approve and v_proposal.changes ? 'category' and v_proposal.changes->>'category' not in ('cafe', 'restaurant', 'quick_bite', 'bar', 'coffee_shop', 'bakery', 'shop', 'other') then
    raise exception 'Unsupported category';
  end if;
  if p_approve and v_proposal.changes ? 'short_description' and char_length(v_proposal.changes->>'short_description') > 280 then
    raise exception 'Short description must be 280 characters or fewer';
  end if;
  if p_approve and v_proposal.changes ? 'website_url' and v_proposal.changes->>'website_url' !~ '^https?://' then
    raise exception 'Website must use an http or https URL';
  end if;
  if p_approve then
    if v_proposal.changes ? 'name' and char_length(trim(v_proposal.changes->>'name')) not between 1 and 160 then raise exception 'Name must be 1 to 160 characters'; end if;
    if v_proposal.changes ? 'address' and char_length(trim(v_proposal.changes->>'address')) not between 1 and 300 then raise exception 'Address must be 1 to 300 characters'; end if;
    if v_proposal.changes ? 'phone' and char_length(v_proposal.changes->>'phone') > 40 then raise exception 'Phone must be 40 characters or fewer'; end if;
    if v_proposal.changes ? 'price_tier' and (v_proposal.changes->>'price_tier') !~ '^[1-4]$' then raise exception 'Price tier must be 1 to 4'; end if;
    if v_proposal.changes ? 'wifi_status' and v_proposal.changes->>'wifi_status' not in ('yes', 'no', 'unknown') then raise exception 'Unsupported Wi-Fi status'; end if;
    if v_proposal.changes ? 'sockets_status' and v_proposal.changes->>'sockets_status' not in ('yes', 'no', 'unknown') then raise exception 'Unsupported socket status'; end if;
    if v_proposal.changes ? 'noise_level' and v_proposal.changes->>'noise_level' not in ('quiet', 'moderate', 'lively', 'unknown') then raise exception 'Unsupported noise level'; end if;
    if v_proposal.changes ? 'outdoor_status' and v_proposal.changes->>'outdoor_status' not in ('yes', 'no', 'unknown') then raise exception 'Unsupported outdoor status'; end if;
    if v_proposal.changes ? 'parking_status' and v_proposal.changes->>'parking_status' not in ('yes', 'no', 'unknown') then raise exception 'Unsupported parking status'; end if;
    if v_proposal.changes ? 'work_friendly_status' and v_proposal.changes->>'work_friendly_status' not in ('yes', 'no', 'unknown') then raise exception 'Unsupported work-friendly status'; end if;
  end if;

  v_change_status := case when p_approve then 'approved' else 'denied' end;
  if p_approve then
    v_changes := v_proposal.changes;
    select * into v_venue from wheretayo.venues where id = v_proposal.venue_id for update;
    select coalesce(jsonb_object_agg(changed.key, to_jsonb(v_venue)->changed.key), '{}'::jsonb)
      into v_previous_values from jsonb_object_keys(v_changes) changed(key);
    update wheretayo.venues venue set
      name = coalesce(v_changes->>'name', venue.name),
      category = coalesce(v_changes->>'category', venue.category),
      address = coalesce(v_changes->>'address', venue.address),
      price_tier = case when v_changes ? 'price_tier' then (v_changes->>'price_tier')::smallint else venue.price_tier end,
      operating_hours = case when v_changes ? 'operating_hours' then v_changes->'operating_hours' else venue.operating_hours end,
      wifi_status = coalesce(v_changes->>'wifi_status', venue.wifi_status),
      sockets_status = coalesce(v_changes->>'sockets_status', venue.sockets_status),
      noise_level = coalesce(v_changes->>'noise_level', venue.noise_level),
      outdoor_status = coalesce(v_changes->>'outdoor_status', venue.outdoor_status),
      parking_status = coalesce(v_changes->>'parking_status', venue.parking_status),
      work_friendly_status = coalesce(v_changes->>'work_friendly_status', venue.work_friendly_status),
      website_url = case when v_changes ? 'website_url' then nullif(v_changes->>'website_url', '') else venue.website_url end,
      phone = case when v_changes ? 'phone' then nullif(v_changes->>'phone', '') else venue.phone end,
      short_description = case when v_changes ? 'short_description' then nullif(v_changes->>'short_description', '') else venue.short_description end,
      is_verified = false,
      last_verified_at = null,
      updated_at = now()
     where venue.id = v_proposal.venue_id;
    insert into wheretayo.venue_field_change_events (venue_id, change_source, actor, previous_values, new_values, proposal_id)
    values (v_proposal.venue_id, 'owner_proposal', trim(p_reviewer), v_previous_values, v_changes, v_proposal.id);
    insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence)
    select v_proposal.venue_id, changed.key, changed.value, 'user_report', 'reported'
      from jsonb_each_text(v_changes) changed
     where changed.key <> 'operating_hours';
    insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence)
    select v_proposal.venue_id, 'operating_hours', (v_changes->'operating_hours')::text, 'user_report', 'reported'
     where v_changes ? 'operating_hours';
    insert into wheretayo.venue_review_events (venue_id, previous_status, new_status, reviewer, notes)
    values (v_proposal.venue_id, 'published', 'published', trim(p_reviewer), 'Approved owner-submitted update: ' || coalesce(nullif(trim(p_notes), ''), 'see proposal ' || p_proposal_id::text));
  end if;
  update wheretayo.venue_change_proposals
     set status = v_change_status, reviewed_by = trim(p_reviewer), review_notes = nullif(trim(p_notes), ''), reviewed_at = now()
   where id = p_proposal_id;
end;
$$;
revoke all on function wheretayo.review_venue_change_proposal(uuid, text, boolean, text) from public, anon, authenticated;
grant execute on function wheretayo.review_venue_change_proposal(uuid, text, boolean, text) to service_role;

create or replace function wheretayo.purge_expired_public_intake_pii()
returns jsonb
language plpgsql
volatile
set search_path = wheretayo, extensions, public
as $$
declare
  v_suggestions integer;
  v_claims integer;
  v_proposals integer;
  v_messages integer;
begin
  update wheretayo.venue_suggestions set contact_email = null, details = null
   where status in ('resolved', 'declined') and reviewed_at < now() - interval '180 days'
     and (contact_email is not null or details is not null);
  get diagnostics v_suggestions = row_count;

  update wheretayo.venue_claim_requests set claimant_name = 'Former claimant', contact_email = null,
    contact_phone = null, notes = null, review_notes = null
   where status in ('denied', 'revoked') and reviewed_at < now() - interval '180 days'
     and (claimant_name <> 'Former claimant' or contact_email is not null or contact_phone is not null or notes is not null or review_notes is not null);
  get diagnostics v_claims = row_count;
  update wheretayo.venue_claim_events event set notes = null
   from wheretayo.venue_claim_requests claim
   where event.claim_request_id = claim.id and claim.status in ('denied', 'revoked')
     and claim.reviewed_at < now() - interval '180 days' and event.notes is not null;

  update wheretayo.venue_change_proposals set notes = null, review_notes = null
   where status in ('approved', 'denied') and reviewed_at < now() - interval '180 days'
     and (notes is not null or review_notes is not null);
  get diagnostics v_proposals = row_count;

  update wheretayo.venue_contact_messages set contact_name = null, contact_email = null, message = '[Personal data removed after retention period.]', review_notes = null
   where status in ('resolved', 'declined') and reviewed_at < now() - interval '180 days'
     and (contact_name is not null or contact_email is not null or message <> '[Personal data removed after retention period.]' or review_notes is not null);
  get diagnostics v_messages = row_count;

  return jsonb_build_object('suggestions', v_suggestions, 'claims', v_claims, 'proposals', v_proposals, 'messages', v_messages);
end;
$$;
revoke all on function wheretayo.purge_expired_public_intake_pii() from public, anon, authenticated;
grant execute on function wheretayo.purge_expired_public_intake_pii() to service_role;

-- Claim and correction contact details should be reviewed and removed after the pilot's 180-day retention window.
comment on column wheretayo.venue_claim_requests.contact_email is 'Private verification contact. Remove or anonymize 180 days after a request is closed unless active dispute retention is needed.';
comment on column wheretayo.venue_suggestions.contact_email is 'Optional private follow-up contact. Remove 180 days after resolution.';
