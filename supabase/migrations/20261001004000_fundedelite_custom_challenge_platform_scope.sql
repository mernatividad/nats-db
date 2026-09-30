begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'platforms_note', 'FundedElite publicly lists MetaTrader 5 and Match-Trader at firm level; its Lite-2 FAQ instead lists MetaTrader 5 and TradeLocker. The Custom Challenge builder has no fixed account configuration on the reviewed public page, so a platform for this custom offer is not stated. Confirm the selected platform in the builder.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fundedelite' and p.slug = 'custom-challenge';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://fundedelite.com/challenges',
  'FundedElite Custom Challenge builder and platform scope — 2026-09-30',
  'Current official page advertises a configurable challenge builder but publishes no fixed configuration or platform for it. Firm-level platform choices and the Lite-2-specific platform list are disclosed separately; no custom offer platform is inferred.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite' and p.slug = 'custom-challenge'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_label = 'FundedElite Custom Challenge builder and platform scope — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T14:35:00Z'::timestamptz,
  'Current FundedElite challenges page rechecked. Custom Challenge is advertised as configurable but no platform or fixed account terms are listed. The platform remains configuration-dependent/unstated.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite' and p.slug = 'custom-challenge'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T14:35:00Z'::timestamptz);

commit;
