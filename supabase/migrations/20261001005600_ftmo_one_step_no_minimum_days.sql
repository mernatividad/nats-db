begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set minimum_trading_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'minimum_trading_days_note', 'No formal minimum trading-days objective is stated for FTMO Challenge 1-Step. The 50% Best Day Rule remains applicable; FTMO says passing in two trading days is possible only in the exceptional case of exactly half the required profit on each day.',
      'minimum_trading_days_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and ph.phase_number = 1
  and f.slug = 'ftmo' and p.slug = 'ftmo-1-step'
  and p.market_type = 'forex' and p.status = 'published';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://ftmo.com/en/trading-objectives/',
  'FTMO Trading Objectives — 1-Step trading days — 2026-10-01',
  'Official FTMO Trading Objectives page reviewed 2026-10-01. It says the four minimum trading days apply to both phases of the 2-Step Challenge and does not list that objective for 1-Step. The 1-Step Best Day Rule remains applicable; FTMO says a two-day pass is possible only with exactly half of the required profit on each day.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'ftmo' and p.slug = 'ftmo-1-step'
  and p.market_type = 'forex' and p.status = 'published'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'FTMO Trading Objectives — 1-Step trading days — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T01:26:26+09:00'::timestamptz,
  'Rechecked the official FTMO Trading Objectives page on 2026-10-01. No formal minimum trading-days objective is listed for the 1-Step evaluation; the Best Day Rule still applies and can make two trading days the exceptional minimum in a precisely balanced 50/50 case.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'ftmo' and p.slug = 'ftmo-1-step'
  and p.market_type = 'forex' and p.status = 'published'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Rechecked the official FTMO Trading Objectives page on 2026-10-01.%');

commit;
