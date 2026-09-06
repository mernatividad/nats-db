-- Public catalog reads are limited to published records. Better Auth users are
-- not represented by Supabase JWT subjects, so user/admin mutations continue
-- through the server-side service-role repositories.

create policy "published firms are publicly readable"
  on bullish_banana.firms for select to anon, authenticated
  using (status = 'published');

create policy "published programs are publicly readable"
  on bullish_banana.programs for select to anon, authenticated
  using (status = 'published');

create policy "published program phases are publicly readable"
  on bullish_banana.program_phases for select to anon, authenticated
  using (exists (
    select 1 from bullish_banana.programs p
    where p.id = program_id and p.status = 'published'
  ));

create policy "platforms are publicly readable"
  on bullish_banana.platforms for select to anon, authenticated
  using (true);

create policy "published program platform links are publicly readable"
  on bullish_banana.program_platforms for select to anon, authenticated
  using (exists (
    select 1 from bullish_banana.programs p
    where p.id = program_id and p.status = 'published'
  ));

create policy "published firm restrictions are publicly readable"
  on bullish_banana.restrictions for select to anon, authenticated
  using (exists (
    select 1 from bullish_banana.firms f
    where f.id = firm_id and f.status = 'published'
  ));

create policy "published source evidence is publicly readable"
  on bullish_banana.sources for select to anon, authenticated
  using (
    (firm_id is not null and exists (
      select 1 from bullish_banana.firms f
      where f.id = sources.firm_id and f.status = 'published'
    ))
    or (program_id is not null and exists (
      select 1 from bullish_banana.programs p
      where p.id = sources.program_id and p.status = 'published'
    ))
  );

create policy "published verifications are publicly readable"
  on bullish_banana.data_verifications for select to anon, authenticated
  using (
    (firm_id is not null and exists (
      select 1 from bullish_banana.firms f
      where f.id = data_verifications.firm_id and f.status = 'published'
    ))
    or (program_id is not null and exists (
      select 1 from bullish_banana.programs p
      where p.id = data_verifications.program_id and p.status = 'published'
    ))
  );

create policy "active published destinations are publicly readable"
  on bullish_banana.affiliate_destinations for select to anon, authenticated
  using (
    status = 'active'
    and exists (
      select 1 from bullish_banana.firms f
      where f.id = affiliate_destinations.firm_id and f.status = 'published'
    )
    and (program_id is null or exists (
      select 1 from bullish_banana.programs p
      where p.id = affiliate_destinations.program_id
        and p.firm_id = affiliate_destinations.firm_id
        and p.status = 'published'
    ))
  );

create policy "published reviews are publicly readable"
  on bullish_banana.reviews for select to anon, authenticated
  using (
    status = 'published'
    and exists (
      select 1 from bullish_banana.firms f
      where f.id = reviews.firm_id and f.status = 'published'
    )
    and (program_id is null or exists (
      select 1 from bullish_banana.programs p
      where p.id = reviews.program_id
        and p.firm_id = reviews.firm_id
        and p.status = 'published'
    ))
  );

create policy "valid affiliate clicks are insertable"
  on bullish_banana.affiliate_clicks for insert to anon, authenticated
  with check (
    destination_id is null or exists (
      select 1 from bullish_banana.affiliate_destinations d
      where d.id = affiliate_clicks.destination_id and d.status = 'active'
    )
  );

create policy "reports may target published catalog records"
  on bullish_banana.data_reports for insert to anon, authenticated
  with check (
    reporter_id is null
    and (
      (firm_id is not null and exists (
        select 1 from bullish_banana.firms f
        where f.id = data_reports.firm_id and f.status = 'published'
      ))
      or (program_id is not null and exists (
        select 1 from bullish_banana.programs p
        where p.id = data_reports.program_id and p.status = 'published'
      ))
    )
  );
