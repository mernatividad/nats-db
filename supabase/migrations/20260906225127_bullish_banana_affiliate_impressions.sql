-- Privacy-preserving CTA impressions for affiliate funnel CTR reporting.
set search_path = bullish_banana, extensions, public;

create table bullish_banana.affiliate_impressions (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid references bullish_banana.firms(id) on delete set null,
  program_id uuid references bullish_banana.programs(id) on delete set null,
  page_path text not null,
  placement text not null,
  destination_kind text not null check (destination_kind in ('affiliate', 'official_site')),
  created_at timestamptz not null default now(),
  check (firm_id is not null or program_id is not null)
);

create index affiliate_impressions_firm_time_idx on bullish_banana.affiliate_impressions (firm_id, created_at desc);
create index affiliate_impressions_program_time_idx on bullish_banana.affiliate_impressions (program_id, created_at desc);
create index affiliate_impressions_page_time_idx on bullish_banana.affiliate_impressions (page_path, created_at desc);

alter table bullish_banana.affiliate_impressions enable row level security;
revoke all on bullish_banana.affiliate_impressions from anon, authenticated;
grant insert on bullish_banana.affiliate_impressions to anon, authenticated;
grant all on bullish_banana.affiliate_impressions to service_role;

create policy "valid published CTA impressions are insertable"
  on bullish_banana.affiliate_impressions for insert to anon, authenticated
  with check (
    (firm_id is not null and exists (
      select 1 from bullish_banana.firms f
      where f.id = affiliate_impressions.firm_id and f.status = 'published'
    ))
    or (program_id is not null and exists (
      select 1 from bullish_banana.programs p
      join bullish_banana.firms f on f.id = p.firm_id
      where p.id = affiliate_impressions.program_id
        and p.status = 'published'
        and f.status = 'published'
    ))
  );

notify pgrst, 'reload config';
