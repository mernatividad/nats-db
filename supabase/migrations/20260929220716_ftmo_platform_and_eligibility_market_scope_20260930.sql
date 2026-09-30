-- Record FTMO platform and client-eligibility facts without conflating its
-- Global and US-affiliate offers. Current official-source review: 2026-09-30.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles
set profile_details = profile_details || jsonb_build_object(
  'eligibility_by_program_market', jsonb_build_object(
    'non_us_ftmo_global', jsonb_build_object(
      'minimum_age', 18,
      'restricted_countries_and_regions', jsonb_build_array(
        'Afghanistan','Anguilla','Antarctica','Antigua and Barbuda','Belarus','Belize','Bhutan','Bouvet Island','Burundi','Cape Verde','Central African Republic','Chad','Cook Islands','Comoros','Republic of the Congo','Cuba','Djibouti','Dominica','Equatorial Guinea','Eritrea','Eswatini','Fiji','Gabon','Gambia','Grenada','Guinea','Guinea-Bissau','Holy See (Vatican City State)','Indonesia','Iraq','Kazakhstan','Kiribati','Kosovo','Kyrgyzstan','Lesotho','Liberia','Malawi','Mali','Mauritania','Marshall Islands','Micronesia','Nauru','Niger','Niue','Papua New Guinea','Russian Federation','Saint Barthélemy','Saint Kitts and Nevis','Saint Lucia','Saint Vincent and the Grenadines','Samoa','San Marino','Sao Tome and Principe','Seychelles','Sierra Leone','Solomon Islands','Somalia','South Sudan','Sudan','Suriname','Tajikistan','Timor-Leste','Tokelau','Tonga','Turkmenistan','Tuvalu','Ukraine (Crimea, Sevastopol, Donetsk, Kherson, Luhansk, Zaporizhzhia)','Uzbekistan','Vanuatu','Venezuela','Western Sahara'
      ),
      'restricted_person_categories', jsonb_build_array('Nationals or residents of Iran, Syria, Myanmar, or North Korea','Individuals on international sanctions lists','Individuals with a financial-crime or terrorism criminal record','Persons previously banned for contract breach','Corporate clients structured as company trusts'),
      'conditional_exception', 'Nationals of Iran, Syria, or Myanmar may be accepted only with verified residency in an EEA country and a verified traditional bank account in their own name at an EEA bank.',
      'united_states', 'Use the separate FTMO US affiliate offer; Global country availability is not the applicable US eligibility rule.',
      'australia', 'FTMO directs Australian clients to its affiliated Australian service; verify the current offer and terms there.'
    ),
    'us_ftmo_affiliate', jsonb_build_object(
      'available_to', 'Individuals legally resident in the United States or legal entities incorporated in the United States with an authorised representative.',
      'minimum_age', 18,
      'territory_scope', 'The United States includes all 50 states and American Samoa, Guam, Northern Mariana Islands, Puerto Rico, United States Minor Outlying Islands, and the U.S. Virgin Islands.',
      'excluded_entity_states', jsonb_build_array('Arkansas','Delaware','Louisiana','Montana','South Carolina'),
      'payout_requirements', 'US residents need a valid US Tax Identification Number; a licensed and regulated US bank account may be requested; W-9 is required before the first Reward.',
      'restricted_person_categories', jsonb_build_array('Individuals or entities on sanctions lists','Individuals or entities with a financial-crime or terrorism criminal record','Persons previously banned for contract breach','Company trusts and non-profit organisations'),
      'operator_scope', 'JV Prop Corporation provides the Evaluation Process; OANDA Prop US Corporation provides the FTMO Rewards Account. These roles are separate.'
    )
  ),
  'eligibility_reviewed_on', '2026-09-30',
  'eligibility_scope_note', 'Country and entity restrictions differ between FTMO Global and the US affiliate. Follow the current official eligibility page for the selected program market and checkout; this captured list is a dated reference, not a substitute for live eligibility checks.'
),
updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'ftmo');

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'platform_availability_by_market', jsonb_build_object(
    'non_us_ftmo_global', jsonb_build_array('MetaTrader 4','MetaTrader 5','cTrader','TradingView'),
    'us_ftmo_affiliate', jsonb_build_array('MetaTrader 5','TradingView'),
    'platforms_are_user_selectable', true,
    'account_type_scope', case p.slug
      when 'ftmo-1-step' then 'Global 1-Step is Standard only; FTMO confirms Swing is not offered for 1-Step.'
      else 'Global 2-Step offers Standard and Swing. Standard restrictions on selected news releases and overnight/weekend holding apply on FTMO Accounts, not during the Evaluation Process; Swing has no such restrictions. Verify account-type availability in the applicable market checkout.'
    end,
    'market_scope_note', 'The program-platform association is a union for comparison and cannot encode market-specific availability. Use this market map: the US affiliate FAQ lists MT5 and TradingView; FTMO Global FAQ lists MT4, MT5, cTrader, and TradingView.'
  ),
  'market_eligibility_note', 'FTMO Global and FTMO US are separate market offers with different eligibility, platform, entity, and fee rules. Check the current official eligibility FAQ for the customer market.'
),
updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'ftmo'
  and p.slug in ('ftmo-1-step','ftmo-2-step');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, s.url, s.label, s.notes
