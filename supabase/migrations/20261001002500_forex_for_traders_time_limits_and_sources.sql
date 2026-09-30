begin;

-- Current official account articles explicitly state there is no maximum
-- evaluation duration for these four For Traders Forex evaluation products.
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'No time limit',
      'time_limit_source_reviewed', '2026-09-30'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id
  and f.slug = 'for-traders'
  and p.slug in ('fast-1-step', 'fast-static-1-step', 'classic-2-step', 'pay-after-pass-1-step');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('fast-1-step', 'https://help.fortraders.com/en/articles/15360683-fast-account-forex', 'FAST Forex rules', 'Current official Forex article states there is no time limit to complete the evaluation. Reviewed 2026-09-30.'),
  ('fast-static-1-step', 'https://help.fortraders.com/en/articles/15376206-fast-static-account-forex', 'FAST STATIC Forex rules', 'Current official Forex article states there is no time limit to complete the evaluation. Reviewed 2026-09-30.'),
  ('classic-2-step', 'https://help.fortraders.com/en/articles/15378600-classic-account-forex', 'CLASSIC Forex rules', 'Current official Forex article states there is no time limit to complete the evaluation. Reviewed 2026-09-30; applied to both evaluation phases.'),
  ('pay-after-pass-1-step', 'https://help.fortraders.com/en/articles/15359294-pay-after-pass-account-forex', 'PAY AFTER PASS Forex rules', 'Current official Forex article states there is no time limit to complete the evaluation. Reviewed 2026-09-30.')
) as x(program_slug, source_url, source_label, notes) on x.program_slug = p.slug
where f.slug = 'for-traders'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = x.source_url
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T12:55:00Z'::timestamptz,
  'Evaluation duration rechecked against the current official account-specific Forex rules on 2026-09-30. The provider states no time limit; all evaluation phases are represented as unlimited. Other source conflicts and selector-specific caveats remain disclosed in commercial details.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'for-traders'
  and p.slug in ('fast-1-step', 'fast-static-1-step', 'classic-2-step', 'pay-after-pass-1-step');

commit;
