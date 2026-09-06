do $$
declare
  target record;
  venue_id uuid;
  media_id uuid;
begin
  for target in
    select * from (values
      (
        'brothers-burger-9th-avenue'::text,
        'https://www.pexels.com/photo/burger-served-in-a-restaurant-18867543/'::text,
        'https://images.pexels.com/photos/18867543/pexels-photo-18867543.jpeg'::text,
        'Marstudio Media'::text,
        'Burger photo by Marstudio Media via Pexels'::text,
        'Pexels marks this photo Free to use under the Pexels License. Representative burger image; not photographed at this venue.'::text
      ),
      (
        'mini-shabu-shabu'::text,
        'https://www.pexels.com/photo/delicious-hot-pot-ingredients-arrangement-28439716/'::text,
        'https://images.pexels.com/photos/28439716/pexels-photo-28439716.jpeg'::text,
        'Thien Binh'::text,
        'Hot-pot photo by Thien Binh via Pexels'::text,
        'Pexels marks this photo Free to use under the Pexels License. Representative hot-pot image; not photographed at this venue.'::text
      )
    ) as media(slug, source_page_url, media_url, photographer_or_owner, attribution_text, rights_note)
  loop
    if not exists (
      select 1 from wheretayo.venue_media m
      join wheretayo.venues v on v.id = m.venue_id
      where v.slug = target.slug and m.source_page_url = target.source_page_url
    ) then
      venue_id := null;
      select v.id into venue_id
      from wheretayo.venues v
      where v.slug = target.slug;

      if venue_id is not null then
        insert into wheretayo.venue_media (
          venue_id, provider, source_page_url, media_url, rights_status,
          rights_note, license_url, photographer_or_owner, attribution_text
        ) values (
          venue_id, 'pexels', target.source_page_url, target.media_url,
          'licensed', target.rights_note, 'https://www.pexels.com/license/',
          target.photographer_or_owner, target.attribution_text
        ) returning id into media_id;

        perform wheretayo.set_selected_venue_media(venue_id, media_id);
      end if;
    end if;
  end loop;
end;
$$;
