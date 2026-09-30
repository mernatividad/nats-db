begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'Unlimited',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'Hola Prime’s current official Forex Challenge Comparison lists Maximum Trading Days as Unlimited for the 2-Step Prime challenge. Its 30-day inactivity suspension is separate from the evaluation deadline.',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'hola-prime'
  and p.slug = '2-step-prime' and p.market_type = 'forex'
  and p.status in ('published', 'in_review') and ph.phase_number in (1, 2);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://holaprime.com/forex/challenge-comparison/',
  'Hola Prime 2-Step Prime evaluation deadline — 2026-10-01',
  'The current official Forex Challenge Comparison lists Maximum Trading Days as Unlimited for the 2-Step Prime challenge. It separately lists a 30-consecutive-calendar-day inactivity suspension. Reviewed 2026-10-01.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hola-prime' and p.slug = '2-step-prime'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Hola Prime 2-Step Prime evaluation deadline — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked Hola Prime’s current official Forex Challenge Comparison. It lists unlimited maximum trading days for 2-Step Prime; 30-day inactivity is a separate rule.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hola-prime' and p.slug = '2-step-prime'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked Hola Prime’s current official Forex Challenge Comparison. It lists unlimited maximum trading days for 2-Step Prime; 30-day inactivity is a separate rule.');

commit;
