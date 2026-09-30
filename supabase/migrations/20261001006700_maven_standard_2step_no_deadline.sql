begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'No time limit; no fixed challenge deadline',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'Maven Trading states that its challenges have no time limit. Its current homepage lists Standard 2-Step as an active challenge. Any inactivity policy is separate from the challenge completion deadline.',
      'time_limit_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'maven-trading'
  and p.slug = 'standard-2-step' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.source_url, s.source_label, s.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://maventrading.com/blog/tips-to-pass-prop-firm-challenges',
   'Maven Trading challenge time-limit policy — 2026-10-01',
   'Official Maven Trading article says challenges have no time limit. Reviewed 2026-10-01; used with the current homepage listing Standard 2-Step as an active evaluation offer.'),
  ('https://maventrading.com/',
   'Maven Trading current challenge lineup — 2026-10-01',
   'Current official Maven Trading homepage lists Standard 2-Step as an active challenge. Reviewed 2026-10-01.')
) as s(source_url, source_label, notes)
where f.slug = 'maven-trading' and p.slug = 'standard-2-step'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources old
    where old.program_id = p.id and old.source_label = s.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T08:00:00+09:00'::timestamptz,
  'Rechecked Maven Trading’s official challenge policy article and current homepage on 2026-10-01. Maven states challenges have no time limit; current homepage lists Standard 2-Step as an active challenge. Recorded as no fixed phase deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading' and p.slug = 'standard-2-step'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'Rechecked Maven Trading’s official challenge policy article%');

commit;
