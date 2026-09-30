begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, label) as (
  values
    ('one-step', 'One-Step Challenge'),
    ('two-step', 'Two-Step Challenge'),
    ('pro-one-step', 'One-Step Pro'),
    ('pro-two-step', 'Two-Step Pro')
)
update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_unit', 'not_stated',
      'time_limit_label', 'Maximum evaluation duration not stated',
      'time_limit_note', 'Finotive Funding’s current public Terms specify this challenge’s phase objectives and minimum profitable days but do not state a maximum evaluation duration. The Terms separately define a 30-consecutive-day inactivity rule; that is not a stated challenge deadline. Confirm any account-specific deadline in the Dashboard before purchase.',
      'time_limit_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'finotive-funding'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

with offers(slug, label) as (
  values
    ('one-step', 'One-Step Challenge'),
    ('two-step', 'Two-Step Challenge'),
    ('pro-one-step', 'One-Step Pro'),
    ('pro-two-step', 'Two-Step Pro')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://finotivefunding.com/terms-and-conditions',
  'Finotive Funding public challenge duration disclosure — ' || o.label || ' — 2026-10-01',
  'Reviewed current official Terms on 2026-10-01. Sections 8.2 and 10.2 describe challenge and Pro objectives and progression but do not state a maximum evaluation duration. Section 7.20 separately defines 30 consecutive days of inactivity; this is not a challenge deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'finotive-funding' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Finotive Funding public challenge duration disclosure — ' || o.label || ' — 2026-10-01');

with offers(slug, label) as (
  values
    ('one-step', 'One-Step Challenge'),
    ('two-step', 'Two-Step Challenge'),
    ('pro-one-step', 'One-Step Pro'),
    ('pro-two-step', 'Two-Step Pro')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T10:00:00+09:00'::timestamptz,
  'Rechecked the current Finotive Funding Terms on 2026-10-01. Challenge objectives and phase minimum profitable days are published, but no maximum challenge duration is stated. A separate 30-day inactivity closure applies; public evidence does not establish a challenge completion deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'finotive-funding' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'Rechecked the current Finotive Funding Terms on 2026-10-01.%');

commit;
