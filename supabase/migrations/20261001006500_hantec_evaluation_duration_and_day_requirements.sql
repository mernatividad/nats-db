begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, source_url, name, minimum_days) as (
  values
    ('endurance','https://help.htrader.hmarkets.com/en/support/solutions/articles/158000445800-endurance-3-step-challenge-','Endurance',3),
    ('enhanced','https://htrader.hmarkets.com/blog/how-funded-trading-works-at-hantec-trader/','Enhanced',null),
    ('enhancedx','https://htrader.freshdesk.com/en/support/solutions/articles/158000445799-enhancedx-2-step-consistency-','EnhancedX',0),
    ('express','https://help.htrader.hmarkets.com/en/support/solutions/articles/158000445797-express-1-step-','Express',0)
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = case when o.minimum_days = 0 then 0 else ph.minimum_trading_days end,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'No maximum evaluation period',
      'time_limit_label', 'Unlimited; no fixed evaluation deadline',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'The current Hantec Trader program rules explicitly state there is no maximum trading period for this challenge. Its 30-day inactivity rule is separate and does not set a challenge completion deadline.',
      'time_limit_verified_at', '2026-10-01'
    ) || case when o.minimum_days = 0 then jsonb_build_object(
      'minimum_trading_days', 0,
      'no_minimum_trading_days', true,
      'day_requirement_note', 'The current Hantec Trader program rules state that no minimum trading days are required during evaluation.',
      'day_requirement_verified_at', '2026-10-01'
    ) else '{}'::jsonb end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'hantec-trader'
  and p.market_type = 'forex' and p.status in ('published','in_review');

with offers(slug, source_url, name, minimum_days) as (
  values
    ('endurance','https://help.htrader.hmarkets.com/en/support/solutions/articles/158000445800-endurance-3-step-challenge-','Endurance',3),
    ('enhanced','https://htrader.hmarkets.com/blog/how-funded-trading-works-at-hantec-trader/','Enhanced',null),
    ('enhancedx','https://htrader.freshdesk.com/en/support/solutions/articles/158000445799-enhancedx-2-step-consistency-','EnhancedX',0),
    ('express','https://help.htrader.hmarkets.com/en/support/solutions/articles/158000445797-express-1-step-','Express',0)
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url,
  'Hantec Trader ' || o.name || ' evaluation duration — 2026-10-01',
  case when o.slug = 'endurance' then 'Current official Hantec Trader Endurance rules, modified 2026-08-25, reviewed 2026-10-01: each evaluation stage has a 3-day minimum and the maximum trading period is none. The separate inactivity limit is 30 days.'
  when o.slug = 'enhanced' then 'Current official Hantec Trader rules overview reviewed 2026-10-01: both Enhanced stages have no time limit. Stage-specific minimum profitable days are listed separately.'
  when o.slug = 'enhancedx' then 'Current official Hantec Trader EnhancedX help article reviewed 2026-10-01 explicitly states no minimum required days and no maximum trading period during the challenge.'
  else 'Current official Hantec Trader Express rules reviewed 2026-10-01 explicitly state no minimum trading period and no maximum trading period during the challenge.' end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'hantec-trader' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'Hantec Trader ' || o.name || ' evaluation duration — 2026-10-01');

with offers(slug, name, verification) as (
  values
    ('endurance','Endurance','Rechecked the current official Hantec Trader Endurance rules on 2026-10-01: all three evaluation stages have a 3-day trading minimum and there is no maximum trading period; inactivity is a separate 30-day breach rule.'),
    ('enhanced','Enhanced','Rechecked current official Hantec Trader rules on 2026-10-01: both Enhanced stages have no time limit.'),
    ('enhancedx','EnhancedX','Rechecked the current official Hantec Trader EnhancedX FAQ on 2026-10-01: no minimum evaluation days and no maximum trading period are stated.'),
    ('express','Express','Rechecked the current official Hantec Trader Express help page on 2026-10-01: the evaluation has no minimum trading days and no maximum trading period.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T06:10:00+09:00'::timestamptz, o.verification
from offers o
join bullish_banana.firms f on f.slug = 'hantec-trader'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = o.slug
where p.market_type = 'forex' and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.verification);

commit;
