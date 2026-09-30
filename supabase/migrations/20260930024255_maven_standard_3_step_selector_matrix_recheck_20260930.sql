-- Refresh Maven's full Standard 3-Step card matrix, including the previously
-- unverified $100K tier. The first number is visibly labelled "Price with
-- coupon"; preserve comparison amounts rather than claiming checkout totals.
update bullish_banana.programs p
set account_sizes = '[2000,5000,10000,20000,50000,100000]'::jsonb,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', '[
        {"account_size":2000,"fee":12,"list_fee":13,"currency":"USD"},
        {"account_size":5000,"fee":16,"list_fee":17,"currency":"USD"},
        {"account_size":10000,"fee":35,"list_fee":38,"currency":"USD"},
        {"account_size":20000,"fee":69,"list_fee":76,"currency":"USD"},
        {"account_size":50000,"fee":171,"list_fee":190,"currency":"USD"},
        {"account_size":100000,"fee":270,"list_fee":299,"currency":"USD"}
      ]'::jsonb,
      'selector_price_observations_2026_09_30', '[
        {"account_size":2000,"displayed_price":12,"comparison_price":13,"currency":"USD","label":"Price with coupon"},
        {"account_size":5000,"displayed_price":16,"comparison_price":17,"currency":"USD","label":"Price with coupon"},
        {"account_size":10000,"displayed_price":35,"comparison_price":38,"currency":"USD","label":"Price with coupon"},
        {"account_size":20000,"displayed_price":69,"comparison_price":76,"currency":"USD","label":"Price with coupon"},
        {"account_size":50000,"displayed_price":171,"comparison_price":190,"currency":"USD","label":"Price with coupon"},
        {"account_size":100000,"displayed_price":270,"comparison_price":299,"currency":"USD","label":"Price with coupon"}
      ]'::jsonb,
      'price_configuration', 'The current Standard 3-Step pricing selector displays two amounts per size and labels the lower amount “Price with coupon.” Values were captured without submitting checkout. Store the first displayed amounts as current observations with comparison prices separately; do not treat either as a guaranteed checkout charge or permanent base fee.',
      'selector_rule_recheck_2026_09_30', 'On every selected Standard 3-Step size card the pricing selector shows 3% target in each of three phases, 3% maximum loss, 2% daily loss, 80% profit split, no consistency score, and 10-business-day funded payout frequency. The page identifies the cards as current offers; account-specific checkout availability and final charge were not verified.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'maven-trading'
  and p.slug = 'standard-3-step';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://maventrading.com/pricing',
       'Maven current Standard 3-Step selector matrix — 2026-09-30',
       'Selected Standard then Standard 3-Step in the public pricing selector. All six current account cards were captured: $2K ($12 coupon-labelled / $13 comparison), $5K ($16/$17), $10K ($35/$38), $20K ($69/$76), $50K ($171/$190), and $100K ($270/$299). The cards label the first amount “Price with coupon.” All six show 3% target per phase across three phases, 3% maximum loss, 2% daily loss, 80% funded split, no consistency score, and a 10-business-day payout frequency. Checkout was not submitted, so final payable amounts and long-term base fees are not asserted.',
       '2026-09-30 02:42:55+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.slug = 'standard-3-step'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://maventrading.com/pricing'
      and s.source_label = 'Maven current Standard 3-Step selector matrix — 2026-09-30'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 02:42:55+00'::timestamptz,
       'Rechecked all six current Maven Standard 3-Step public selector cards on 2026-09-30. The previously unverified $100K card shows $270 with coupon / $299 comparison. All selected size cards display 3% targets in each phase, 3% max loss, 2% daily loss, 80% split, no consistency score and 10-business-day funded payouts. Checkout not submitted. Preserve the program publication status from the base catalog migration; price observations are coupon-labelled, not guaranteed checkout charges.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.slug = 'standard-3-step'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30 02:42:55+00'::timestamptz
      and v.notes like 'Rechecked all six current Maven Standard 3-Step public selector cards on 2026-09-30%'
  );
