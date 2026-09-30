begin;
set search_path = bullish_banana, extensions, public;

-- Current first-party product cards expose these two platform variants for
-- Maven's Instant, Mini, and Standard 1/2/3-Step offers. The Match Trade cards
-- carry a regional availability overlay, so keep all five programs in review
-- until the catalog can express and verify supported regions.
insert into bullish_banana.platforms (name, slug)
values ('MetaTrader 5', 'metatrader-5'), ('Match Trade', 'match-trade')
on conflict (slug) do nothing;

with target_programs as (
  select p.id, p.slug
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'maven-trading'
    and p.market_type = 'forex'
    and p.status = 'in_review'
    and p.slug in ('instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step')
),
target_platforms as (
  select id, slug from bullish_banana.platforms
  where slug in ('metatrader-5', 'match-trade')
)
insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from target_programs p
cross join target_platforms pl
on conflict do nothing;

with target_programs as (
  select p.id, p.slug
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'maven-trading'
    and p.market_type = 'forex'
    and p.status = 'in_review'
    and p.slug in ('instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step')
),
page_map as (
  select * from (values
    ('instant', 'https://maventrading.com/challenges/instant', 'Instant'),
    ('mini', 'https://maventrading.com/challenges/mini', 'Mini'),
    ('standard-1-step', 'https://maventrading.com/challenges/1-step', 'Standard 1-Step'),
    ('standard-2-step', 'https://maventrading.com/challenges/2-step', 'Standard 2-Step'),
    ('standard-3-step', 'https://maventrading.com/challenges/3-step', 'Standard 3-Step')
  ) as pages(program_slug, source_url, program_name)
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  pages.source_url,
  'Maven ' || pages.program_name || ' live platform variants — reviewed 2026-10-01',
  'The current first-party product page renders six account-size variants ($2K, $5K, $10K, $20K, $50K, and $100K), each with MetaTrader 5 and Match Trade platform-specific product variants. The Match Trade cards display a "not available in your region" overlay in this review session; availability is region-dependent and the affected platform must not be recommended until the supported region is verified.'
from target_programs p
join page_map pages on pages.program_slug = p.slug
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id and s.source_url = pages.source_url
    and s.source_label = 'Maven ' || pages.program_name || ' live platform variants — reviewed 2026-10-01'
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
  '2026-09-30T20:01:00+00:00'::timestamptz,
  'Rechecked the current official Maven product page on 2026-10-01. Its live card data maps all six sizes to MetaTrader 5 and Match Trade variants. The Match Trade variants also show a regional unavailability overlay in this review session, so the mapping is recorded with that restriction and the program remains in review pending supported-region verification.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug in ('instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30T20:01:00+00:00'::timestamptz
      and v.notes like 'Rechecked the current official Maven product page%'
  );

update bullish_banana.programs p
set commercial_details = jsonb_set(
      jsonb_set(
        p.commercial_details,
        '{review_note}',
        to_jsonb('The current official product page exposes MetaTrader 5 and Match Trade variants for the listed account sizes. Match Trade variants show a regional unavailability overlay in this review session; confirm supported regions before recommending that platform.'::text),
        true
      ),
      '{platform_availability_note}',
      to_jsonb('Match Trade option is region-gated in this review session; supported regions have not been verified.'::text),
      true
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'maven-trading'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug in ('instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step');

commit;
