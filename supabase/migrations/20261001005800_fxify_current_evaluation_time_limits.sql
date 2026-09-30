begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, time_limit_days, label, conditions) as (
  values
    ('one-phase', 0, 'Unlimited; no fixed challenge deadline', 'No maximum evaluation period is stated.'),
    ('two-phase-standard', 0, 'Unlimited; no fixed challenge deadline', 'No maximum evaluation period is stated.'),
    ('two-phase-classic', 0, 'Unlimited; no fixed challenge deadline', 'No maximum evaluation period is stated.'),
    ('two-phase-pro', 0, 'Unlimited; no fixed challenge deadline', 'A separate 60-day inactivity rule requires a trade to be placed.'),
    ('three-phase', 0, 'Unlimited; no fixed challenge deadline', 'No maximum evaluation period is stated.'),
    ('lightning-challenge', 5, '5 trading days', 'Failure to reach the profit target within five trading days is a hard breach.')
)
update bullish_banana.program_phases ph
set time_limit_days = o.time_limit_days,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', o.label,
      'time_limit_label', o.label,
      'time_limit_unit', case when o.slug = 'lightning-challenge' then 'trading_days' else 'unlimited' end,
      'time_limit_note', o.conditions,
      'evaluation_time_limit_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'fxify'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

with offers(slug, source_url, source_label, notes) as (
  values
    ('one-phase', 'https://fxify.com/blog/average-time-to-pass-prop-firm-challenge/',
      'FXIFY evaluation time limits — One Phase — 2026-10-01',
      'Current official FXIFY article reviewed 2026-10-01 states One Phase has no time limit.'),
    ('two-phase-standard', 'https://fxify.com/blog/average-time-to-pass-prop-firm-challenge/',
      'FXIFY evaluation time limits — Two Phase Standard — 2026-10-01',
      'Current official FXIFY article reviewed 2026-10-01 states Two Phase Standard has no time limit.'),
    ('two-phase-classic', 'https://fxify.com/blog/average-time-to-pass-prop-firm-challenge/',
      'FXIFY evaluation time limits — Two Phase Classic — 2026-10-01',
      'Current official FXIFY article reviewed 2026-10-01 states Two Phase Classic has no time limit.'),
    ('two-phase-pro', 'https://fxify.com/blog/average-time-to-pass-prop-firm-challenge/',
      'FXIFY evaluation time limits — Two Phase Pro — 2026-10-01',
      'Current official FXIFY article reviewed 2026-10-01 states Two Phase Pro has no maximum evaluation deadline. A separate current Pro FAQ specifies the 60-day inactivity condition.'),
    ('three-phase', 'https://fxify.com/blog/average-time-to-pass-prop-firm-challenge/',
      'FXIFY evaluation time limits — Three Phase — 2026-10-01',
      'Current official FXIFY article reviewed 2026-10-01 states Three Phase has no time limit.'),
    ('lightning-challenge', 'https://fxify.com/faqs/all-faqs/lightning-plan/lightning-plan-what-is-the-lightning-plan/',
      'FXIFY Lightning maximum evaluation period — 2026-10-01',
      'Current official FXIFY Lightning FAQ reviewed 2026-10-01 states the plan has a five-trading-day limit to reach the profit target; a separate official FAQ states failure to meet the target within five trading days is a hard breach.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url, o.source_label, o.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'fxify' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = o.source_label);

with offers(slug, note) as (
  values
    ('one-phase', 'Rechecked FXIFY official evaluation matrix on 2026-10-01: One Phase has no time limit.'),
    ('two-phase-standard', 'Rechecked FXIFY official evaluation matrix on 2026-10-01: Two Phase Standard has no time limit.'),
    ('two-phase-classic', 'Rechecked FXIFY official evaluation matrix on 2026-10-01: Two Phase Classic has no time limit.'),
    ('two-phase-pro', 'Rechecked FXIFY official evaluation matrix on 2026-10-01: Two Phase Pro has no maximum deadline; its separate inactivity condition is recorded.'),
    ('three-phase', 'Rechecked FXIFY official evaluation matrix on 2026-10-01: Three Phase has no time limit.'),
    ('lightning-challenge', 'Rechecked FXIFY official Lightning FAQ on 2026-10-01: the evaluation target must be reached in five trading days; failure is a hard breach. The minimum-day requirement is not conflated with this deadline.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T01:43:33+09:00'::timestamptz, o.note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'fxify' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.note);

commit;
