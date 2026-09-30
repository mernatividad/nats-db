begin;
set search_path = bullish_banana, extensions, public;

-- A second, in-review FundingPips record uses the same official domain and
-- name but contains only unverified duplicate challenge aliases. Keep history;
-- expose the canonical FundingPips catalog record only.
update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_status', 'duplicate legacy catalog record; see canonical FundingPips firm',
      'archived_reason', 'This offer row belongs to a duplicate FundingPips firm entry with the same name and official website. It has no captured program-specific evidence. Current source-backed offers are represented under the canonical fundingpips firm record.',
      'archived_reviewed_at', '2026-10-01',
      'canonical_firm_slug', 'fundingpips'
    )
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'funding-pips' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.firms f
where d.firm_id = f.id and f.slug = 'funding-pips';

update bullish_banana.firms f
set status = 'archived', archived_at = coalesce(f.archived_at, now()),
    published_at = null, updated_at = now(),
    description = 'Archived duplicate FundingPips firm record. Current source-backed offers are listed under the canonical FundingPips entry.',
    market_type = 'forex'
where f.slug = 'funding-pips' and f.status in ('published', 'in_review');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://fundingpips.com/',
  'FundingPips duplicate firm crosswalk — 2026-10-01',
  'The archived FundingPips firm entry and the canonical FundingPips entry share the same official website, name, and Forex market identity. The canonical record contains the current source-backed challenge catalog; the duplicate entry had only unverified offer aliases.'
from bullish_banana.firms f
where f.slug = 'funding-pips'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_label = 'FundingPips duplicate firm crosswalk — 2026-10-01');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Compared duplicate funding-pips and canonical fundingpips records: same official name/domain and market identity. Archived the duplicate firm and its three unverified program aliases, deactivated their destinations, and retained the canonical offer records.'
from bullish_banana.firms f
where f.slug = 'funding-pips'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz and v.notes like 'Compared duplicate funding-pips and canonical fundingpips records:%');

commit;
