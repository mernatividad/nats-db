-- Save source-backed review progress without publishing a venue.
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
    'price_tier', 'wifi_status', 'sockets_status', 'noise_level',
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
  if jsonb_typeof(coalesce(p_facts, '{}'::jsonb)) <> 'object' then
    raise exception 'Review facts must be a JSON object';
  end if;
  if jsonb_typeof(coalesce(p_vibes, '{}'::jsonb)) <> 'object' then
    raise exception 'Vibe assignments must be a JSON object';
  end if;
  if exists (
    select 1
      from jsonb_object_keys(coalesce(p_facts, '{}'::jsonb)) requested(name)
     where requested.name <> all (v_allowed_facts)
  ) then
    raise exception 'One or more review facts are not supported';
  end if;
  if p_facts ? 'operating_hours' and jsonb_typeof(p_facts->'operating_hours') <> 'object' then
    raise exception 'Operating hours must be a JSON object';
  end if;

  select id, publication_status
    into v_venue_id, v_status
    from wheretayo.venues
   where slug = p_slug
   for update;

  if v_venue_id is null then
    raise exception 'Venue not found: %', p_slug;
  end if;
  if v_status not in ('review', 'draft') then
    raise exception 'Only review or draft venues can save facts';
  end if;
  if exists (
    select 1
      from jsonb_object_keys(coalesce(p_vibes, '{}'::jsonb)) requested(slug)
      left join wheretayo.vibes v on v.slug = requested.slug
     where v.id is null
  ) then
    raise exception 'One or more vibe slugs do not exist';
  end if;

  update wheretayo.venues
     set price_tier = case when p_facts ? 'price_tier' then (p_facts->>'price_tier')::smallint else price_tier end,
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
    from jsonb_each_text(coalesce(p_facts, '{}'::jsonb)) fact;

  insert into wheretayo.venue_vibes (venue_id, vibe_id, weight)
  select v_venue_id, v.id, (requested.value)::smallint
    from jsonb_each_text(coalesce(p_vibes, '{}'::jsonb)) requested
    join wheretayo.vibes v on v.slug = requested.key
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
