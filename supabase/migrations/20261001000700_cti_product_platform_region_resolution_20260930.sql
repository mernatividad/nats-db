-- Confirm CTI's current per-offer platform choices and surface the regional
-- differences in the program detail/comparison field consumed by the app.
-- All four programs remain in_review for unrelated price and terms gaps.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platforms_and_region', 'The official product page for this offer lists MetaTrader 5 and Match-Trader. CTI says MT5 is available in most countries but not to U.S. clients; Match-Trader is available worldwide, including the U.S. Confirm the platform offered for your location in the current checkout. MT5 Expert Advisors do not run on Match-Trader.',
      'platform_availability', 'Both MetaTrader 5 and Match-Trader are listed on this offer''s official product page. MT5 is unavailable to U.S. clients; Match-Trader is stated to be available worldwide including the U.S. Verify local eligibility in checkout.',
      'platforms_checked_at', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'city-traders-imperium'
  and p.slug in ('1-step-challenge', '2-step-challenge', 'instant-funding', 'direct-funding');

update bullish_banana.sources s
set notes = concat_ws(' ', nullif(s.notes, ''),
      'Rechecked 2026-09-30: this product page lists both MetaTrader 5 and Match-Trader for the offer. Regional availability is described separately by CTI''s platform pages; MT5 is not offered to U.S. clients, while Match-Trader is stated to be available worldwide including the U.S. Confirm current local selection in checkout.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'city-traders-imperium'
  and (
    (p.slug = '1-step-challenge' and s.source_url = 'https://citytradersimperium.com/1-step-challenge/')
    or (p.slug = '2-step-challenge' and s.source_url = 'https://citytradersimperium.com/2-step-challenge/')
    or (p.slug = 'instant-funding' and s.source_url = 'https://citytradersimperium.com/instant-funding/')
    or (p.slug = 'direct-funding' and s.source_url = 'https://citytradersimperium.com/direct-funding/')
  )
  and s.notes not like '%Rechecked 2026-09-30: this product page lists both MetaTrader 5 and Match-Trader for the offer.%';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       timestamptz '2026-09-30 00:00:00+00',
       'Official product page rechecked 2026-09-30 and lists MetaTrader 5 and Match-Trader for this offer. CTI platform pages state MT5 is available in most countries but not in the U.S.; Match-Trader is available worldwide including the U.S. Confirm market eligibility in checkout. Existing program/platform associations are supported; program remains in_review for unrelated price and terms gaps.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'city-traders-imperium'
  and p.slug in ('1-step-challenge', '2-step-challenge', 'instant-funding', 'direct-funding')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like '%Official product page rechecked 2026-09-30 and lists MetaTrader 5 and Match-Trader for this offer.%'
  );
