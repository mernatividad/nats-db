begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set minimum_trading_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'minimum_trading_days', 0,
      'no_minimum_trading_days', true,
      'day_requirement_note', 'The5ers’ current official Hyper Growth page states there are no minimum trades or days required to complete Level 1. The separate 30-consecutive-day inactivity expiry is not a minimum trading-day requirement.',
      'day_requirement_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'the5ers'
  and p.slug = 'hyper-growth' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://the5ers.com/hyper-growth/',
  'The5ers Hyper Growth evaluation day requirement — 2026-10-01',
  'Current official Hyper Growth page lists “No minimum trades or days requirements for completing level 1.” The same page separately describes expiry after more than 30 consecutive inactive days. Reviewed 2026-10-01.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'hyper-growth'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'The5ers Hyper Growth evaluation day requirement — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T09:30:00+09:00'::timestamptz,
  'Rechecked The5ers’ current official Hyper Growth page on 2026-10-01. It states there is no minimum trades or days requirement for completing Level 1; the separate 30-day inactivity expiry is not a minimum-day condition.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'hyper-growth'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'Rechecked The5ers’ current official Hyper Growth page%');

commit;
