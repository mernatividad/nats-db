begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, name) as (
  values
    ('1-step-prime','1-Step Prime'),
    ('2-step-pro','2-Step Pro'),
    ('2-step-prime-x','2-Step Prime X')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'Unlimited maximum trading days',
      'time_limit_label', 'Unlimited; no fixed evaluation deadline',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'Hola Prime’s current official challenge comparison lists the maximum trading days for this challenge as Unlimited. A separate 30-calendar-day inactivity rule applies and is not the challenge completion deadline.',
      'time_limit_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'hola-prime'
  and p.market_type = 'forex' and p.status in ('published','in_review');

with offers(slug, name) as (
  values
    ('1-step-prime','1-Step Prime'),
    ('2-step-pro','2-Step Pro'),
    ('2-step-prime-x','2-Step Prime X')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://holaprime.com/forex/challenge-comparison/',
  'Hola Prime current challenge comparison — ' || o.name || ' time limit — 2026-10-01',
  'Current official Hola Prime Forex Challenge Comparison reviewed 2026-10-01. Its Challenge Account Rules table lists Maximum Trading Days as Unlimited for ' || o.name || '. The table separately lists a 30-day inactivity countdown; that is not a challenge completion deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'hola-prime' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'Hola Prime current challenge comparison — ' || o.name || ' time limit — 2026-10-01');

with offers(slug, name, note) as (
  values
    ('1-step-prime','1-Step Prime','Rechecked Hola Prime’s current official Forex Challenge Comparison on 2026-10-01. Its challenge-account rules list Maximum Trading Days as Unlimited for 1-Step Prime; the 30-day inactivity countdown is separate.'),
    ('2-step-pro','2-Step Pro','Rechecked Hola Prime’s current official Forex Challenge Comparison on 2026-10-01. Its challenge-account rules list Maximum Trading Days as Unlimited for 2-Step Pro; the 30-day inactivity countdown is separate.'),
    ('2-step-prime-x','2-Step Prime X','Rechecked Hola Prime’s current official Forex Challenge Comparison on 2026-10-01. Its challenge-account rules list Maximum Trading Days as Unlimited for 2-Step Prime X; the 30-day inactivity countdown is separate.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T06:45:00+09:00'::timestamptz, o.note
from offers o
join bullish_banana.firms f on f.slug = 'hola-prime'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = o.slug
where p.market_type = 'forex' and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.note);

commit;
