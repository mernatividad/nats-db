-- Public taxonomy for the first WhereTayo discovery pages.
insert into wheretayo.vibes (name, slug, category)
values
  ('Work-friendly', 'work-friendly', 'amenity'),
  ('Slow afternoons', 'slow-afternoons', 'mood'),
  ('Late-night buzz', 'late-night-buzz', 'mood'),
  ('Outdoor tables', 'outdoor-tables', 'amenity'),
  ('Good for groups', 'good-for-groups', 'crowd')
on conflict (slug) do update set name = excluded.name, category = excluded.category;
