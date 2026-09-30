-- Add source-backed FTMO profile context reviewed 2026-09-30.
-- The company has separate operating entities by market; do not imply one entity
-- is the contracting party for every visitor.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles
set country_code = 'CZ',
    legal_entity_name = 'FTMO Evaluation Global s.r.o. (non-US FTMO program)',
    supported_assets = array['Forex', 'Commodities', 'Indices', 'Stocks', 'Crypto'],
    profile_details = profile_details || jsonb_build_object(
      'founded_year', 2015,
      'headquarters', 'Prague, Czech Republic',
      'service_model', 'Simulated trading evaluation; FTMO Account trading is simulated.',
      'contracting_entity_scope', 'FTMO Evaluation Global s.r.o. operates the non-US FTMO program. FTMO states the US affiliate program is operated by JV Prop Corporation. Confirm the applicable contracting entity and eligibility in the customer order flow.',
      'entity_note', 'FTMO contact page lists multiple group entities. The non-US entity above is not a universal contracting-entity claim.',
      'source_note', 'Reviewed official FTMO press kit, contact page, FTMO Group page, and non-US vs US FAQ on 2026-09-30.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'ftmo');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://ftmo.com/en/contact/', 'FTMO Contact', 'Official contact page lists its Prague headquarters and several FTMO group legal entities; it does not establish one entity as universal across markets.'),
  ('https://ftmo.com/en/faq/difference-between-ftmo-and-ftmo-us-affiliate-programmes/', 'FTMO and FTMO US program entities', 'Official FAQ states that the non-US FTMO Global program is operated by FTMO Evaluation Global s.r.o. and the US affiliate program by JV Prop Corporation.'),
  ('https://ftmo.com/en/press-kit/', 'FTMO Press Kit', 'Official press kit states FTMO was founded in Prague in 2015 and describes its simulated trading evaluation model.'),
  ('https://ftmo.com/en/ftmo-group/', 'FTMO Group', 'Official group page describes FTMO simulated trading and group entities.'),
  ('https://ftmo.com/faq/which-instruments-can-i-trade-and-what-strategies-am-i-allowed-to-use/', 'FTMO tradable instruments FAQ', 'Current official FAQ lists Forex, indices, commodities, stocks, and crypto among assets available on the trading platform.'),
  ('https://ftmo.com/en/trading-objectives/', 'FTMO Trading Objectives', 'Current official objectives page details the 1-Step Best Day Rule and end-of-day trailing maximum loss, alongside 2-Step evaluation rules.')
) as source(url, label, notes) on true
where firms.slug = 'ftmo'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Refreshed FTMO profile and entity scope from official FTMO sources on 2026-09-30. The non-US and US program operators differ; entity applicability must be verified for each customer.'
from bullish_banana.firms where firms.slug = 'ftmo';
