-- Atomically add OSM candidates and their provenance rows to the review queue.
-- The importer never promotes records beyond publication_status=review.
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
      record.longitude
    from jsonb_to_recordset(p_records) as record(
      source_record_id text,
      source_type text,
      source_url text,
      raw_payload jsonb,
      name text,
      slug text,
      address text,
      latitude double precision,
      longitude double precision
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
      select 1
      from wheretayo.venue_sources source
      where source.provider = 'openstreetmap'
        and source.provider_record_id = records.source_record_id
    )
  ),
  inserted as (
    insert into wheretayo.venues (
      neighborhood_id, name, slug, address, latitude, longitude,
      price_tier, publication_status, is_verified
    )
    select
      p_neighborhood_id,
      fresh.name,
      fresh.slug,
      coalesce(nullif(trim(fresh.address), ''), 'Address needs checking'),
      fresh.latitude,
      fresh.longitude,
      2,
      'review',
      false
    from fresh
    on conflict (slug) do nothing
    returning id, slug
  )
  insert into wheretayo.venue_sources (
    venue_id, provider, provider_record_id, source_url, raw_payload
  )
  select
    inserted.id,
    'openstreetmap',
    fresh.source_record_id,
    fresh.source_url,
    coalesce(fresh.raw_payload, '{}'::jsonb)
  from fresh
  join inserted on inserted.slug = fresh.slug
  on conflict (provider, provider_record_id) do nothing;

  get diagnostics v_imported = row_count;
  return v_imported;
end;
$$;

revoke all on function wheretayo.import_review_venues(uuid, jsonb) from public, anon, authenticated;
grant execute on function wheretayo.import_review_venues(uuid, jsonb) to service_role;
