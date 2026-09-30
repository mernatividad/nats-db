-- Tradeify FX Help Center restriction list, verified 2026-09-30.
-- Restrictions are based on permanent country of residence. The list contains
-- 31 country codes plus Crimea, which is represented in the Ukraine note.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || jsonb_build_object(
      'jurisdiction_notes', 'Eligibility is based on permanent country of residence, not citizenship or temporary location. Tradeify FX states residents of these 32 countries and regions cannot purchase or use accounts: Afghanistan, Belarus, Belgium, Burma (Myanmar), Cambodia, Central African Republic, Crimea, Cuba, Democratic Republic of Congo, Eritrea, Ethiopia, Haiti, Iran, Iraq, Israel, Lebanon, Libya, Morocco, Nicaragua, North Korea, Russia, Somalia, South Sudan, Sudan, Syria, Taiwan, Ukraine, United States, Venezuela, Vietnam, Yemen, and Zimbabwe. The Terms separately say services are unavailable to both U.S. residents and users located in the United States. The firm says the country list is periodically reviewed and may change.',
      'jurisdictions', 'As of 2026-09-30, residents of Afghanistan, Belarus, Belgium, Burma (Myanmar), Cambodia, Central African Republic, Crimea, Cuba, Democratic Republic of Congo, Eritrea, Ethiopia, Haiti, Iran, Iraq, Israel, Lebanon, Libya, Morocco, Nicaragua, North Korea, Russia, Somalia, South Sudan, Sudan, Syria, Taiwan, Ukraine, United States, Venezuela, Vietnam, Yemen, and Zimbabwe are restricted. Restrictions are residency-based; the company may update the list. Terms separately restrict both U.S. residents and people located in the United States.',
      'restricted_jurisdictions', jsonb_build_array(
        'Afghanistan','Belarus','Belgium','Burma (Myanmar)','Cambodia','Central African Republic','Crimea','Cuba',
        'Democratic Republic of Congo','Eritrea','Ethiopia','Haiti','Iran','Iraq','Israel','Lebanon','Libya','Morocco',
        'Nicaragua','North Korea','Russia','Somalia','South Sudan','Sudan','Syria','Taiwan','Ukraine','United States',
        'Venezuela','Vietnam','Yemen','Zimbabwe'
      ),
      'restrictions_verified_at', '2026-09-30',
      'restriction_source', 'https://help.tradeifyfx.co/en/articles/16976515-restricted-countries'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id
  and f.slug = 'tradeify-fx';

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select f.id, r.country_code, 'restricted',
       r.country_name || ' is listed as unavailable based on country of permanent residence in the official Tradeify FX restricted-countries article, reviewed 2026-09-30. The article separately names Crimea; this row covers Ukraine and notes Crimea in the country name.'
       || case when r.country_code = 'US' then ' The Terms also restrict users located in the United States.' else '' end
from bullish_banana.firms f
join (values
  ('AF','Afghanistan'), ('BY','Belarus'), ('BE','Belgium'), ('MM','Burma (Myanmar)'),
  ('KH','Cambodia'), ('CF','Central African Republic'), ('CU','Cuba'), ('CD','Democratic Republic of Congo'),
  ('ER','Eritrea'), ('ET','Ethiopia'), ('HT','Haiti'), ('IR','Iran'), ('IQ','Iraq'), ('IL','Israel'),
  ('LB','Lebanon'), ('LY','Libya'), ('MA','Morocco'), ('NI','Nicaragua'), ('KP','North Korea'), ('RU','Russia'),
  ('SO','Somalia'), ('SS','South Sudan'), ('SD','Sudan'), ('SY','Syria'), ('TW','Taiwan'),
  ('UA','Ukraine and Crimea'), ('US','United States'), ('VE','Venezuela'), ('VN','Vietnam'), ('YE','Yemen'), ('ZW','Zimbabwe')
) as r(country_code, country_name) on true
where f.slug = 'tradeify-fx'
on conflict (firm_id, country_code) do update
set restriction_type = excluded.restriction_type,
    note = excluded.note,
    updated_at = now();

update bullish_banana.sources s
set notes = 'Official Tradeify FX Restricted countries article, reviewed 2026-09-30. Lists 32 countries and regions unavailable for purchase or use; restrictions are based on permanent country of residence and may change. Crimea is separately named in addition to Ukraine.'
from bullish_banana.firms f
where s.firm_id = f.id
  and s.source_url = 'https://help.tradeifyfx.co/en/articles/16976515-restricted-countries'
  and f.slug = 'tradeify-fx';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
       'https://help.tradeifyfx.co/en/articles/16976515-restricted-countries',
       'Tradeify FX restricted countries and residency rules',
       'Official Help Center article reviewed 2026-09-30. Lists 32 countries and regions unavailable for purchase or use; restrictions are based on permanent country of residence, not citizenship or temporary location. Crimea is separately named in addition to Ukraine; list may change.'
from bullish_banana.firms f
where f.slug = 'tradeify-fx'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://help.tradeifyfx.co/en/articles/16976515-restricted-countries'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://help.tradeifyfx.co/en/articles/16976515-restricted-countries',
       'Tradeify FX residency eligibility',
       'Firm-wide program eligibility: the current official Help Center list restricts 32 countries and regions based on permanent country of residence. Reviewed 2026-09-30; see profile for full list and note that it may change.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'tradeify-fx'
  and p.slug in ('daily-1-step', 'classic-2-step', 'direct-instant-funding')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://help.tradeifyfx.co/en/articles/16976515-restricted-countries'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Verified the official Tradeify FX restricted-countries article on 2026-09-30. It lists 32 countries/regions unavailable by permanent residence, separately names Crimea, and states the list may change. Added readable profile details and structured country restrictions.'
from bullish_banana.firms f
where f.slug = 'tradeify-fx';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Verified firm-wide Tradeify FX country eligibility on 2026-09-30 against the official restricted-countries Help Center article. Eligibility is based on permanent residence; 32 countries/regions are listed.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'tradeify-fx'
  and p.slug in ('daily-1-step', 'classic-2-step', 'direct-instant-funding');
