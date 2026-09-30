begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'Alpha Capital states that its evaluations have no time limit.',
      'time_limit_scope', 'Current Alpha One, Alpha Pro, and Alpha Swing evaluation paths',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'alpha-capital-group'
  and p.slug in ('alpha-one','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing');

update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_status', 'not offered for new purchases',
      'archived_reason', 'Alpha Capital states Alpha Three is no longer available to new buyers; it is retained as history for existing accounts.',
      'archived_reviewed_at', '2026-10-01',
      'archived_source', 'https://alphacapitalgroup.uk/posts/alpha-one-vs-alpha-pro-vs-alpha-swing-vs-alpha-three-2026'
    )
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'alpha-capital-group' and p.slug = 'alpha-three';

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'alpha-capital-group' and p.slug = 'alpha-three';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://alphacapitalgroup.uk/resources/what-is-a-qualified-trading-account-a-uk-guide-for-2026',
  'Alpha Capital evaluation time-limit policy — ' || p.name || ' — 2026-10-01',
  'The current official guide states Alpha Capital evaluations carry no time limit. Applied to the current Alpha One, Alpha Pro, and Alpha Swing evaluation offers represented by this record.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group'
  and p.slug in ('alpha-one','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'Alpha Capital evaluation time-limit policy — ' || p.name || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T03:00:00Z'::timestamptz,
  'Rechecked the current Alpha Capital guide, which states that evaluations have no time limit. This is distinct from the qualified-account phase.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group'
  and p.slug in ('alpha-one','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id
    and v.verified_at = '2026-10-01T03:00:00Z'::timestamptz);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://alphacapitalgroup.uk/posts/alpha-one-vs-alpha-pro-vs-alpha-swing-vs-alpha-three-2026',
  'Alpha Three availability status — 2026-10-01',
  'Alpha Capital’s current guide says Alpha Three is no longer available for new purchases and retains its rules for existing accounts. The program record is archived, not deleted, to preserve historical information.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-three'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'Alpha Three availability status — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T03:00:00Z'::timestamptz,
  'The current Alpha Capital guide explicitly states Alpha Three is not currently offered to new purchasers. Archived the record and disabled its destination while retaining the historical data.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-three'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id
    and v.verified_at = '2026-10-01T03:00:00Z'::timestamptz);

commit;
