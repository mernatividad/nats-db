begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'Not applicable — funded stage',
      'time_limit_note', 'This is the post-evaluation funded stage. Evaluation completion deadlines apply to the evaluation phase only; the official model article does not define a challenge-completion deadline for this funded-stage row.',
      'time_limit_scope', 'Funded phase; not an evaluation deadline',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and ph.phase_number = 2
  and f.slug = 'goat-funded-trader'
  and p.slug in ('pay-later', 'goat-blitz')
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked the official model article. This stored phase row represents the post-evaluation funded stage; evaluation completion deadlines apply to the evaluation phase only.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'goat-funded-trader'
  and p.slug in ('pay-later', 'goat-blitz')
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked the official model article. This stored phase row represents the post-evaluation funded stage; evaluation completion deadlines apply to the evaluation phase only.');

commit;
