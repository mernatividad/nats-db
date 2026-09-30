-- Recheck Goat Funded Trader Help Center restrictions/platforms/commissions.
-- Keep offer-specific availability unknown where the current FAQ is firm-wide.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles
set profile_details = profile_details || jsonb_build_object(
  'platforms', jsonb_build_array('cTrader','TradeLocker','MatchTrader','Volumetrica','MetaTrader 5'),
  'jurisdiction_notes', 'Restricted from signup/trading per official FAQ dated 2026-07-27 (rechecked 2026-09-30): Afghanistan, Belarus, Central African Republic, Chile, Cuba, Democratic Republic of the Congo, Hong Kong, Iran, Israel, Jordan, Lebanon, Libya, Mali, Myanmar, North Korea, Russia, Senegal, Singapore, Somalia, South Korea, South Sudan, Sudan, Syria, Togo, Venezuela, Yemen, Zimbabwe. The same source also names Islamic State in Iraq and the Levant and Al-Qaida. Recheck the live source before purchase; this dated capture may change.',
  'eligibility_reviewed_on', '2026-09-30',
  'restricted_countries', jsonb_build_array(
    'Afghanistan','Belarus','Central African Republic','Chile','Cuba','Democratic Republic of the Congo','Hong Kong','Iran','Israel','Jordan','Lebanon','Libya','Mali','Myanmar','North Korea','Russia','Senegal','Singapore','Somalia','South Korea','South Sudan','Sudan','Syria','Togo','Venezuela','Yemen','Zimbabwe'
  ),
  'restricted_non_country_entities', jsonb_build_array('Islamic State in Iraq and the Levant','Al-Qaida'),
  'restriction_source_date', '2026-07-27',
  'eligibility_note', 'The official Help Center says these countries are currently restricted from signing up and trading. Rechecked 2026-09-30; confirm the live eligibility page before use because restrictions may change.',
  'platform_availability_reviewed_on', '2026-09-30',
  'platform_availability_note', 'Official Help Center list: cTrader, TradeLocker, MatchTrader, Volumetrica, and MT5. MT5 and cTrader are unavailable to clients located in the USA; TradeLocker, MatchTrader, and Volumetrica are available to US traders. One platform change may be requested if no trades have been placed. The firm-wide FAQ does not map each platform to every model, size, or region; verify the selected offer at checkout.',
  'commission_note', 'Official commission FAQ lists $5/lot for FX pairs and metals and $0/lot for crypto, indices, commodities, and stocks on MT5, Match-Trade, and TradeLocker (source terminology: Match-Trade). It does not state commission rates for cTrader or Volumetrica, nor a per-model/size exception matrix. Verify the platform and commission in the selected offer.'
),
updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'goat-funded-trader');

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
  'platforms_and_region', jsonb_build_object(
    'firm_wide_platforms', jsonb_build_array('cTrader','TradeLocker','MatchTrader','Volumetrica','MetaTrader 5'),
    'unavailable_to_us_clients', jsonb_build_array('cTrader','MetaTrader 5'),
    'available_to_us_clients', jsonb_build_array('TradeLocker','MatchTrader','Volumetrica'),
    'model_size_mapping', 'Not stated in the firm-wide Help Center article; platform choices shown by the offer selector must be confirmed for the selected model, size, and region.',
    'change_policy', 'One platform change may be requested if no trades have been placed; regional availability restrictions still apply.',
    'reviewed_on', '2026-09-30'
  ),
  'commission_details', 'Official Help Center commission article states that MT5, Match-Trade (article wording), and TradeLocker use $5 per lot for FX pairs and metals, and $0 per lot for cryptocurrencies, indices, commodities, and stocks, with raw spreads on all assets. It does not specify commission rates for cTrader or Volumetrica, or map commissions by model, size, or account phase. Confirm the selected platform/offer at checkout.'
),
updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'goat-funded-trader'
  and p.slug in ('1-step-goat','2-step-goat','2-step-standard','instant-hero','instant-goat','instant-premium');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes, captured_at)
select f.id, s.url, s.label, s.notes, '2026-09-29 22:15:52+00'::timestamptz
from bullish_banana.firms f
join (values
  ('https://help.goatfundedtrader.com/en/articles/10742187-which-countries-are-restricted-at-goat-funded-trader','Restricted countries and jurisdictions','Official Help Center article dated 2026-07-27, rechecked 2026-09-30. Lists countries restricted from signing up and trading, plus Islamic State in Iraq and the Levant and Al-Qaida; says restricted persons cannot create an account or use the platform.'),
  ('https://help.goatfundedtrader.com/en/articles/10741900-which-platforms-can-i-trade-on','Trading platform availability','Official Help Center article dated 2026-08-13, rechecked 2026-09-30. Lists cTrader, TradeLocker, MatchTrader, Volumetrica and MT5; MT5 and cTrader unavailable to US clients, while the other three are available in the US. One platform change is allowed before any trade. It does not identify the platform matrix by model or size.'),
  ('https://help.goatfundedtrader.com/en/articles/10742044-how-does-the-commission-work-for-different-trading-instruments','Commission by platform and instrument','Official Help Center article dated 2026-07-27, rechecked 2026-09-30. States $5/lot on FX pairs and metals and $0/lot on crypto, indices, commodities, and stocks for MT5, Match-Trade (as written in source), and TradeLocker. Does not state rates for cTrader/Volumetrica or model-specific exceptions.')
) as s(url,label,notes) on true
where f.slug = 'goat-funded-trader'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = f.id and existing.source_url = s.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id, s.url, s.label, s.notes, '2026-09-29 22:15:52+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'goat-funded-trader'
cross join (values
  ('https://help.goatfundedtrader.com/en/articles/10741900-which-platforms-can-i-trade-on','Firm-wide platform availability','Help Center lists five platforms and US location limits but does not map platform support by model/size. Verify the selected model and location in checkout.'),
  ('https://help.goatfundedtrader.com/en/articles/10742044-how-does-the-commission-work-for-different-trading-instruments','Commission by platform and instrument','Help Center states rates for MT5, Match-Trade (source wording), and TradeLocker only. cTrader and Volumetrica rates and offer-specific commission rules are not stated.')
) as s(url,label,notes)
where p.slug in ('1-step-goat','2-step-goat','2-step-standard','instant-hero','instant-goat','instant-premium')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = p.id and existing.source_url = s.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-29 22:15:52+00'::timestamptz,
  'Rechecked official Goat Funded Trader Help Center restrictions, platform, and commission articles on 2026-09-30. Captured current dated country/person restrictions, US platform limits, and instrument commissions for MT5, Match-Trade (source wording), and TradeLocker. Model/size platform mapping and cTrader/Volumetrica commissions remain not stated; retain existing publication status.'
from bullish_banana.firms f
where f.slug = 'goat-funded-trader'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-29 22:15:52+00'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-29 22:15:52+00'::timestamptz,
  'Rechecked official Help Center restriction/platform/commission guidance on 2026-09-30. Added firm-wide platform and US availability, and the cited commission schedule with explicit platform scope. The Help Center does not state model/size-specific platform availability, cTrader/Volumetrica commissions, or model/phase fee exceptions; confirm current selection at checkout.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'goat-funded-trader'
where p.slug in ('1-step-goat','2-step-goat','2-step-standard','instant-hero','instant-goat','instant-premium')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-29 22:15:52+00'::timestamptz);
