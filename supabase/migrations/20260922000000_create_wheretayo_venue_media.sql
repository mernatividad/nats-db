create table wheretayo.venue_media (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  provider text not null,
  source_page_url text not null,
  media_url text not null,
  rights_status text not null check (rights_status in ('licensed', 'permission_granted', 'venue_owned_reuse_allowed', 'research_only')),
  rights_note text,
  license_url text,
  photographer_or_owner text,
  attribution_text text,
  observed_at timestamptz not null default now(),
  selected boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (selected = false or rights_status <> 'research_only'),
  check (selected = false or length(trim(rights_note)) > 0),
  check (selected = false or length(trim(attribution_text)) > 0)
);

create unique index venue_media_one_selected_per_venue_idx
  on wheretayo.venue_media (venue_id)
  where selected;

create index venue_media_venue_selected_idx
  on wheretayo.venue_media (venue_id, selected);

create index venue_media_rights_status_idx
  on wheretayo.venue_media (rights_status);

alter table wheretayo.venue_media enable row level security;

create policy "approved selected venue media are readable"
  on wheretayo.venue_media for select to anon, authenticated
  using (
    selected = true
    and rights_status in ('licensed', 'permission_granted', 'venue_owned_reuse_allowed')
    and exists (
      select 1
      from wheretayo.venues v
      where v.id = venue_media.venue_id
        and v.publication_status = 'published'
    )
  );

revoke all on wheretayo.venue_media from public;
grant select on wheretayo.venue_media to anon, authenticated;
revoke insert, update, delete on wheretayo.venue_media from anon, authenticated;
grant all on wheretayo.venue_media to service_role;

create or replace function wheretayo.set_selected_venue_media(
  p_venue_id uuid,
  p_media_id uuid
)
returns wheretayo.venue_media
language plpgsql
security definer
set search_path = wheretayo, public
as $$
declare
  selected_media wheretayo.venue_media;
begin
  select * into selected_media
  from wheretayo.venue_media
  where id = p_media_id and venue_id = p_venue_id;

  if not found then
    raise exception 'Media does not belong to venue';
  end if;

  if selected_media.rights_status = 'research_only' then
    raise exception 'Research-only media cannot be selected';
  end if;

  if nullif(trim(selected_media.rights_note), '') is null
     or nullif(trim(selected_media.attribution_text), '') is null then
    raise exception 'Selected media requires rights note and attribution';
  end if;

  update wheretayo.venue_media
  set selected = false, updated_at = now()
  where venue_id = p_venue_id and selected;

  update wheretayo.venue_media
  set selected = true, updated_at = now()
  where id = p_media_id;

  update wheretayo.venues
  set cover_image_url = selected_media.media_url,
      source_updated_at = now(),
      updated_at = now()
  where id = p_venue_id;

  selected_media.selected := true;
  return selected_media;
end;
$$;

revoke all on function wheretayo.set_selected_venue_media(uuid, uuid) from public;
grant execute on function wheretayo.set_selected_venue_media(uuid, uuid) to authenticated, service_role;
