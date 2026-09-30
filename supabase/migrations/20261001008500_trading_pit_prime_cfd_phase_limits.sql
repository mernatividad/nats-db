begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set minimum_trading_days = 3,
    time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'minimum_trading_days', 3,
      'day_requirement_note', 'The Trading Pit states CFD Prime challenges require at least three profitable trading days per phase; each profitable day must exceed 0.5% of initial balance under its published end-of-day calculation.',
      'time_limit', 'Unlimited',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'The Trading Pit states CFD challenges have unlimited trading days. A separate 21-day inactivity rule can close an account and is not a challenge completion deadline.',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'the-trading-pit'
  and p.slug in ('prime-1-phase-cfd', 'prime-2-phase-cfd')
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('prime-1-phase-cfd', 'https://support.thetradingpit.com/is-there-a-minimum-trading-period-for-completing-the-forex-challenge', 'The Trading Pit Prime CFD 1-phase rules — 2026-10-01', 'The official support article specifies three profitable trading days for CFD Prime challenges and defines the 0.5% initial-balance threshold. The Trading Pit’s challenge-duration FAQ states CFD challenges have unlimited trading days, separate from the 21-day inactivity rule. Reviewed 2026-10-01.'),
  ('prime-2-phase-cfd', 'https://support.thetradingpit.com/is-there-a-minimum-trading-period-for-completing-the-forex-challenge', 'The Trading Pit Prime CFD 2-phase rules — 2026-10-01', 'The official support article specifies three profitable trading days for CFD Prime challenges and defines the 0.5% initial-balance threshold. The Trading Pit’s challenge-duration FAQ states CFD challenges have unlimited trading days, separate from the 21-day inactivity rule. Reviewed 2026-10-01.')
) as x(program_slug, source_url, source_label, notes) on x.program_slug = p.slug
where f.slug = 'the-trading-pit' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://support.thetradingpit.com/for-how-long-can-i-trade-on-my-challenge',
  'The Trading Pit CFD challenge duration — ' || p.name || ' — 2026-10-01',
  'The current official duration FAQ states CFD challenges have unlimited trading days and separately warns that 21 consecutive inactive days will close an account. Reviewed 2026-10-01.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the-trading-pit'
  and p.slug in ('prime-1-phase-cfd', 'prime-2-phase-cfd')
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'The Trading Pit CFD challenge duration — ' || p.name || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked The Trading Pit’s official CFD Prime minimum-profitable-days page and CFD challenge-duration FAQ. Prime requires three profitable days per phase; CFD challenge duration is unlimited, separately from the inactivity policy.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the-trading-pit'
  and p.slug in ('prime-1-phase-cfd', 'prime-2-phase-cfd')
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked The Trading Pit’s official CFD Prime minimum-profitable-days page and CFD challenge-duration FAQ. Prime requires three profitable days per phase; CFD challenge duration is unlimited, separately from the inactivity policy.');

commit;
