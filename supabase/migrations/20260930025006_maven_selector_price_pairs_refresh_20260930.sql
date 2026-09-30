-- Refresh current Maven selector price pairs captured 2026-09-30.
-- First amounts are explicitly coupon/current prices; comparison amounts are retained separately.
-- Checkout was not submitted. Do not treat these as guaranteed payable totals or permanent base fees.
set search_path = bullish_banana, extensions, public;

with selector(program_slug, prices, observations, note) as (
  values
  ('standard-1-step',
   '[{"account_size":2000,"fee":14,"list_fee":15,"currency":"USD"},{"account_size":5000,"fee":18,"list_fee":19,"currency":"USD"},{"account_size":10000,"fee":34,"list_fee":37,"currency":"USD"},{"account_size":20000,"fee":62,"list_fee":68,"currency":"USD"},{"account_size":50000,"fee":153,"list_fee":170,"currency":"USD"},{"account_size":100000,"fee":342,"list_fee":380,"currency":"USD"}]'::jsonb,
   '[{"account_size":2000,"displayed_price":14,"comparison_price":15,"label":"Price with coupon"},{"account_size":5000,"displayed_price":18,"comparison_price":19,"label":"Price with coupon"},{"account_size":10000,"displayed_price":34,"comparison_price":37,"label":"Price with coupon"},{"account_size":20000,"displayed_price":62,"comparison_price":68,"label":"Price with coupon"},{"account_size":50000,"displayed_price":153,"comparison_price":170,"label":"Price with coupon"},{"account_size":100000,"displayed_price":342,"comparison_price":380,"label":"Price with coupon"}]'::jsonb,
   'Selected Standard then 1 Step. Six size cards label the first amount Price with coupon; comparison amounts are preserved separately. Checkout not submitted.'),
  ('standard-2-step',
   '[{"account_size":2000,"fee":18,"list_fee":19,"currency":"USD"},{"account_size":5000,"fee":20,"list_fee":22,"currency":"USD"},{"account_size":10000,"fee":40,"list_fee":44,"currency":"USD"},{"account_size":20000,"fee":80,"list_fee":88,"currency":"USD"},{"account_size":50000,"fee":198,"list_fee":220,"currency":"USD"},{"account_size":100000,"fee":396,"list_fee":440,"currency":"USD"}]'::jsonb,
   '[{"account_size":2000,"displayed_price":18,"comparison_price":19,"label":"Price with coupon"},{"account_size":5000,"displayed_price":20,"comparison_price":22,"label":"Price with coupon"},{"account_size":10000,"displayed_price":40,"comparison_price":44,"label":"Price with coupon"},{"account_size":20000,"displayed_price":80,"comparison_price":88,"label":"Price with coupon"},{"account_size":50000,"displayed_price":198,"comparison_price":220,"label":"Price with coupon"},{"account_size":100000,"displayed_price":396,"comparison_price":440,"label":"Price with coupon"}]'::jsonb,
   'Selected Standard then 2 Step. Six size cards label the first amount Price with coupon; comparison amounts are preserved separately. Checkout not submitted.'),
  ('instant',
   '[{"account_size":2000,"fee":14,"list_fee":15,"currency":"USD"},{"account_size":5000,"fee":18,"list_fee":19,"currency":"USD"},{"account_size":10000,"fee":34,"list_fee":37,"currency":"USD"},{"account_size":20000,"fee":62,"list_fee":68,"currency":"USD"},{"account_size":50000,"fee":153,"list_fee":170,"currency":"USD"},{"account_size":100000,"fee":342,"list_fee":380,"currency":"USD"}]'::jsonb,
   '[{"account_size":2000,"displayed_price":14,"comparison_price":15,"label":"Price with coupon"},{"account_size":5000,"displayed_price":18,"comparison_price":19,"label":"Price with coupon"},{"account_size":10000,"displayed_price":34,"comparison_price":37,"label":"Price with coupon"},{"account_size":20000,"displayed_price":62,"comparison_price":68,"label":"Price with coupon"},{"account_size":50000,"displayed_price":153,"comparison_price":170,"label":"Price with coupon"},{"account_size":100000,"displayed_price":342,"comparison_price":380,"label":"Price with coupon"}]'::jsonb,
   'Selected Instant. Six size cards label the first amount Price with coupon; comparison amounts are preserved separately. Checkout not submitted.'),
  ('mini',
   '[{"account_size":2000,"fee":16,"list_fee":17,"currency":"USD"},{"account_size":5000,"fee":20,"list_fee":22,"currency":"USD"},{"account_size":10000,"fee":40,"list_fee":44,"currency":"USD"},{"account_size":20000,"fee":80,"list_fee":88,"currency":"USD"},{"account_size":50000,"fee":198,"list_fee":220,"currency":"USD"},{"account_size":100000,"fee":396,"list_fee":440,"currency":"USD"}]'::jsonb,
   '[{"account_size":2000,"displayed_price":16,"comparison_price":17,"label":"Price with coupon"},{"account_size":5000,"displayed_price":20,"comparison_price":22,"label":"Price with coupon"},{"account_size":10000,"displayed_price":40,"comparison_price":44,"label":"Price with coupon"},{"account_size":20000,"displayed_price":80,"comparison_price":88,"label":"Price with coupon"},{"account_size":50000,"displayed_price":198,"comparison_price":220,"label":"Price with coupon"},{"account_size":100000,"displayed_price":396,"comparison_price":440,"label":"Price with coupon"}]'::jsonb,
   'Selected Mini. The live 10K card shows $40/$44, correcting the earlier duplicate-card extraction of $34/$37. All six first amounts are labelled Price with coupon; checkout not submitted.'),
  ('omo-2-step',
   '[{"account_size":2000,"fee":9,"list_fee":19,"currency":"USD"},{"account_size":5000,"fee":15,"list_fee":32,"currency":"USD"},{"account_size":10000,"fee":38,"list_fee":62,"currency":"USD"},{"account_size":20000,"fee":74,"list_fee":122,"currency":"USD"},{"account_size":50000,"fee":143,"list_fee":238,"currency":"USD"},{"account_size":100000,"fee":284,"list_fee":472,"currency":"USD"}]'::jsonb,
   '[{"account_size":2000,"displayed_price":9,"comparison_price":19,"promo_text":"$10 OFF with code OMO"},{"account_size":5000,"displayed_price":15,"comparison_price":32,"promo_text":"$17 OFF with code OMO"},{"account_size":10000,"displayed_price":38,"comparison_price":62,"promo_text":"40% OFF with code OMO"},{"account_size":20000,"displayed_price":74,"comparison_price":122},{"account_size":50000,"displayed_price":143,"comparison_price":238},{"account_size":100000,"displayed_price":284,"comparison_price":472}]'::jsonb,
   'Selected Omo 2-Step. Preserve each displayed current/comparison pair and promo wording separately; the displayed values do not consistently calculate to the advertised percentage. Checkout not submitted.')
)
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', s.prices,
      'selector_price_observations_2026_09_30', s.observations,
      'price_configuration', 'The current Maven public selector shows a coupon/current amount and a comparison amount for each selected size. Values were captured 2026-09-30 without submitting checkout. Store them as dated observations; they do not establish a guaranteed final charge or permanent base price.',
      'selector_price_note_2026_09_30', s.note
    ),
    updated_at = now()
