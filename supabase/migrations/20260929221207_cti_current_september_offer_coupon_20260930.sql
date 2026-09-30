-- Capture the time-limited discount currently shown on CTI's official offer page.
-- This is a promotion observation, not a replacement for base fee schedules.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'promotion_observation_2026_09_30', jsonb_build_object(
    'code', 'SINCE2018',
    'discount_percent', 15,
    'applies_to_page_listed_programs', jsonb_build_array('1-Step Challenge','2-Step Challenge','Instant Funding'),
    'valid_through', '2026-09-30',
    'terms', 'The official CTI page says terms apply but does not expose their details in the page banner.',
    'checkout_price_verified', false,
    'source_url', 'https://citytradersimperium.com/1-step-challenge/',
    'captured_on', '2026-09-30',
    'note', 'Dated discount only. Do not fold into the base account_size_prices or assume eligibility after expiry; verify code and final checkout total before presenting as available.'
  )
),
updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'city-traders-imperium'
  and p.slug in ('1-step-challenge','2-step-challenge','instant-funding');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes, captured_at)
select f.id,
       'https://citytradersimperium.com/1-step-challenge/',
       'CTI September 2026 offer code — homepage banner',
       'Official CTI offer page observed 2026-09-30 displayed a 15% discount for 1-Step, 2-Step, and Instant Funding with code SINCE2018, valid through 2026-09-30, with terms applying. This is a dated promotion and no final checkout price was verified.',
       '2026-09-29 22:12:07+00'::timestamptz
from bullish_banana.firms f
where f.slug = 'city-traders-imperium'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://citytradersimperium.com/1-step-challenge/' and s.source_label = 'CTI September 2026 offer code — homepage banner');

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://citytradersimperium.com/1-step-challenge/',
       'CTI September 2026 offer code',
       'The CTI page-wide banner included this program in a 15% offer using code SINCE2018 through 2026-09-30. Terms apply; the checkout amount was not verified. Keep the offer separate from the base price schedule.',
       '2026-09-29 22:12:07+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'city-traders-imperium'
where p.slug in ('1-step-challenge','2-step-challenge','instant-funding')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://citytradersimperium.com/1-step-challenge/' and s.source_label = 'CTI September 2026 offer code');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-29 22:12:07+00'::timestamptz,
       'Rechecked CTI official 1-Step page on 2026-09-30. Current base-price table lists $2.5K/$29, $5K/$49, $10K/$79, $25K/$159, $50K/$299, and $100K/$449. The page also showed code SINCE2018 for 15% off 1-Step, 2-Step, and Instant Funding through 2026-09-30, terms apply. Kept this dated offer separate from base fees; final checkout price not verified. The differing editorial 1-Step prices remain documented for review.'
from bullish_banana.firms f
where f.slug = 'city-traders-imperium'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-29 22:12:07+00'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-29 22:12:07+00'::timestamptz,
       case p.slug
         when '1-step-challenge' then 'Rechecked official CTI 1-Step page 2026-09-30: displayed current price matrix $2.5K/$29, $5K/$49, $10K/$79, $25K/$159, $50K/$299, $100K/$449, plus 15% code SINCE2018 through 2026-09-30. Final checkout price was not verified. Editorial prices differ; retain the mismatch for review. Program remains in_review.'
         else 'Rechecked official CTI 1-Step page 2026-09-30; its banner included this product in a 15% code SINCE2018 offer through 2026-09-30. Terms apply; final checkout price was not verified. Promotion is separate from base fees. Program remains in_review.'
       end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'city-traders-imperium'
where p.slug in ('1-step-challenge','2-step-challenge','instant-funding')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-29 22:12:07+00'::timestamptz);
