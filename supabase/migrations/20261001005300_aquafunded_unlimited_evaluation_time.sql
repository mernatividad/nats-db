begin;
set search_path = bullish_banana, extensions, public;

-- AquaFunded's official Help Center says evaluation accounts have no time
-- limit, provided the account remains active and no other rules are breached.
with offers(slug) as (
  values
    ('1-step-flex'), ('aquaman'), ('3-step'), ('2-step-standard'),
    ('2-step-pro'), ('1-step-standard'), ('1-step-pro'),
    ('2-step-elite'), ('pay-after-pass')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'evaluation_time_limit', 'Unlimited; no fixed challenge deadline',
      'evaluation_time_limit_condition', 'Account must remain active and comply with all other rules',
      'evaluation_time_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'aquafunded'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

with offers(slug) as (
  values
    ('1-step-flex'), ('aquaman'), ('3-step'), ('2-step-standard'),
    ('2-step-pro'), ('1-step-standard'), ('1-step-pro'),
    ('2-step-elite'), ('pay-after-pass')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.aquafunded.com/en/articles/11875797-is-there-a-time-limit',
  'AquaFunded evaluation time-limit policy — 2026-10-01',
  'Official AquaFunded Help Center article reviewed 2026-10-01. It states that AquaFunded accounts have no time limit and traders may take as long as needed to complete the evaluation, provided the account remains active and no rules are breached.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'aquafunded' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'AquaFunded evaluation time-limit policy — 2026-10-01');

with offers(slug) as (
  values
    ('1-step-flex'), ('aquaman'), ('3-step'), ('2-step-standard'),
    ('2-step-pro'), ('1-step-standard'), ('1-step-pro'),
    ('2-step-elite'), ('pay-after-pass')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T16:13:46Z'::timestamptz,
  'Rechecked AquaFunded official Help Center policy on 2026-10-01. Evaluation may take as long as needed, provided the account remains active and no rules are breached. No fixed evaluation deadline is stated; phase time_limit_days is recorded as 0.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'aquafunded' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Rechecked AquaFunded official Help Center policy on 2026-10-01.%');

commit;
