begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_time_limit', true,
      'time_limit_note', 'Blue Guardian’s current Forex challenge page states there are no time limits. This is the evaluation deadline; funded inactivity and payout-day rules are separate.',
      'time_limit_scope', 'Current Blue Guardian Forex evaluation challenge model shown in its live plan selector',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'blue-guardian'
  and p.slug in ('1-step-nano','2-step-nano','1-step-standard')
  and p.market_type = 'forex';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label || ' — ' || p.name || ' — 2026-10-01', x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('1-step-nano', 'https://help.blueguardian.com/en/articles/16444654-1-step-nano-rules', 'Blue Guardian 1 Step Nano model rules', 'Current official model-specific rules identify the 1 Step Nano evaluation and distinguish its evaluation requirements from funded-account trading-day requirements.'),
  ('2-step-nano', 'https://help.blueguardian.com/en/articles/16445450-2-step-nano-rules', 'Blue Guardian 2 Step Nano model rules', 'Current official model-specific rules identify both phases of the 2 Step Nano evaluation and state no minimum challenge trading days.'),
  ('1-step-standard', 'https://help.blueguardian.com/en/articles/14062186-1-step-standard-rules', 'Blue Guardian 1 Step Standard model rules', 'Current official model-specific rules identify the 1 Step Standard evaluation and distinguish its evaluation requirements from funded-account trading-day requirements.')
) as x(slug, source_url, source_label, notes) on x.slug = p.slug
where f.slug = 'blue-guardian' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = x.source_label || ' — ' || p.name || ' — 2026-10-01');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://blueguardian.com/forex',
  'Blue Guardian current Forex challenge page and plan selector — ' || p.name || ' — 2026-10-01',
  'The current official Forex challenge page lists this model in its plan selector and states “No time limits” in the challenge offer. This is recorded as the evaluation deadline, distinct from funded trading-day or inactivity terms.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian'
  and p.slug in ('1-step-nano','2-step-nano','1-step-standard')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Blue Guardian current Forex challenge page and plan selector — ' || p.name || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked the current official Blue Guardian Forex challenge page and the plan-specific rules article. The current challenge page lists this model and states no time limits. This applies to the evaluation deadline, not funded payout-day requirements or inactivity terms.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian'
  and p.slug in ('1-step-nano','2-step-nano','1-step-standard')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz);

commit;
