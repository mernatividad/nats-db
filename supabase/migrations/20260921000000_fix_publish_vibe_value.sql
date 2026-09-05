-- Correct the vibe weight field returned by jsonb_each_text.
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
  v_expected_facts constant text[] := array[
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
  if p_facts is null or not (p_facts ?& v_expected_facts) then
    raise exception 'All practical venue facts are required before publishing';
  end if;
  if jsonb_typeof(p_facts->'operating_hours') <> 'object' then
    raise exception 'Operating hours must be a JSON object';
  end if;
  if jsonb_typeof(coalesce(p_vibes, '{}'::jsonb)) <> 'object'
     or (select count(*) from jsonb_object_keys(coalesce(p_vibes, '{}'::jsonb))) = 0 then
    raise exception 'At least one vibe assignment is required';
  end if;

  select id, publication_status
    into v_venue_id, v_status
    from wheretayo.venues
   where slug = p_slug
   for update;

  if v_venue_id is null then
    raise exception 'Venue not found: %', p_slug;
  end if;
  if v_status <> 'review' then
    raise exception 'Only review venues can be published';
  end if;

  if exists (
    select 1
      from jsonb_object_keys(p_vibes) requested(slug)
      left join wheretayo.vibes v on v.slug = requested.slug
     where v.id is null
  ) then
    raise exception 'One or more vibe slugs do not exist';
  end if;

  update wheretayo.venues
     set price_tier = (p_facts->>'price_tier')::smallint,
         wifi_status = p_facts->>'wifi_status',
         sockets_status = p_facts->>'sockets_status',
         noise_level = p_facts->>'noise_level',
         outdoor_status = p_facts->>'outdoor_status',
         parking_status = p_facts->>'parking_status',
         work_friendly_status = p_facts->>'work_friendly_status',
         address = p_facts->>'address',
         operating_hours = p_facts->'operating_hours',
         publication_status = 'published',
         is_verified = true,
         last_verified_at = now(),
         updated_at = now()
   where id = v_venue_id;

  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, fact.key, fact.value, 'admin', 'verified', trim(p_source_url)
    from jsonb_each_text(p_facts) fact;

  insert into wheretayo.venue_vibes (venue_id, vibe_id, weight)
  select v_venue_id, v.id, (requested.value)::smallint
    from jsonb_each_text(p_vibes) requested
    join wheretayo.vibes v on v.slug = requested.key
  on conflict (venue_id, vibe_id) do update set weight = excluded.weight;

  insert into wheretayo.venue_attribute_evidence (venue_id, attribute_name, attribute_value, evidence_type, confidence, source_url)
  select v_venue_id, 'vibe:' || requested.key, requested.value, 'admin', 'verified', trim(p_source_url)
    from jsonb_each_text(p_vibes) requested;

  insert into wheretayo.venue_review_events (venue_id, previous_status, new_status, reviewer, notes)
  values (v_venue_id, 'review', 'published', trim(p_reviewer), nullif(trim(p_notes), ''));

  return v_venue_id;
end;
$$;

revoke all on function wheretayo.publish_venue(text, text, text, text, jsonb, jsonb) from public, anon, authenticated;
grant execute on function wheretayo.publish_venue(text, text, text, text, jsonb, jsonb) to service_role;
