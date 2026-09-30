begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'No time limit; no fixed challenge deadline',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'Blue Guardian’s current official Pay Only When You Pass page lists the BNPL challenge plans and states that traders can hit the target on their own terms with no time limits. This is the evaluation deadline, separate from inactivity or funded-account rules.',
      'time_limit_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'blue-guardian'
  and p.slug = 'buy-now-pay-later' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://blueguardian.com/buy-now-pay-later',
  'Blue Guardian BNPL challenge deadline — 2026-10-01',
  'Current official Blue Guardian Pay Only When You Pass page lists the 1 Step Standard, 1 Step Nano, 2 Step Standard, and 2 Step Nano BNPL plans and states “No time limits” for completing the challenge. Reviewed 2026-10-01.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Blue Guardian BNPL challenge deadline — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T09:00:00+09:00'::timestamptz,
  'Rechecked Blue Guardian’s current official Pay Only When You Pass page on 2026-10-01. The page names the BNPL challenge plans and states there are no time limits to complete the challenge.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'Rechecked Blue Guardian’s current official Pay Only When You Pass page%');

commit;
