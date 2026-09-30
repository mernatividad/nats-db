begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, source_url, program_name) as (
  values
    ('1-step-flex','https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex'),
    ('2-step-standard','https://help.fundingpips.com/hc/en-us/articles/34501809112081-2-Step-Standard','2 Step Standard'),
    ('2-step-pro-model','https://help.fundingpips.com/hc/en-us/articles/34502027344017-2-Step-Pro-Model','2 Step Pro'),
    ('2-step-flex','https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = case when o.slug = '1-step-flex' then 0 else ph.minimum_trading_days end,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'No fixed evaluation deadline',
      'time_limit_label', 'Unlimited evaluation time',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'The current FundingPips offer page states there is no time limit to pass the evaluation. A separate 30-day completed-trade inactivity rule applies; this is recorded separately and is not a challenge deadline.',
      'time_limit_verified_at', '2026-10-01'
    ) || case when o.slug = '1-step-flex' then jsonb_build_object(
      'no_minimum_trading_days', true,
      'day_requirement_note', 'No minimum trading days are required for the 1 Step Flex evaluation.',
      'day_requirement_verified_at', '2026-10-01'
    ) else '{}'::jsonb end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'fundingpips'
  and p.market_type = 'forex' and p.status in ('published','in_review');

with offers(slug, source_url, program_name) as (
  values
    ('1-step-flex','https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex'),
    ('2-step-standard','https://help.fundingpips.com/hc/en-us/articles/34501809112081-2-Step-Standard','2 Step Standard'),
    ('2-step-pro-model','https://help.fundingpips.com/hc/en-us/articles/34502027344017-2-Step-Pro-Model','2 Step Pro'),
    ('2-step-flex','https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url,
  'FundingPips ' || o.program_name || ' evaluation deadline — 2026-10-01',
  case when o.slug = '1-step-flex' then
    'Current official 1 Step Flex help article reviewed 2026-10-01 states there is no time limit and no minimum trading days to pass the evaluation. It also documents a separate 30-consecutive-day completed-trade inactivity breach; this is not the evaluation deadline.'
  else
    'Current official ' || o.program_name || ' help article reviewed 2026-10-01 states there is no time limit on either evaluation phase. It separately documents an inactivity rule requiring a completed trade every 30 days; this is not a phase deadline.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'fundingpips' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'FundingPips ' || o.program_name || ' evaluation deadline — 2026-10-01');

with offers(slug, program_name, verification) as (
  values
    ('1-step-flex','1 Step Flex','Rechecked the current official 1 Step Flex offer page on 2026-10-01. It states no minimum trading days and no evaluation time limit; the separate 30-day completed-trade inactivity condition is preserved as a different rule.'),
    ('2-step-standard','2 Step Standard','Rechecked the current official 2 Step Standard offer page on 2026-10-01. It states no time limit on either evaluation phase; the separate inactivity rule remains distinct from the deadline.'),
    ('2-step-pro-model','2 Step Pro','Rechecked the current official 2 Step Pro offer page on 2026-10-01. It states no time limit on either evaluation phase; the separate inactivity rule remains distinct from the deadline.'),
    ('2-step-flex','2 Step Flex','Rechecked the current official 2 Step Flex offer page on 2026-10-01. It states no time limit on either evaluation phase; the separate inactivity rule remains distinct from the deadline.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T04:20:00+09:00'::timestamptz, o.verification
from offers o
join bullish_banana.firms f on f.slug = 'fundingpips'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = o.slug
where p.market_type = 'forex' and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.verification);

commit;
