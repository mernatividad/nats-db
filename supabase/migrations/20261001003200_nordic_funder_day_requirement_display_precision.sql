begin;

-- The official track table renders a dash for classic-track minimum days; keep
-- this as an unlisted requirement instead of asserting a numeric zero.
update bullish_banana.program_phases ph
set raw_rules = (coalesce(ph.raw_rules, '{}'::jsonb) - 'no_minimum_trading_days') ||
      jsonb_build_object('no_minimum_trading_days', false),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id
  and f.slug = 'nordic-funder'
  and p.slug in ('one-step', 'two-step', 'three-step');

commit;
