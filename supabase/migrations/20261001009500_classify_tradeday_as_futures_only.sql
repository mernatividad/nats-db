begin;
set search_path = bullish_banana, extensions, public;

-- TradeDay's current official site and Terms state that its offers are futures
-- only and expressly exclude Forex. Preserve the firm as a futures candidate,
-- but remove its misclassified Forex offers from the Forex MVP surfaces.
update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_status', 'not a Forex offer; firm is futures-only',
      'archived_reason', 'Current official TradeDay Terms and homepage say only listed futures products are permitted and that Forex trading is not permitted or available. This row is archived from the Forex catalog; firm classification is retained as futures.',
      'archived_reviewed_at', '2026-10-01',
      'current_firm_market', 'futures'
    )
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'tradeday'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.firms f
where d.firm_id = f.id and f.slug = 'tradeday';

update bullish_banana.firms f
set market_type = 'futures', updated_at = now(),
    description = 'Futures evaluation provider; official terms permit listed exchange-traded futures only and exclude Forex.'
where f.slug = 'tradeday' and f.status in ('published', 'in_review');

delete from bullish_banana.firm_markets fm
using bullish_banana.firms f
where fm.firm_id = f.id and f.slug = 'tradeday' and fm.market_type = 'forex';

insert into bullish_banana.firm_markets (firm_id, market_type)
select f.id, 'futures' from bullish_banana.firms f
where f.slug = 'tradeday'
  and not exists (select 1 from bullish_banana.firm_markets fm where fm.firm_id=f.id and fm.market_type='futures');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://www.tradeday.com/terms-and-conditions',
  'TradeDay current product-market restrictions — 2026-10-01',
  'Current official Terms (last modified 2026-08-11) limit permitted products to CME Exchange Group futures. The official site states Forex and CFDs are not permitted or available in its program/platforms. TradeDay is retained as a futures firm candidate and removed from the Forex MVP.'
from bullish_banana.firms f
where f.slug = 'tradeday'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_label='TradeDay current product-market restrictions — 2026-10-01');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked current official TradeDay Terms and homepage: permitted instruments are listed futures only; Forex is explicitly unavailable. Archived both Forex-marked program rows, removed the Forex market membership, retained the firm with futures classification, and deactivated its Forex destinations.'
from bullish_banana.firms f
where f.slug = 'tradeday'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id=f.id and v.verified_at='2026-10-01T00:00:00Z'::timestamptz and v.notes like 'Rechecked current official TradeDay Terms and homepage:%');

commit;
