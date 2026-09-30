begin;
set search_path = bullish_banana, extensions, public;

-- The individual Maven Buy Now, Pay Later and OMO product URLs return 404,
-- while the live first-party pricing selector still renders purchasable
-- variants for those plans. Record the current pricing selector as the source
-- of truth for their offer presence and platform crosswalk.
insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join bullish_banana.platforms pl on pl.slug = 'metatrader-5'
where f.slug = 'maven-trading'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug = 'buy-now-pay-later'
on conflict do nothing;

insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join bullish_banana.platforms pl on pl.slug in ('metatrader-5', 'match-trade')
where f.slug = 'maven-trading'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug = 'omo-2-step'
on conflict do nothing;

with target_programs as (
  select p.id, p.slug
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'maven-trading'
    and p.market_type = 'forex'
    and p.status = 'in_review'
    and p.slug in (
      'instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step',
      'buy-now-pay-later', 'omo-2-step'
    )
),
page_map as (
  select * from (values
    ('instant', 'Instant'),
    ('mini', 'Mini'),
    ('standard-1-step', 'Standard 1-Step'),
    ('standard-2-step', 'Standard 2-Step'),
    ('standard-3-step', 'Standard 3-Step'),
    ('buy-now-pay-later', 'Buy Now, Pay Later'),
    ('omo-2-step', 'OMO 2-Step')
  ) as pages(program_slug, program_name)
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://maventrading.com/pricing',
  'Maven live pricing selector — ' || pages.program_name || ' variants, reviewed 2026-10-01',
  case p.slug
    when 'buy-now-pay-later' then 'The live first-party pricing selector currently renders this plan with six account sizes ($2K, $5K, $10K, $20K, $50K, and $100K), one MetaTrader 5 variant per size, and separate pay-now/pay-later prices. The individual challenge URL returns 404. The region-restriction element exists in the card markup but computed display is none in this review session; country eligibility remains unknown.'
    when 'omo-2-step' then 'The live first-party pricing selector currently renders this plan with six account sizes ($2K, $5K, $10K, $20K, $50K, and $100K), MetaTrader 5 and Match Trade variants per size, and the OMO discount. The guessed individual challenge URL returns 404. The region-restriction element exists in the card markup but computed display is none in this review session; country eligibility remains unknown.'
    else 'The live first-party pricing selector currently renders this plan with six account sizes ($2K, $5K, $10K, $20K, $50K, and $100K) and platform-specific variants. Its region-restriction element exists in the card markup but computed display is none in this review session; country eligibility remains unknown.'
  end
from target_programs p
join page_map pages on pages.program_slug = p.slug
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id
    and s.source_url = 'https://maventrading.com/pricing'
    and s.source_label = 'Maven live pricing selector — ' || pages.program_name || ' variants, reviewed 2026-10-01'
);

-- Correct the prior note: the restriction layer is present in the DOM but is
-- hidden by CSS in this browser session; it was not visibly displayed.
update bullish_banana.sources s
set notes = replace(
  s.notes,
  'The Match Trade cards display a "not available in your region" overlay in this review session; availability is region-dependent and the affected platform must not be recommended until the supported region is verified.',
  'The cards include a regional restriction layer, but its computed display is none in this review session. The layer does not establish actual country availability; supported regions remain unverified.'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'maven-trading'
  and p.slug in ('instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step')
  and s.source_label like 'Maven % live platform variants — reviewed 2026-10-01';

update bullish_banana.data_verifications v
set notes = 'Rechecked the current official Maven product page on 2026-10-01. Its live card data maps all six sizes to MetaTrader 5 and Match Trade variants. A regional restriction layer is present in the card markup but computed display is none in this review session; that layer does not establish actual country availability, so supported regions remain unverified. The program remains in review pending full offer and regional verification.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where v.program_id = p.id
  and f.slug = 'maven-trading'
  and p.slug in ('instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step')
  and v.verified_at = '2026-09-30T20:01:00+00:00'::timestamptz
  and v.notes like 'Rechecked the current official Maven product page%';

with target_programs as (
  select p.id, p.slug
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'maven-trading'
    and p.market_type = 'forex'
    and p.status = 'in_review'
    and p.slug in ('buy-now-pay-later', 'omo-2-step')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T20:06:00+00:00'::timestamptz,
  case p.slug
    when 'buy-now-pay-later' then 'Reviewed the current Maven pricing selector on 2026-10-01. It renders Buy Now, Pay Later with six sizes and MetaTrader 5 variants; the guessed dedicated challenge path returns 404. Its regional restriction layer is hidden (computed display none) in this browser session, so country availability remains unknown. Kept in review pending full offer and regional verification.'
    else 'Reviewed the current Maven pricing selector on 2026-10-01. It renders OMO 2-Step with six sizes and both MetaTrader 5 and Match Trade variants; the guessed dedicated challenge path returns 404. Its regional restriction layer is hidden (computed display none) in this browser session, so country availability remains unknown. Kept in review pending full offer and regional verification.'
  end
from target_programs p
where not exists (
  select 1 from bullish_banana.data_verifications v
  where v.program_id = p.id
    and v.verified_at = '2026-09-30T20:06:00+00:00'::timestamptz
);

update bullish_banana.programs p
set commercial_details = jsonb_set(
      jsonb_set(
        p.commercial_details,
        '{review_note}',
        to_jsonb(case p.slug
          when 'buy-now-pay-later' then 'The current official pricing selector exposes six Buy Now, Pay Later sizes with MetaTrader 5 variants. Its dedicated challenge URL returns 404. Country eligibility is not established by the hidden restriction layer in the selector.'
          when 'omo-2-step' then 'The current official pricing selector exposes six OMO 2-Step sizes with MetaTrader 5 and Match Trade variants. Its dedicated challenge URL returns 404. Country eligibility is not established by the hidden restriction layer in the selector.'
          else 'The current official product page exposes MetaTrader 5 and Match Trade variants for the listed account sizes. The card markup contains a regional restriction layer, but it is hidden in this review session; supported-region eligibility remains unknown.'
        end::text),
        true
      ),
      '{platform_availability_note}',
      to_jsonb('Official product variant data identifies these platforms and sizes, but country eligibility remains unverified; the page contains a hidden regional restriction layer.'::text),
      true
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'maven-trading'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug in (
    'instant', 'mini', 'standard-1-step', 'standard-2-step', 'standard-3-step',
    'buy-now-pay-later', 'omo-2-step'
  );

commit;
