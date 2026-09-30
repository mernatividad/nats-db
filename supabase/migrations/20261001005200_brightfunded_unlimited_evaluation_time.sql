begin;
set search_path = bullish_banana, extensions, public;

-- BrightFunded's current first-party evaluation guide states no time limit for
-- each of its three active Forex challenge plans and every evaluation phase.
with offers(slug, plan_name) as (
  values
    ('1-step', '1-Step'),
    ('2-step-bright', '2-Step Bright'),
    ('2-step-classic', '2-Step Classic')
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
where ph.program_id = p.id and f.slug = 'brightfunded'
  and p.status in ('published', 'in_review');

with offers(slug, plan_name) as (
  values
    ('1-step', '1-Step'),
    ('2-step-bright', '2-Step Bright'),
    ('2-step-classic', '2-Step Classic')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.brightfunded.com/en/articles/9241600-how-long-does-the-evaluation-process-take',
  'BrightFunded ' || o.plan_name || ' evaluation timing — 2026-10-01',
  'Official BrightFunded Help Center evaluation-duration guide reviewed 2026-10-01. It states there is no fixed deadline; each phase ends once its objectives are met. The article also states the applicable five-day minimum trading requirement, already recorded on the phase row.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'brightfunded' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'BrightFunded ' || o.plan_name || ' evaluation timing — 2026-10-01');

with offers(slug, plan_name) as (
  values
    ('1-step', '1-Step'),
    ('2-step-bright', '2-Step Bright'),
    ('2-step-classic', '2-Step Classic')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T16:02:03Z'::timestamptz,
  'Rechecked current official BrightFunded evaluation-duration guide on 2026-10-01. It states no fixed deadline for the ' || o.plan_name || ' evaluation; each phase ends when its objectives are met. Phase time_limit_days is recorded as 0.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'brightfunded' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Rechecked current official BrightFunded evaluation-duration guide on 2026-10-01.%');

commit;
