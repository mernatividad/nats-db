-- Axi Select is a no-fee, staged capital-allocation program, not a prop challenge.
-- Stage thresholds are indicative per Axi's public program page; regions and customer eligibility vary.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type)
values (
  'Axi Select', 'axi-select',
  'Axi Select is a no-fee Forex capital-allocation program linked to an Axi live trading account. Traders progress through Edge Score and equity-based stages; it is not a conventional challenge.',
  'https://www.axi.com/int/funded-trader-program', 'published', 'forex'
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'published', market_type = 'forex', published_at = coalesce(bullish_banana.firms.published_at, now()), archived_at = null, updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'axi-select'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, null, 'AxiTrader LLC', array['Forex', 'Indices']::text[],
  '{"service_model":"No-fee capital allocation program connected to a customer-funded Axi live trading account; qualifying traders may receive an additional Axi-funded Allocation Account.","platforms":["MetaTrader 4","MetaTrader 5"],"platform_scope_note":"Axi states that the program is available to AxiTrader LLC clients; regional entity and eligibility vary.","eligibility_note":"New traders: minimum $500 deposit, Edge Score 50, and 20 unique closed trades. Existing eligible Axi traders may qualify with Edge Score 50. No time limit is stated for completing the 20 trades.","funding_note":"The customer-funded trading account and the firm-funded Allocation Account are distinct. Stage matrix values are indicative and subject to change.","instrument_note":"Axi Select supports eligible Forex symbols; copied allocation instruments are subject to Axi rules.","region_note":"Do not infer worldwide eligibility. Confirm the user’s Axi entity and country eligibility with Axi."}'::jsonb
from bullish_banana.firms where slug = 'axi-select'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details,
  published_at, archived_at
)
select f.id, 'Axi Select Capital Allocation', 'axi-select-allocation',
       'No-fee, staged Forex capital allocation through an Axi live account. Qualification uses equity, Edge Score, and trading activity rather than a challenge target.',
       'other', 'forex', 'published', 'USD', '[]'::jsonb,
       null::numeric, null::numeric, 'Monthly; fees are processed on the first day of the month subject to account conditions',
       null::integer, null::boolean, null::boolean,
       '{"fee":"No application or membership fee stated","program_model":"Capital allocation; not a challenge or evaluation purchase","qualification":"New traders require Edge Score 50, 20 unique closed trades, and at least $500 deposited. Existing clients may qualify with Edge Score 50. No time limit is stated for the 20 trades.","platforms":["MetaTrader 4","MetaTrader 5"],"payout_rules":"Monthly performance fee is subject to month-end balance and open-position conditions; see official payout FAQ. Public program page says payouts are processed on the first of each month.","instrument_scope":"Forex symbols are eligible; allocation copying and regional account eligibility depend on Axi rules.","indicative_values_note":"Public stage thresholds are indicative and may change. Minimum equity refers to customer-account equity; maximum funding refers to the separate allocation account. Stage share and requirements vary.","stages":[{"name":"Seed","minimum_equity":500,"edge_score":50,"maximum_multiplier":10,"maximum_funding":5000,"profit_share":0,"profit_target":7,"minimum_duration_days":30,"trades":20,"leverage":1000,"maximum_loss":7},{"name":"Incubation","minimum_equity":1000,"edge_score":60,"maximum_multiplier":10,"maximum_funding":20000,"profit_share":40,"profit_target":7,"minimum_duration_days":60,"trades":40,"leverage":100,"maximum_loss":7},{"name":"Acceleration","minimum_equity":2000,"edge_score":70,"maximum_multiplier":25,"maximum_funding":100000,"profit_share":50,"profit_target":7,"minimum_duration_days":60,"trades":50,"leverage":100,"maximum_loss":7},{"name":"Pro","minimum_equity":5000,"edge_score":90,"maximum_multiplier":40,"maximum_funding":200000,"profit_share":60,"profit_target":7,"minimum_duration_days":60,"trades":50,"leverage":100,"maximum_loss":7},{"name":"Pro 500","minimum_equity":10000,"edge_score":90,"maximum_multiplier":50,"maximum_funding":500000,"profit_share":70,"profit_target":7,"minimum_duration_days":60,"trades":50,"leverage":100,"maximum_loss":7},{"name":"Pro M","minimum_equity":20000,"edge_score":90,"maximum_multiplier":50,"maximum_funding":1000000,"profit_share":80,"profit_target":null,"minimum_duration_days":null,"trades":50,"leverage":100,"maximum_loss":10}],"review_note":"Eligibility and contracting entity must be confirmed for each visitor jurisdiction. The published stage matrix is indicative."}'::jsonb,
       now(), null