from bullish_banana.firms f
join (values
  ('https://ftmo.com/en/faq/who-can-join-ftmo/', 'FTMO Global client eligibility', 'Official eligibility FAQ reviewed 2026-09-30. Captures age threshold, restricted countries/regions and person categories, conditional exceptions, and referrals to US and Australian affiliates. The page states lists can change.'),
  ('https://ftmo.oanda.com/faq/who-can-join-ftmo-us/', 'FTMO US client eligibility', 'Official FTMO x OANDA FAQ reviewed 2026-09-30. FTMO US serves eligible US residents and US-incorporated legal entities; lists eligible territories, excluded states for entities, person/entity exclusions, and US payout requirements.'),
  ('https://ftmo.com/en/faq/which-platforms-can-i-use-for-trading/', 'FTMO Global platform availability', 'Official FAQ reviewed 2026-09-30 lists MT4, MT5, cTrader, and TradingView and says the platform is selected in the Challenge configurator.'),
  ('https://ftmo.oanda.com/faq/which-platforms-are-available-to-me/', 'FTMO US platform availability', 'Official US affiliate FAQ reviewed 2026-09-30 lists MetaTrader 5 and TradingView.'),
  ('https://ftmo.com/en/faq/is-the-swing-account-type-available-for-ftmo-challenge-1-step/', 'FTMO 1-Step account type', 'Official FAQ confirms Swing is not offered for FTMO Challenge: 1-Step; Swing is offered exclusively in the 2-Step product.'),
  ('https://ftmo.com/en/faq/can-i-modify-my-platform-or-account-type/', 'FTMO account type changes', 'Official FAQ reviewed 2026-09-30: platform modifications are supported before trading; 2-Step account type may change from Swing to Standard, but not Standard to Swing. 1-Step does not offer Swing.'),
  ('https://ftmo.oanda.com/faq/ftmo-swing-account-type/', 'FTMO US Swing account terms', 'FTMO US FAQ reviewed 2026-09-30 describes Swing selection and its news/overnight/weekend terms; verify exact product/account configurator availability before ordering.')
) as s(url,label,notes) on true
where f.slug = 'ftmo'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = f.id and existing.source_url = s.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.url, s.label, s.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'ftmo'
join (values
  ('https://ftmo.com/en/faq/which-platforms-can-i-use-for-trading/', 'FTMO Global platform availability', 'Global 1-Step and 2-Step platform options: MT4, MT5, cTrader, and TradingView; selected in configurator.'),
  ('https://ftmo.oanda.com/faq/which-platforms-are-available-to-me/', 'FTMO US platform availability', 'US affiliate platform options: MT5 and TradingView. This market-specific list supersedes the wider Global platform list for US offers.'),
  ('https://ftmo.com/en/faq/who-can-join-ftmo/', 'FTMO Global eligibility', 'Eligibility and restricted-jurisdiction terms for the non-US Global offer; current list and conditional exceptions are retained at the official FAQ.'),
  ('https://ftmo.oanda.com/faq/who-can-join-ftmo-us/', 'FTMO US eligibility', 'Eligibility, entity and payout requirements for US affiliate offers; current full terms are retained at the official FAQ.')
) as s(url,label,notes) on true
where p.slug in ('ftmo-1-step','ftmo-2-step')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = p.id and existing.source_url = s.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-29 22:07:16+00'::timestamptz,
  'Rechecked FTMO Global and FTMO US eligibility and platform FAQs on 2026-09-30. Recorded market-specific platform lists, age/entity/jurisdiction limits and account-type distinctions. Eligibility pages state lists may change; require current checkout confirmation.'
from bullish_banana.firms f
where f.slug = 'ftmo'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-29 22:07:16+00'::timestamptz);
