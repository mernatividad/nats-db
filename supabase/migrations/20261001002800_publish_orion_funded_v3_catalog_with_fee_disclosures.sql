begin;

-- Current V3 programs remain the visible product set. Generic legacy checkout
-- prices are not copied into these records; current unresolved fee and entity
-- details remain described in the individual public program disclosures.
update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'orion-funded'
  and p.market_type = 'forex'
  and p.slug in ('orion-zero', 'orion-nova', 'orion-standard', 'orion-swing', 'orion-select')
  and p.status = 'in_review';

update bullish_banana.firms
set status = 'published',
    published_at = coalesce(published_at, now()),
    archived_at = null,
    updated_at = now()
where slug = 'orion-funded' and status = 'in_review';

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, null, 'official_site', 'Visit Orion Funded official site', 'https://www.orionfunded.com/', true, 'active'
from bullish_banana.firms f
where f.slug = 'orion-funded'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.status = 'active'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:14:00Z'::timestamptz,
  'Current official V3 homepage and Help Center program overview/comparison rechecked 2026-09-30; the five current V3 program families remain visible. The linked generic checkout still uses unmatched legacy labels and is not treated as V3 fee evidence. Current V3 fee availability, homepage-footer versus GTC provider identity, and order-specific contracting entity remain explicitly disclosed as unresolved.'
from bullish_banana.firms f
where f.slug = 'orion-funded'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T13:14:00Z'::timestamptz);

commit;
