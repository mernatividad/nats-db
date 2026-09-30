-- Add For Traders' currently advertised Forex products as review records.
-- First-party research captured 2026-09-28. Checkout-dependent settings and
-- source conflicts remain explicit; these records are not published yet.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type)
values ('For Traders', 'for-traders', 'For Traders offers simulated Forex evaluations and direct-funded account products.', 'https://fortraders.com/', 'in_review', 'forex')
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = case when bullish_banana.firms.status = 'published' then 'published' else 'in_review' end,
    updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'for-traders'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'AE', 'BLN TECH CLUB DMCC', array['Forex']::text[],
  '{"service_model":"Simulated trading and education service; demo funds are fictitious and rewards are discretionary under the terms.","established_year":2023,"platforms_disclosed_at_firm_level":["MetaTrader 5","TradeLocker","cTrader"],"platform_availability_note":"The public site says platform options depend on the selected challenge; availability for each Forex offer and region is unconfirmed.","legal_entity_conflict":"Current Terms identify BLN TECH CLUB DMCC as provider, while the site footer also names FT Trading Ltd. Relationship is not explained in the public material reviewed.","restricted_countries_note":"Terms list differs from the footer; use the formal terms pending clarification.","account_allocation_note":"Terms cap combined active Master and Instant Master allocation at $300,000."}'::jsonb
from bullish_banana.firms where slug = 'for-traders'
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
select f.id, p.name, p.slug, p.description, p.program_type, 'forex', 'in_review', 'USD',
       p.account_sizes::jsonb, p.max_leverage, p.profit_split_percent, p.payout_frequency,
       p.minimum_trading_days, p.news_allowed, true, p.commercial_details::jsonb, null, null
