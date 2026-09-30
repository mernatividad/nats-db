begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'FundedElite currently advertises “No Time Limits” on its homepage. The reviewed offer-specific material does not define the limit by phase; confirm the selected configuration in checkout.',
      'time_limit_source_scope', 'firm-level homepage claim; not a phase-specific commitment',
      'time_limit_reviewed_at', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fundedelite'
  and p.program_type = 'evaluation';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://fundedelite.com/', 'FundedElite duration scope — ' || p.name || ' — 2026-09-30',
  'The current homepage advertises “No Time Limits” generally. This is firm-level promotional wording; the reviewed offer-specific documentation does not map the claim to a particular evaluation phase. The phase record preserves this scope and asks traders to confirm the selected configuration.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite' and p.program_type = 'evaluation'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_label = 'FundedElite duration scope — ' || p.name || ' — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T14:40:00Z'::timestamptz,
  'Rechecked current FundedElite homepage and challenge documentation. Homepage broadly advertises no time limits, but inspected challenge materials do not specify the deadline per phase. The broad claim is shown with its limited source scope; do not infer a phase-specific unlimited duration.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite' and p.program_type = 'evaluation'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T14:40:00Z'::timestamptz);

commit;
