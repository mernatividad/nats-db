begin;
set search_path = bullish_banana, extensions, public;

-- CTI's current first-party challenge pages explicitly state there is no time
-- limit on the 1-Step challenge or either phase of the 2-Step challenge.
with offers(slug, source_url, source_label, notes) as (
  values
    ('1-step-challenge', 'https://citytradersimperium.com/1-step-challenge/', 'CTI 1-Step Challenge rules — unlimited time — 2026-10-01', 'Official CTI product page reviewed 2026-10-01: Challenge Metrics lists “Time Limit None”; page also says one phase, 8% target, 5% trailing max drawdown, no daily drawdown and three minimum profitable days.'),
    ('2-step-challenge', 'https://citytradersimperium.com/2-step-challenge/', 'CTI 2-Step Challenge rules — unlimited time — 2026-10-01', 'Official CTI product page reviewed 2026-10-01: Challenge Metrics lists “Time Limit None” and states both phases run with no time limit; page lists 10% then 5% targets and three minimum profitable days per phase.')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'evaluation_time_limit', 'Unlimited; no fixed challenge deadline',
      'evaluation_time_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'city-traders-imperium'
  and p.status in ('published', 'in_review');

with offers(slug, source_url, source_label, notes) as (
  values
    ('1-step-challenge', 'https://citytradersimperium.com/1-step-challenge/', 'CTI 1-Step Challenge rules — unlimited time — 2026-10-01', 'Official CTI product page reviewed 2026-10-01: Challenge Metrics lists “Time Limit None”; page also says one phase, 8% target, 5% trailing max drawdown, no daily drawdown and three minimum profitable days.'),
    ('2-step-challenge', 'https://citytradersimperium.com/2-step-challenge/', 'CTI 2-Step Challenge rules — unlimited time — 2026-10-01', 'Official CTI product page reviewed 2026-10-01: Challenge Metrics lists “Time Limit None” and states both phases run with no time limit; page lists 10% then 5% targets and three minimum profitable days per phase.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url, o.source_label, o.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'city-traders-imperium' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = o.source_label);

with offers(slug) as (values ('1-step-challenge'), ('2-step-challenge'))
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T16:00:04Z'::timestamptz,
  'Rechecked current official CTI product page on 2026-10-01. Its Challenge Metrics state no time limit for this challenge; the 2-Step page explicitly applies this to both phases. Phase time_limit_days is recorded as 0.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'city-traders-imperium' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Rechecked current official CTI product page on 2026-10-01.%');

commit;
