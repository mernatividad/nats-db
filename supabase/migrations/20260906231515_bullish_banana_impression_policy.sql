-- Keep the impression insert policy aligned with the published destination resolver.
set search_path = bullish_banana, extensions, public;

drop policy if exists "valid published CTA impressions are insertable"
  on bullish_banana.affiliate_impressions;

create policy "valid published CTA impressions are insertable"
  on bullish_banana.affiliate_impressions for insert to anon, authenticated
  with check (
    (
      program_id is null
      and firm_id is not null
      and exists (
        select 1
        from bullish_banana.firms f
        where f.id = affiliate_impressions.firm_id
          and f.status = 'published'
      )
    )
    or (
      program_id is not null
      and firm_id is not null
      and exists (
        select 1
        from bullish_banana.programs p
        join bullish_banana.firms f on f.id = p.firm_id
        where p.id = affiliate_impressions.program_id
          and p.firm_id = affiliate_impressions.firm_id
          and p.status = 'published'
          and f.status = 'published'
      )
    )
  );

notify pgrst, 'reload config';
