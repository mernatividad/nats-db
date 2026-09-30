begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_price_note', 'The official Terms list a $1,000 Student 2-Phase Evaluation but do not publish its fee. No price is inferred for that size. Current official Terms list base fees for the $5,000, $10,000, $25,000, $50,000, $100,000, and $200,000 sizes; applicable taxes and payment-processor currency conversion may affect checkout totals.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'crypto-fund-trader'
  and p.slug = '2-phase-evaluation' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://cryptofundtrader.com/terms-and-conditions/',
  'Crypto Fund Trader 2-Phase base fees and $1K price disclosure — 2026-10-01',
  'Current official Terms §5.6.1 list two-phase evaluation fees for $5K, $10K, $25K, $50K, $100K, and $200K. The Terms list a $1K Student 2-Phase size elsewhere but publish no fee for it; the missing price is left undisclosed. Fees are stated to include applicable taxes; payment processor conversion may apply.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'crypto-fund-trader' and p.slug = '2-phase-evaluation'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Crypto Fund Trader 2-Phase base fees and $1K price disclosure — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked Crypto Fund Trader’s current official Terms. They publish base fees from $5K through $200K, and list a $1K Student 2-Phase size without publishing its fee; no $1K price is inferred.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'crypto-fund-trader' and p.slug = '2-phase-evaluation'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked Crypto Fund Trader’s current official Terms. They publish base fees from $5K through $200K, and list a $1K Student 2-Phase size without publishing its fee; no $1K price is inferred.');

commit;
