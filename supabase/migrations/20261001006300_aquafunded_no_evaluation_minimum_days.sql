begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, name) as (
  values
    ('1-step-flex','1 Step Flex'),
    ('aquaman','AquaMan'),
    ('3-step','3 Step'),
    ('2-step-pro','2 Step Pro'),
    ('pay-after-pass','Pay After Pass')
)
update bullish_banana.program_phases ph
set minimum_trading_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_minimum_trading_days', true,
      'day_requirement_note', 'AquaFunded states there are no minimum trading days during the evaluation stage for this model. This does not remove separate funded-stage qualifying-day requirements.',
      'day_requirement_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'aquafunded'
  and p.market_type = 'forex' and p.status in ('published','in_review');

with offers(slug, name) as (
  values
    ('1-step-flex','1 Step Flex'),
    ('aquaman','AquaMan'),
    ('3-step','3 Step'),
    ('2-step-pro','2 Step Pro'),
    ('pay-after-pass','Pay After Pass')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://help.aquafunded.com/en/articles/15255671-are-there-minimum-trading-days',
  'AquaFunded evaluation minimum days — ' || o.name || ' — 2026-10-01',
  'Current official AquaFunded minimum-day FAQ (updated 2026-08-18) explicitly lists ' || o.name || ' Evaluation among models with no minimum trading days. The FAQ distinguishes evaluation rules from funded-stage minimum reward days.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'aquafunded' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'AquaFunded evaluation minimum days — ' || o.name || ' — 2026-10-01');

with offers(slug, name, verification) as (
  values
    ('1-step-flex','1 Step Flex','Rechecked AquaFunded official minimum-day FAQ on 2026-10-01. It places 1 Step Flex Evaluation in the no-minimum category and separately lists three minimum qualifying days for the funded stage.'),
    ('aquaman','AquaMan','Rechecked AquaFunded official minimum-day FAQ on 2026-10-01. It places AquaMan Evaluation in the no-minimum category and separately lists funded-stage requirements.'),
    ('3-step','3 Step','Rechecked AquaFunded official minimum-day FAQ on 2026-10-01. It places 3 Step Evaluation in the no-minimum category.'),
    ('2-step-pro','2 Step Pro','Rechecked AquaFunded official minimum-day FAQ on 2026-10-01. It places 2 Step Pro Evaluation in the no-minimum category and separately lists funded-stage requirements.'),
    ('pay-after-pass','Pay After Pass','Rechecked AquaFunded official minimum-day FAQ on 2026-10-01. It places Pay Later Evaluation in the no-minimum category; funded-stage requirements are distinct.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T05:15:00+09:00'::timestamptz, o.verification
from offers o
join bullish_banana.firms f on f.slug = 'aquafunded'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = o.slug
where p.market_type = 'forex' and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.verification);

commit;
