begin;
set search_path = bullish_banana, extensions, public;

-- The current Maven lineup and terms were rechecked on 2026-09-30. These older
-- in-review rows duplicate offers represented by the current canonical records.
with aliases(slug, canonical_slug, reason) as (
  values
    ('two-step-challenge', 'standard-2-step', 'Older generic two-step alias duplicates Maven Standard 2-Step.'),
    ('instant-funding', 'instant', 'Older instant-funding alias duplicates Maven Instant.'),
    ('omo-two-step', 'omo-2-step', 'Older OMO alias duplicates Maven Omo 2-Step.')
)
update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
      jsonb_build_object('superseded_by', a.canonical_slug, 'superseded_reason', a.reason,
        'superseded_reviewed_at', '2026-09-30',
        'superseded_source', 'https://maventrading.com/terms-and-conditions')
from bullish_banana.firms f, aliases a
where p.firm_id = f.id and f.slug = 'maven-trading' and p.slug = a.slug
  and p.status <> 'archived';

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'maven-trading'
  and p.slug in ('two-step-challenge', 'instant-funding', 'omo-two-step');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://maventrading.com/', 'Maven current offer lineup — alias review — 2026-09-30',
  'Current official homepage lineup exposes Standard 1-Step, Standard 2-Step, Standard 3-Step, Instant, Buy Now Pay Later, Omo 2-Step, and Mini. This older in-review record was retained as archived history and linked to its current canonical offer in commercial_details.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.slug in ('two-step-challenge', 'instant-funding', 'omo-two-step')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'Maven current offer lineup — alias review — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T15:00:00Z'::timestamptz,
  'Compared the legacy in-review Maven row to the current official homepage lineup and terms on 2026-09-30. It duplicates the named canonical offer listed in commercial_details and was archived without deleting its record.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.slug in ('two-step-challenge', 'instant-funding', 'omo-two-step')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-09-30T15:00:00Z'::timestamptz);

commit;