from bullish_banana.firms f
join (values
  ('FAST (1-Step)', 'fast-1-step', 'Single-phase Forex evaluation with selectable target and profit-split configurations.', 'evaluation', '[{"account_size":6000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 3, null::boolean, '{"account_size_prices":[{"account_size":6000,"fee":41,"list_fee":49,"currency":"USD"},{"account_size":15000,"fee":84,"list_fee":99,"currency":"USD"},{"account_size":25000,"fee":152,"list_fee":179,"currency":"USD"},{"account_size":50000,"fee":211,"list_fee":249,"currency":"USD"},{"account_size":100000,"fee":398,"list_fee":469,"currency":"USD"}],"pricing_note":"Current displayed price follows the regular price. Promo code TRADE15 was displayed on capture date 2026-09-28; the promotion may change.","phase_configuration":{"target_percent":[9,11],"max_drawdown_percent":6,"drawdown_type":"trailing from highest balance","daily_drawdown_percent":3,"time_limit":"none stated"},"configurable_options":{"profit_split_percent":[70,80,90]},"payout_rules":"Three profitable days of at least 0.5% of starting balance are required to pass and again before payout. Rewards every 14 days; $100 minimum profit; up to $20,000 per cycle.","consistency_rule":"No single trade may contribute more than 70% of the target.","commission_details":"A 40% margin rule applies. Overnight/weekend holds allowed. Challenge news trading is unrestricted; on Master, opening positions is restricted within five minutes before/after high-impact news."}'),
  ('FAST STATIC (1-Step)', 'fast-static-1-step', 'Single-phase Forex evaluation with static loss limits and selectable profit-split options.', 'evaluation', '[{"account_size":6000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 20::numeric, 80::numeric, 'Every 14 days', 3, null::boolean, '{"account_size_prices":[{"account_size":6000,"fee":58,"list_fee":69,"currency":"USD"},{"account_size":15000,"fee":118,"list_fee":139,"currency":"USD"},{"account_size":25000,"fee":194,"list_fee":229,"currency":"USD"},{"account_size":50000,"fee":322,"list_fee":379,"currency":"USD"},{"account_size":100000,"fee":509,"list_fee":599,"currency":"USD"}],"pricing_note":"Current displayed price follows the regular price. Promo code TRADE15 was displayed on capture date 2026-09-28; the promotion may change.","phase_configuration":{"target_percent":10,"max_drawdown_percent":6,"drawdown_type":"static","daily_drawdown_percent":3,"time_limit":"none stated"},"configurable_options":{"profit_split_percent":[70,80,90]},"payout_rules":"Three profitable days of at least 0.5% of starting balance are required to pass and before each Master payout. Bi-weekly rewards; $100 minimum profit; up to $15,000 per cycle.","commission_details":"Forex leverage 1:20. A 40% margin rule applies. Overnight/weekend holds allowed. Challenge news trading is unrestricted; Master opening positions is restricted within five minutes before/after high-impact news."}'),
  ('CLASSIC (2-Step)', 'classic-2-step', 'Two-phase Forex evaluation with selectable drawdown configurations.', 'evaluation', '[{"account_size":6000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', null::numeric, 80::numeric, 'Every 14 days', 3, null::boolean, '{"account_size_prices":[{"account_size":6000,"fee":56,"list_fee":67,"currency":"USD"},{"account_size":15000,"fee":99,"list_fee":117,"currency":"USD"},{"account_size":25000,"fee":186,"list_fee":219,"currency":"USD"},{"account_size":50000,"fee":296,"list_fee":349,"currency":"USD"},{"account_size":100000,"fee":492,"list_fee":579,"currency":"USD"}],"pricing_note":"Current displayed price follows the regular price. Promo code TRADE15 was displayed on capture date 2026-09-28; the promotion may change.","phase_configuration":{"targets_percent":[8,5],"max_drawdown_percent":[8,10],"daily_drawdown_percent":[3,4],"drawdown_type":"fixed from initial balance","time_limit":"none stated"},"payout_rules":"Three profitable days of at least 0.5% of starting balance are required in each evaluation phase and on Master. Bi-weekly rewards; $100 minimum profit; up to $15,000 per cycle.","commission_details":"A 40% margin rule applies. Overnight/weekend holds allowed. Challenge news trading is unrestricted; Master opening positions is restricted within five minutes before/after high-impact news. Drawdown choices depend on selected order."}'),
  ('PAY AFTER PASS (1-Step)', 'pay-after-pass-1-step', 'One-phase Forex evaluation with a small entry payment and a separate activation payment due after passing.', 'evaluation', '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', null::numeric, 80::numeric, 'On demand', 0, null::boolean, '{"account_size_prices":[{"account_size":25000,"fee":29,"activation_fee":189,"currency":"USD"},{"account_size":50000,"fee":39,"activation_fee":329,"currency":"USD"},{"account_size":100000,"fee":49,"activation_fee":489,"currency":"USD"},{"account_size":200000,"fee":9,"activation_fee":999,"currency":"USD"}],"pricing_note":"The $25K/$50K/$100K fees are from the Forex rules article. The $200K $9 entry/$999 activation offer is a newer announcement whose complete Forex configuration was not verified; keep this program in review.","phase_configuration":{"target_percent":2,"max_drawdown_percent":6,"drawdown_type":"trailing from highest account balance","daily_drawdown_percent":3,"time_limit":"none stated"},"payout_rules":"Activation payment is due within five days after passing. Master requires a best-day consistency below 20%, 3% payout buffer and 80% split. On-demand rewards; maximum $15,000 per withdrawal.","inactivity_rule":"30 days without activity may result in inactivity."}'),
  ('INSTANT (Forex)', 'instant-forex', 'Direct-funded Forex account with no evaluation phase.', 'instant_funding', '[{"account_size":6000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 30::numeric, 70::numeric, 'Every 14 days', 7, null::boolean, '{"account_size_prices":[{"account_size":6000,"fee":69,"list_fee":138,"currency":"USD"},{"account_size":15000,"fee":109,"list_fee":218,"currency":"USD"},{"account_size":25000,"fee":169,"list_fee":338,"currency":"USD"},{"account_size":50000,"fee":279,"list_fee":558,"currency":"USD"},{"account_size":100000,"fee":439,"list_fee":878,"currency":"USD"}],"pricing_note":"Current and crossed-out prices captured 2026-09-28; the promotion may change.","phase_configuration":{"evaluation":"none","max_drawdown_percent":5,"drawdown_type":"trailing from highest balance; locks at start balance on payout","daily_drawdown_percent":3},"payout_rules":"Seven profitable days of at least 0.5% of starting balance; best day below 15% of total profit; 3% payout buffer. Split starts at 70% and rises by five points per approved reward to 90%. Every 14 days; max $15,000 per cycle.","consistency_rule":"Best day must be below 15% of total profit.","commission_details":"2% floating-loss drawdown-protection feature. Forex leverage 1:30. Overnight/weekend holds allowed; cannot open within five minutes before/after high-impact news.","inactivity_rule":"Seven days without meaningful activity may make the account inactive."}'),
  ('INSTANT PRO (Forex)', 'instant-pro-forex', 'Direct-funded Forex account with no evaluation phase and no daily drawdown limit stated.', 'instant_funding', '[{"account_size":3000,"currency":"USD"},{"account_size":6000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"}]', 10::numeric, 60::numeric, 'Every 14 days', null::integer, null::boolean, '{"account_size_prices":[{"account_size":3000,"fee":92,"list_fee":109,"currency":"USD"},{"account_size":6000,"fee":186,"list_fee":219,"currency":"USD"},{"account_size":15000,"fee":373,"list_fee":439,"currency":"USD"},{"account_size":25000,"fee":713,"list_fee":839,"currency":"USD"}],"pricing_note":"Current and crossed-out prices captured 2026-09-28; the promotion may change.","phase_configuration":{"evaluation":"none","max_drawdown_percent":6,"drawdown_type":"trailing from highest balance; locks at start balance on payout","daily_drawdown":"none stated"},"payout_rules":"Split starts at 60% and rises by ten points per approved reward to 90%. Bi-weekly rewards, 3% payout buffer, maximum $15,000 per cycle.","commission_details":"Forex leverage 1:10. Overnight/weekend holds allowed; new positions restricted within five minutes before/after high-impact news.","inactivity_rule":"Seven days without meaningful activity may make the account inactive."}')
) as p(name, slug, description, program_type, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, commercial_details) on true
where f.slug = 'for-traders'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'in_review', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = null, archived_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.maximum_loss, x.drawdown_type, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('fast-1-step', 1, 'Evaluation', 9.000::numeric, 3.000::numeric, 6.000::numeric, 'trailing', 3, '{"target_variant_percent":[9,11],"source_note":"Target and profit split vary by selector choice; this row documents the default evidence and stays in review until variants are captured."}'),
  ('fast-static-1-step', 1, 'Evaluation', 10.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 3, '{"source_note":"Three profitable days of at least 0.5% of starting balance are required."}'),
  ('classic-2-step', 1, 'Phase 1', 8.000::numeric, 4.000::numeric, 10.000::numeric, 'static', 3, '{"target_variant_percent":[8],"drawdown_variant_percent":[8,10],"daily_drawdown_variant_percent":[3,4],"source_note":"Selected order determines loss limits."}'),
  ('classic-2-step', 2, 'Phase 2', 5.000::numeric, 4.000::numeric, 10.000::numeric, 'static', 3, '{"drawdown_variant_percent":[8,10],"daily_drawdown_variant_percent":[3,4],"source_note":"Selected order determines loss limits."}'),
  ('pay-after-pass-1-step', 1, 'Evaluation', 2.000::numeric, 3.000::numeric, 6.000::numeric, 'trailing', 0, '{"source_note":"Activation fee is separately due within five days after passing."}')
) as x(program_slug, phase_number, name, target, daily_loss, maximum_loss, drawdown_type, days, rules)
  on x.program_slug = p.slug
where f.slug = 'for-traders'
on conflict (program_id, phase_number) do update
set name = excluded.name, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent,
    maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, minimum_trading_days = excluded.minimum_trading_days,
    raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://fortraders.com/challenges?step=1', 'For Traders challenge and pricing page', 'First-party current offer list and promotional price tables captured 2026-09-28. Order settings may be selectable and offers may change.'),
  ('https://fortraders.com/instant-funding?edition=pro', 'For Traders Instant pricing', 'First-party Instant and Instant PRO sizes and displayed promotional prices captured 2026-09-28.'),
  ('https://fortraders.com/terms-and-conditions', 'For Traders terms', 'First-party provider identity, service terms, account allocation and country restrictions; entity and footer country-list discrepancies remain.'),
  ('https://help.fortraders.com/en/collections/14318524-our-accounts', 'For Traders Forex account collection', 'Official Help Center lists active Forex account types; STRIKE is excluded because comparison marks it unavailable.'),
  ('https://help.fortraders.com/en/articles/15208251-account-types-comparison', 'For Traders account comparison', 'Official status for active and unavailable account families and product-scope cross-check.')
) as x(url, label, notes) on true
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('fast-1-step', 'https://help.fortraders.com/en/articles/13459470-fast-account-forex', 'FAST Forex rules', 'Official rules captured 2026-09-28; selector offers alternate target and split values.'),
  ('fast-static-1-step', 'https://help.fortraders.com/en/articles/15376206-fast-static-account-forex', 'FAST STATIC Forex rules', 'Official rules captured 2026-09-28.'),
  ('classic-2-step', 'https://help.fortraders.com/en/articles/15378600-classic-account-forex', 'CLASSIC Forex rules', 'Official rules captured 2026-09-28; loss-limit variants depend on order selection.'),
  ('pay-after-pass-1-step', 'https://help.fortraders.com/en/articles/15359294-pay-after-pass-account-forex', 'PAY AFTER PASS Forex rules', 'Official rules and three listed sizes captured 2026-09-28.'),
  ('pay-after-pass-1-step', 'https://help.fortraders.com/en/articles/16761354-first-time-ever-a-200k-account-with-pay-after-pass', 'PAY AFTER PASS $200K announcement', 'Separate current announcement captured 2026-09-28; complete settings and duration of promotion are not confirmed.'),
  ('instant-forex', 'https://help.fortraders.com/en/articles/15379105-instant-account-forex', 'INSTANT Forex rules', 'Official product rules captured 2026-09-28.'),
  ('instant-forex', 'https://help.fortraders.com/en/articles/15053571-reward-policy-instant-account-forex', 'INSTANT Forex reward policy', 'Official reward split progression and withdrawal rules captured 2026-09-28.'),
  ('instant-pro-forex', 'https://help.fortraders.com/en/articles/15379390-instant-pro-account-forex', 'INSTANT PRO Forex rules', 'Official product rules captured 2026-09-28.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url and s.source_label = x.label);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Current Forex products, company disclosure, terms and known entity/country-list discrepancies reviewed against first-party pages on 2026-09-28. Firm remains in review until conflicts are resolved.'
from bullish_banana.firms f
where slug = 'for-traders'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Rules, prices, sizes and terms reviewed against first-party For Traders pages on 2026-09-28. Products remain in review pending order-selector variant and platform-by-program checks; $200K PAY AFTER PASS terms are incomplete.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at For Traders',
       case when p.slug in ('instant-forex','instant-pro-forex') then 'https://fortraders.com/instant-funding?edition=pro' else 'https://fortraders.com/challenges?step=1' end,
       true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