from bullish_banana.firms f, selector s
where p.firm_id = f.id and f.slug = 'maven-trading'
  and p.slug = s.program_slug;

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id, 'https://maventrading.com/pricing',
       'Maven current ' || p.name || ' selector price pairs — 2026-09-30',
       s.note || ' Price pair rows are stored in selector_price_observations_2026_09_30. The displayed promotion is volatile; final checkout price was not verified.',
       '2026-09-30 02:50:06+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('standard-1-step', 'Selected Standard → 1 Step. Captured all six current/comparison card pairs.'),
  ('standard-2-step', 'Selected Standard → 2 Step. Captured all six current/comparison card pairs.'),
  ('instant', 'Selected Instant. Captured all six current/comparison card pairs.'),
  ('mini', 'Selected Mini. Captured all six pairs; the 10K card is $40/$44, correcting the earlier duplicate-card extraction.'),
  ('omo-2-step', 'Selected Omo 2-Step. Captured all six pairs and preserved the promo wording shown on the applicable cards.')
) as s(program_slug, note) on s.program_slug = p.slug
where f.slug = 'maven-trading'
  and not exists (select 1 from bullish_banana.sources x where x.program_id = p.id and x.source_label = 'Maven current ' || p.name || ' selector price pairs — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30 02:50:06+00'::timestamptz,
       'Rechecked the current Maven public selector and all six card pairs on 2026-09-30. First amounts are coupon/current prices and comparison amounts are separately preserved. Checkout was not submitted; price observation does not prove final payable price.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading' and p.slug in ('standard-1-step','standard-2-step','instant','mini','omo-2-step')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30 02:50:06+00'::timestamptz);
