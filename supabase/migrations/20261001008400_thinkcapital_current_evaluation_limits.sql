begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set minimum_trading_days = 3,
    time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'minimum_trading_days', 3,
      'minimum_trading_days_note', 'ThinkCapital’s current program table lists three minimum trading days for this challenge.',
      'time_limit', 'Unlimited',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'ThinkCapital’s current program table lists Maximum Trading Days as Unlimited for this challenge. A separate 30-day inactivity rule requires at least one trade per 30 days and is not an evaluation deadline.',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'thinkcapital'
  and p.slug in ('lightning', 'dual-step-intraday', 'dual-step-swing', 'nexus')
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('lightning', 'https://www.thinkcapital.com/lightning/', 'ThinkCapital Lightning evaluation limits — 2026-10-01', 'The current official Lightning challenge table lists three minimum trading days and Maximum Trading Days as Unlimited. It separately lists one trade per 30 days as the inactivity period. Reviewed 2026-10-01.'),
  ('dual-step-intraday', 'https://www.thinkcapital.com/dual-step/', 'ThinkCapital Dual Step Intraday evaluation limits — 2026-10-01', 'The current official Dual Step challenge table lists three minimum trading days and Maximum Trading Days as Unlimited. It separately lists one trade per 30 days as the inactivity period. Reviewed 2026-10-01.'),
  ('dual-step-swing', 'https://www.thinkcapital.com/dual-step/', 'ThinkCapital Dual Step Swing evaluation limits — 2026-10-01', 'The current official Dual Step challenge table lists three minimum trading days and Maximum Trading Days as Unlimited. It separately lists one trade per 30 days as the inactivity period. Reviewed 2026-10-01.'),
  ('nexus', 'https://www.thinkcapital.com/nexus/', 'ThinkCapital Nexus evaluation limits — 2026-10-01', 'The current official Nexus challenge table lists three minimum trading days and Maximum Trading Days as Unlimited. It separately lists one trade per 30 days as the inactivity period. Reviewed 2026-10-01.')
) as x(program_slug, source_url, source_label, notes) on x.program_slug = p.slug
where f.slug = 'thinkcapital' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz, x.verification_note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('lightning', 'Rechecked ThinkCapital’s current official Lightning challenge table; it lists three minimum trading days and no maximum trading-day cap. Its 30-day inactivity limit is separate.'),
  ('dual-step-intraday', 'Rechecked ThinkCapital’s current official Dual Step challenge table; it lists three minimum trading days and no maximum trading-day cap. Its 30-day inactivity limit is separate.'),
  ('dual-step-swing', 'Rechecked ThinkCapital’s current official Dual Step challenge table; it lists three minimum trading days and no maximum trading-day cap. Its 30-day inactivity limit is separate.'),
  ('nexus', 'Rechecked ThinkCapital’s current official Nexus challenge table; it lists three minimum trading days and no maximum trading-day cap. Its 30-day inactivity limit is separate.')
) as x(program_slug, verification_note) on x.program_slug = p.slug
where f.slug = 'thinkcapital' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = x.verification_note);

commit;
