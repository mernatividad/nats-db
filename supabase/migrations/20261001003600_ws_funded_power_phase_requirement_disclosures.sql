begin;
set search_path = bullish_banana, extensions, public;

-- The current Power FAQ places its three 0.5% days in the funded stage only;
-- it does not state an evaluation minimum-day rule or a maximum duration.
update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_minimum_trading_days', true,
      'minimum_trading_days', 'No minimum is stated for the Power evaluation phase. The three days at 0.50% apply to the funded stage only.',
      'time_limit_note', 'The current official Power FAQ does not state a maximum time limit for the evaluation phase; confirm any account-specific condition in checkout/contract.',
      'requirement_recheck', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'wall-street-funded'
  and p.slug = 'power' and ph.phase_number = 1;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://faq.wsfunded.com/en/articles/16859382-1-phase-wall-street-power',
  'Power evaluation day/time-limit qualification — 2026-09-30',
  'The current official FAQ says three 0.50% trading days apply to the funded stage only, not Phase 1. It does not state a Phase 1 minimum-day rule or maximum evaluation duration. Those fields are represented as no minimum stated and time limit unstated, respectively.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'wall-street-funded' and p.slug = 'power'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_label = 'Power evaluation day/time-limit qualification — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T14:05:00Z'::timestamptz,
  'Rechecked the current Power Help Center article. It explicitly limits the three 0.50% days to the funded stage, not Phase 1; it does not state an evaluation minimum-day rule or maximum time limit. These distinctions are preserved without inferring an unlimited deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'wall-street-funded' and p.slug = 'power'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T14:05:00Z'::timestamptz);

commit;
