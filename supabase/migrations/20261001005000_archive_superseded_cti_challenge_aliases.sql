begin;
set search_path = bullish_banana, extensions, public;

-- CTI's current homepage exposes one 1-Step and one 2-Step challenge path.
-- The newer numeric-slug rows contain the current price and offer capture;
-- older word-form rows duplicate those offers and are retained as aliases.
with aliases(slug, canonical_slug, source_url, reason) as (
  values
    ('one-step-challenge', '1-step-challenge', 'https://citytradersimperium.com/1-step-challenge/', 'Older word-form CTI 1-Step row duplicates the current numeric-slug offer.'),
    ('two-step-challenge', '2-step-challenge', 'https://citytradersimperium.com/2-step-challenge/', 'Older word-form CTI 2-Step row duplicates the current numeric-slug offer.')
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
where p.firm_id = f.id and f.slug = 'city-traders-imperium' and p.slug = a.slug
  and canonical_firm.id = f.id and canonical.market_type = 'forex'
  and canonical.status in ('published', 'in_review') and p.status <> 'archived';

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'city-traders-imperium'
  and p.slug in ('one-step-challenge', 'two-step-challenge') and p.status = 'archived';

with aliases(slug, canonical_slug, source_url) as (
  values
    ('one-step-challenge', '1-step-challenge', 'https://citytradersimperium.com/1-step-challenge/'),
    ('two-step-challenge', '2-step-challenge', 'https://citytradersimperium.com/2-step-challenge/')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, a.source_url, 'CTI current official offer and legacy alias review — 2026-10-01',
  'CTI official product page reviewed 2026-10-01. The current detailed record is ' || a.canonical_slug || '; CTI homepage lists a single current 1-Step and 2-Step challenge offer. This older row is preserved as archived history.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join aliases a on a.slug = p.slug
where f.slug = 'city-traders-imperium' and p.status = 'archived'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'CTI current official offer and legacy alias review — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T15:58:40Z'::timestamptz,
  'Compared this legacy challenge row with CTI current homepage and dedicated challenge page on 2026-10-01. The current numeric-slug offer is recorded in commercial_details; the duplicate is archived, retained and its destination disabled.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'city-traders-imperium'
  and p.slug in ('one-step-challenge', 'two-step-challenge') and p.status = 'archived'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Compared this legacy challenge row with CTI current homepage and dedicated challenge page on 2026-10-01.%');

commit;