from bullish_banana.firms f where f.slug = 'axi-select'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'published', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = coalesce(bullish_banana.programs.published_at, now()),
    archived_at = null, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://www.axi.com/int/funded-trader-program', 'Axi Select program and stage matrix', 'Official public page reviewed 2026-09-29. No challenge or fee; stage metrics, allocation cap, profit share, trading requirements and monthly processing. Page labels stage terms indicative and subject to change.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/1YzJXzUf-what-is-axi-select', 'Axi Select overview', 'Official Support article reviewed 2026-09-29. Program structure, no-fee positioning and Axi client availability; regional account entity applies.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/zLCbArkB-how-do-i-qualify-for-the-axi-select-program', 'Qualification requirements', 'Official Support article reviewed 2026-09-29. Edge Score, unique closed trades, minimum deposit and no stated time limit for trade qualification.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/8Zjs9f7o--axi-select-', 'Current Axi Select stages', 'Official Support article reviewed 2026-09-29; confirms current stage names.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/Af3ubqWW-what-products-and-instruments-can-i-trade-in-axi-select', 'Eligible products and instruments', 'Official Support article reviewed 2026-09-29; Forex and copied Allocation Account instrument eligibility.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/OcgZvFFC-does-axi-select-pay-performance-fees', 'Performance fee and payout conditions', 'Official Support article reviewed 2026-09-29; month-end performance fee conditions and balance requirements.')
) as x(url, label, notes) on true
where f.slug = 'axi-select'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('https://www.axi.com/int/funded-trader-program', 'Axi Select stage matrix', 'Six current stage levels, indicative minimum equity, Edge Score, multiplier, allocation maximum, profit share, target, duration, trade count, leverage and maximum loss reviewed 2026-09-29.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/zLCbArkB-how-do-i-qualify-for-the-axi-select-program', 'Qualification requirements', 'New traders: Edge Score 50, 20 unique closed trades and $500 deposited; existing-client path differs. No challenge purchase or time limit for trade qualification is stated.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/OcgZvFFC-does-axi-select-pay-performance-fees', 'Performance fee and monthly payout terms', 'Fee conditions depend on the allocation account balance at month end and open-position status; consult current official conditions.'),
  ('https://help.axi.com/en-US/axiv2--axicorp-prod/article/Af3ubqWW-what-products-and-instruments-can-i-trade-in-axi-select', 'Forex product eligibility', 'Forex symbol eligibility and instrument copying follow Axi program rules; not all products should be assumed eligible.')
) as x(url, label, notes) on true
where f.slug = 'axi-select' and p.slug = 'axi-select-allocation'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, '2026-09-29T00:00:00Z'::timestamptz,
       'Official Axi Select program and support sources reviewed 2026-09-29. Listed as a Forex capital-allocation alternative, not a challenge. Country/entity eligibility must be confirmed for each visitor.'
from bullish_banana.firms f where f.slug = 'axi-select'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-29T00:00:00Z'::timestamptz,
       'Current six-stage Axi Select matrix and qualification/payout documentation checked 2026-09-29. Stage terms are indicative; jurisdiction eligibility and live account terms can vary.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'axi-select' and p.slug = 'axi-select-allocation'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'Explore Axi Select', 'https://www.axi.com/int/funded-trader-program', true, 'active'
from bullish_banana.firms f join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'axi-select' and p.slug = 'axi-select-allocation'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
