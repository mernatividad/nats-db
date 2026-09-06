do $$
declare
  target record;
  venue_id uuid;
  media_id uuid;
begin
  for target in
    select * from (values
      ('cupcakes-by-sonja'::text, 'https://www.pexels.com/photo/cupcakes-1055272/'::text, 'https://images.pexels.com/photos/1055272/pexels-photo-1055272.jpeg'::text, 'Pexels contributor'::text, 'Cupcake photo via Pexels'::text),
      ('jones-all-day', 'https://www.pexels.com/photo/rows-of-chairs-at-tables-on-a-cafe-patio-in-philippines-24554396/', '/images/wheretayo-hero.jpeg', 'Enil yugto', 'Cafe patio photo by Enil yugto via Pexels'),
      ('melo-s', 'https://www.pexels.com/photo/steak-769289/'::text, 'https://images.pexels.com/photos/769289/pexels-photo-769289.jpeg'::text, 'Pexels contributor'::text, 'Steak photo via Pexels'::text),
      ('north-park', 'https://www.pexels.com/photo/delicious-hot-pot-ingredients-arrangement-28439716/', 'https://images.pexels.com/photos/28439716/pexels-photo-28439716.jpeg', 'Thien Binh', 'Hot-pot photo by Thien Binh via Pexels'),
      ('pizza-hut-32nd-street', 'https://www.pexels.com/photo/pizza-825661/'::text, 'https://images.pexels.com/photos/825661/pexels-photo-825661.jpeg'::text, 'Pexels contributor'::text, 'Pizza photo via Pexels'::text),
      ('pound-by-todd-english', 'https://www.pexels.com/photo/burger-served-in-a-restaurant-18867543/', 'https://images.pexels.com/photos/18867543/pexels-photo-18867543.jpeg', 'Marstudio Media', 'Burger photo by Marstudio Media via Pexels'),
      ('saladstop', 'https://www.pexels.com/photo/delicious-salad-in-plate-on-table-5710204/'::text, 'https://images.pexels.com/photos/5710204/pexels-photo-5710204.jpeg'::text, 'Sam Lion'::text, 'Salad photo by Sam Lion via Pexels'::text),
      ('st-marc-cafe-7th-avenue', 'https://www.pexels.com/photo/rows-of-chairs-at-tables-on-a-cafe-patio-in-philippines-24554396/', '/images/wheretayo-hero.jpeg', 'Enil yugto', 'Cafe patio photo by Enil yugto via Pexels'),
      ('starbucks-7th-avenue', 'https://www.pexels.com/photo/rows-of-chairs-at-tables-on-a-cafe-patio-in-philippines-24554396/', '/images/wheretayo-hero.jpeg', 'Enil yugto', 'Cafe patio photo by Enil yugto via Pexels'),
      ('the-coffee-bean', 'https://www.pexels.com/photo/rows-of-chairs-at-tables-on-a-cafe-patio-in-philippines-24554396/', '/images/wheretayo-hero.jpeg', 'Enil yugto', 'Cafe patio photo by Enil yugto via Pexels'),
      ('the-empress-dining-palace', 'https://www.pexels.com/photo/delicious-hot-pot-ingredients-arrangement-28439716/', 'https://images.pexels.com/photos/28439716/pexels-photo-28439716.jpeg', 'Thien Binh', 'Hot-pot photo by Thien Binh via Pexels'),
      ('ucc-coffee-park-cafe', 'https://www.pexels.com/photo/rows-of-chairs-at-tables-on-a-cafe-patio-in-philippines-24554396/', '/images/wheretayo-hero.jpeg', 'Enil yugto', 'Cafe patio photo by Enil yugto via Pexels'),
      ('zhu', 'https://www.pexels.com/photo/delicious-hot-pot-ingredients-arrangement-28439716/', 'https://images.pexels.com/photos/28439716/pexels-photo-28439716.jpeg', 'Thien Binh', 'Hot-pot photo by Thien Binh via Pexels')
    ) as media(slug, source_page_url, media_url, photographer_or_owner, attribution_text)
  loop
    if not exists (
      select 1 from wheretayo.venue_media m
      join wheretayo.venues v on v.id = m.venue_id
      where v.slug = target.slug and m.source_page_url = target.source_page_url
    ) then
      venue_id := null;
      select v.id into venue_id from wheretayo.venues v where v.slug = target.slug and v.publication_status = 'published';
      if venue_id is not null then
        insert into wheretayo.venue_media (
          venue_id, provider, source_page_url, media_url, rights_status,
          rights_note, license_url, photographer_or_owner, attribution_text
        ) values (
          venue_id, 'pexels', target.source_page_url, target.media_url, 'licensed',
          'Pexels marks this photo Free to use under the Pexels License. Representative image; not photographed at this venue.',
          'https://www.pexels.com/license/', target.photographer_or_owner, target.attribution_text
        ) returning id into media_id;
        perform wheretayo.set_selected_venue_media(venue_id, media_id);
      end if;
    end if;
  end loop;
end;
$$;
