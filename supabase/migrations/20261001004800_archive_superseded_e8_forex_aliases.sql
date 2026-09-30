begin;
set search_path = bullish_banana, extensions, public;

-- Current first-party E8 materials identify E8 One, E8 Pro and E8 Signature as
-- the current Classic Markets products. The older generic rows below duplicate
-- the detailed Forex records and are retained as archived aliases.
with aliases(slug, canonical_slug, source_url, reason) as (
  values
    ('e8-one', 'e8-one-forex', 'https://help.e8markets.com/en/articles/11775980-e8-one', 'Legacy E8 One row duplicates the current detailed Forex offer.'),
    ('e8-pro', 'e8-pro-forex', 'https://help.e8markets.com/en/articles/15274219-e8-pro', 'Legacy E8 Pro row duplicates the current detailed Forex offer.'),
    ('e8-signature', 'e8-signature-forex', 'https://help.e8markets.com/en/articles/11755943-e8-signature-forex', 'Legacy E8 Signature row duplicates the current detailed Forex offer.')
)
update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
      jsonb_build_object('superseded_by', a.canonical_slug, 'superseded_reason', a.reason,
        'superseded_reviewed_at', '2026-10-01', 'superseded_source', a.source_url)
from bullish_banana.firms f, aliases a
join bullish_banana.programs canonical on canonical.slug = a.canonical_slug
join bullish_banana.firms canonical_firm on canonical_firm.id = canonical.firm_id
where p.firm_id = f.id and f.slug = 'e8-markets' and p.slug = a.slug
  and canonical_firm.id = f.id and canonical.market_type = 'forex'
  and canonical.status in ('published', 'in_review') and p.status <> 'archived';

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'e8-markets'
  and p.slug in ('e8-one', 'e8-pro', 'e8-signature') and p.status = 'archived';

with aliases(slug, canonical_slug, source_url) as (
  values
    ('e8-one', 'e8-one-forex', 'https://help.e8markets.com/en/articles/11775980-e8-one'),
    ('e8-pro', 'e8-pro-forex', 'https://help.e8markets.com/en/articles/15274219-e8-pro'),
    ('e8-signature', 'e8-signature-forex', 'https://help.e8markets.com/en/articles/11755943-e8-signature-forex')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, a.source_url, 'E8 current product lineup and alias review — 2026-10-01',
  'Official E8 product/help page reviewed 2026-10-01. This legacy row duplicates the current detailed Forex record ' || a.canonical_slug || '; it is archived as historical catalog data, not deleted.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join aliases a on a.slug = p.slug
where f.slug = 'e8-markets'
  and p.status = 'archived'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'E8 current product lineup and alias review — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T15:51:30Z'::timestamptz,
  'Compared this legacy row with the current detailed Forex offer on the official E8 Help Center page on 2026-10-01. The current catalog record is named in commercial_details; the legacy duplicate is archived, preserved and its destination disabled.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'e8-markets'
  and p.slug in ('e8-one', 'e8-pro', 'e8-signature') and p.status = 'archived'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Compared this legacy row with the current detailed Forex offer on the official E8 Help Center page on 2026-10-01.%');

commit;
