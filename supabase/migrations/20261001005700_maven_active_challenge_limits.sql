begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, phase_number) as (
  values
    ('standard-1-step', 1),
    ('standard-3-step', 1), ('standard-3-step', 2), ('standard-3-step', 3),
    ('buy-now-pay-later', 1),
    ('omo-2-step', 1), ('omo-2-step', 2)
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'evaluation_time_limit', 'Unlimited; no fixed challenge deadline',
      'minimum_trading_days_note', 'Maven states there is no minimum trading-days requirement for its accounts.',
      'evaluation_time_verified_at', '2026-10-01',
      'minimum_trading_days_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and ph.phase_number = o.phase_number
  and f.slug = 'maven-trading' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

with offers(slug) as (
  values ('standard-1-step'), ('standard-3-step'), ('buy-now-pay-later'), ('omo-2-step')
), policy_sources(source_url, source_label, notes) as (
  values
    ('https://maventrading.com/blog/benefits-of-maven-funded-trading-program',
      'Maven Trading challenge time-limit policy — 2026-10-01',
      'Official Maven Trading article states Maven does not add time limits to its challenges. Reviewed 2026-10-01 and applied to the active Standard, Buy Now Pay Later, and OMO evaluation offers shown on Maven current homepage.'),
    ('https://maventrading.com/blog/forex-trading-sessions-hours-volatility-guide',
      'Maven Trading minimum trading days — 2026-10-01',
      'Official Maven Trading article states Maven accounts have no minimum trading days. Reviewed 2026-10-01 and applied to active evaluation offers shown on Maven current homepage. This is recorded as no formal minimum-day requirement.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.source_url, s.source_label, s.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
cross join policy_sources s
where f.slug = 'maven-trading' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources old
    where old.program_id = p.id and old.source_label = s.source_label);

with offers(slug) as (
  values ('standard-1-step'), ('standard-3-step'), ('buy-now-pay-later'), ('omo-2-step')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T01:31:18+09:00'::timestamptz,
  'Rechecked Maven official policy articles and current homepage on 2026-10-01. Current lineup shows this challenge as an active evaluation offer. Maven states no fixed challenge deadline and no minimum trading days; phase data records both as no formal requirement.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'maven-trading' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Rechecked Maven official policy articles and current homepage on 2026-10-01.%');

commit;
