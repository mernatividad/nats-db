-- Publish Lark Funding's current Forex offers from its live selector and
-- first-party terms/help pages. Captured 2026-09-28.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('Lark Funding', 'lark-funding', 'Lark Funding offers simulated Forex evaluations and an instant Master account with size-specific rules and rewards.', 'https://larkfunding.com/', 'published', 'forex', now())
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'published', published_at = coalesce(bullish_banana.firms.published_at, now()), archived_at = null, updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'lark-funding'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, established_on, legal_entity_name, supported_assets, profile_details)
select id, 'CA', '2022-07-01'::date, 'Lark Dashboards Inc.',
  array['Forex','Metals','Indices','Cryptocurrencies','Commodities','U.S. stocks']::text[],
  '{"service_model":"The company describes the accounts as simulated demo accounts and the service as trading education and skill assessment; it does not provide brokerage or custody services.","licensed_brand_entity":"Lark Funding Inc.","operator_entity":"Lark Dashboards Inc. is the operator under license from Lark Funding Inc.; Terms identify Lark Dashboards Inc. as the legal operator responsible for payments, platform operations, and fulfillment.","established_year":2022,"platforms_disclosed_at_firm_level":["DXTrade","cTrader","MatchTrader"],"platform_availability_note":"Official EA guidance names these platforms but does not map them to each offer, size, or region.","eligibility_note":"Terms require age 18+ and require the trader to ensure local-law compliance. No firm-published restricted-country list was found in the reviewed sources.","current_selector_offers":["Instant","1-Step","3-Step"],"offer_scope_note":"The current live selector did not list 2-Step, although Help Center payout and timing articles still mention it. Do not treat 2-Step as a currently purchasable Forex product without checkout confirmation.","current_bonus_note":"As captured 2026-09-28, a $1,000 Instant Account is advertised with purchases. It has a separate $100 total withdrawal cap after split, $50 minimum request, and no $40 processing fee. A free-reset promotion for 1-Step and 3-Step ends 2026-09-30 and has risk/usage conditions."}'::jsonb
from bullish_banana.firms where slug = 'lark-funding'
on conflict (firm_id) do update
set country_code = excluded.country_code, established_on = excluded.established_on,
    legal_entity_name = excluded.legal_entity_name, supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details,
  published_at, archived_at
)
select f.id, p.name, p.slug, p.description, p.program_type, 'forex', 'published', 'USD',
       p.account_sizes::jsonb, p.max_leverage, p.profit_split_percent, p.payout_frequency,
       p.minimum_trading_days, true, null::boolean, p.commercial_details::jsonb, now(), null
from bullish_banana.firms f
join (values
  ('1-Step Career Evaluation', '1-step-career-evaluation', 'Single-phase simulated Forex evaluation with a 10% target, 7% static maximum loss, and 5% daily loss limit.', 'evaluation', '[{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 0, '{"account_size_prices":[{"account_size":10000,"fee":200,"currency":"USD"},{"account_size":25000,"fee":300,"currency":"USD"},{"account_size":50000,"fee":500,"currency":"USD"},{"account_size":100000,"fee":800,"currency":"USD"},{"account_size":200000,"fee":1500,"currency":"USD"}],"pricing_capture":"Live official offer selector, displayed USD price, captured 2026-09-28. No regular/crossed-out price was shown.","payout_rules":"On the Master account, standard performance reward is 80% and can be requested every 14 days. A separate Monthly Base contractor fee is $50/$125/$250/$500/$1,000 for $10K/$25K/$50K/$100K/$200K accounts, when the trader records at least three profitable days of 0.5% or more and keeps overall drawdown better than -3.5% within the 30-day eligibility period. A $40 Riseworks processing fee applies to each payment.","consistency_rule":"The current homepage advertises no consistency rules; the reviewed Help Center does not give a separate evaluation consistency threshold.","copy_trading_rule":"Not stated in the reviewed current product sources.","ea_rule":"EAs are permitted if they do not use prohibited strategies. No public API is available; platform compatibility is the trader''s responsibility.","prohibited_strategies":"Terms prohibit price/latency exploitation, insider information, all-or-nothing trading that can breach drawdown in one trade, front-running, broker-relationship jeopardy, equity-CFD gap exploitation, account arbitrage, and EAs using HFT, gold arbitrage, or other prohibited strategies. Terms also cap daily and/or per-trade gain at $10,000.","commission_details":"Forex leverage is 30:1. Forex and metals commission is $7 round trip per standard lot. Indices, crypto, and oil are commission-free; stock commission is $0.02 per share. Firm-level platforms are DXTrade, cTrader, and MatchTrader; availability by offer is not stated.","fee_refund_policy":"A Help Center answer last updated 2023-03-21 says the challenge fee is not refundable. No newer product-specific refund policy was located; confirm the current checkout terms.","promotion_note":"Homepage promotion captured 2026-09-28: free reset included for eligible 1-Step and 3-Step purchases through 2026-09-30. Help Center conditions apply and the offer is temporary. Current homepage also advertises a free $1,000 Instant Account with purchases; its own withdrawal cap and payout rules are described on the firm profile."}'),
  ('3-Step Evaluation', '3-step-evaluation', 'Three-phase simulated Forex evaluation with 5%, 4%, and 3% targets and a 5% static maximum loss.', 'evaluation', '[{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 50::numeric, 80::numeric, 'Every 14 days', 0, '{"account_size_prices":[{"account_size":10000,"fee":105,"currency":"USD"},{"account_size":25000,"fee":175,"currency":"USD"},{"account_size":50000,"fee":280,"currency":"USD"},{"account_size":100000,"fee":370,"currency":"USD"},{"account_size":200000,"fee":750,"currency":"USD"}],"pricing_capture":"Live official offer selector, displayed USD price, captured 2026-09-28. No regular/crossed-out price was shown.","payout_rules":"Standard performance reward is 80%; an optional checkout upgrade increases it to 90%. Requests are every 14 days by default; an optional weekly-payout add-on is available. A $40 Riseworks processing fee applies. Lark Base is identified as a 1-Step-only benefit.","consistency_rule":"The current homepage advertises no consistency rules; the reviewed Help Center does not give a separate evaluation consistency threshold.","copy_trading_rule":"Not stated in the reviewed current product sources.","ea_rule":"EAs are permitted if they do not use prohibited strategies. No public API is available; platform compatibility is the trader''s responsibility.","prohibited_strategies":"Terms prohibit price/latency exploitation, insider information, all-or-nothing trading that can breach drawdown in one trade, front-running, broker-relationship jeopardy, equity-CFD gap exploitation, account arbitrage, and EAs using HFT, gold arbitrage, or other prohibited strategies. Terms also cap daily and/or per-trade gain at $10,000.","commission_details":"Forex leverage is 50:1. Forex and metals commission is $7 round trip per standard lot. Indices, crypto, and oil are commission-free; stock commission is $0.02 per share. Firm-level platforms are DXTrade, cTrader, and MatchTrader; availability by offer is not stated.","fee_refund_policy":"A Help Center answer last updated 2023-03-21 says the challenge fee is not refundable. No newer product-specific refund policy was located; confirm the current checkout terms.","promotion_note":"Homepage promotion captured 2026-09-28: free reset included for eligible 1-Step and 3-Step purchases through 2026-09-30. Help Center conditions apply and the offer is temporary. Current homepage also advertises a free $1,000 Instant Account with purchases; its own withdrawal cap and payout rules are described on the firm profile."}'),
  ('Instant Master Account', 'instant-master-account', 'Direct simulated Forex Master account with no evaluation, an 8% trailing maximum drawdown, and a 5% daily loss limit.', 'instant_funding', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 50::numeric, 90::numeric, 'First payout on demand; subsequent payouts every 30 days', 0, '{"account_size_prices":[{"account_size":5000,"fee":200,"currency":"USD"},{"account_size":10000,"fee":400,"currency":"USD"},{"account_size":25000,"fee":1125,"currency":"USD"},{"account_size":50000,"fee":2750,"currency":"USD"},{"account_size":100000,"fee":4500,"currency":"USD"}],"pricing_capture":"Live official offer selector, displayed USD price, captured 2026-09-28. No regular/crossed-out price was shown.","payout_rules":"No evaluation. Standard reward is 90% of simulated gains. First request is on demand; later requests are every 30 days. Minimum withdrawal is $100. Riseworks processing fee is $40. The 8% maximum trailing drawdown does not reset on payout.","consistency_rule":"The current homepage advertises no consistency rules.","copy_trading_rule":"Not stated in the reviewed current product sources.","ea_rule":"EAs are permitted if they do not use prohibited strategies. No public API is available; platform compatibility is the trader''s responsibility.","prohibited_strategies":"Terms prohibit price/latency exploitation, insider information, all-or-nothing trading that can breach drawdown in one trade, front-running, broker-relationship jeopardy, equity-CFD gap exploitation, account arbitrage, and EAs using HFT, gold arbitrage, or other prohibited strategies. Terms also cap daily and/or per-trade gain at $10,000.","commission_details":"Forex leverage is 50:1. Forex and metals commission is $7 round trip per standard lot. Indices, crypto, and oil are commission-free; stock commission is $0.02 per share. Firm-level platforms are DXTrade, cTrader, and MatchTrader; availability by offer is not stated.","fee_refund_policy":"A Help Center answer last updated 2023-03-21 says the challenge fee is not refundable. No newer product-specific refund policy was located; confirm the current checkout terms.","direct_funding_note":"The official Instant rules state 5% daily loss, 8% trailing drawdown based on the highest recorded closed balance, and a lock at initial balance after an 8% gain or first payout. Daily loss is measured from previous-day closed balance at 5 p.m. EST.","promotion_note":"Current homepage advertises a free $1,000 Instant Account with purchases. Its withdrawal total is capped at $100 after split, with a $50 minimum payout and no $40 processing fee. This is a conditional bonus, not a separate paid challenge."}')
) as p(name, slug, description, program_type, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, commercial_details) on true
where f.slug = 'lark-funding'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'published', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = coalesce(bullish_banana.programs.published_at, now()), archived_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.maximum_loss,
       x.drawdown_type, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('1-step-career-evaluation', 1, 'Evaluation', 10.000::numeric, 5.000::numeric, 7.000::numeric, 'static', 0, '{"time_limit":"unlimited","daily_loss_reset":"5:00 p.m. EST","source_note":"First-party 1-Step Career Evaluation details captured 2026-09-28."}'),
  ('3-step-evaluation', 1, 'Phase 1', 5.000::numeric, null::numeric, 5.000::numeric, 'static', 0, '{"time_limit":"unlimited","daily_loss":"none","source_note":"First-party 3-Step Evaluation details captured 2026-09-28."}'),
  ('3-step-evaluation', 2, 'Phase 2', 4.000::numeric, null::numeric, 5.000::numeric, 'static', 0, '{"time_limit":"unlimited","daily_loss":"none","source_note":"First-party 3-Step Evaluation details captured 2026-09-28."}'),
  ('3-step-evaluation', 3, 'Phase 3', 3.000::numeric, null::numeric, 5.000::numeric, 'static', 0, '{"time_limit":"unlimited","daily_loss":"none","source_note":"First-party 3-Step Evaluation details captured 2026-09-28."}'),
  ('instant-master-account', 1, 'Instant Master account', null::numeric, 5.000::numeric, 8.000::numeric, 'trailing', 0, '{"evaluation":"none","time_limit":"unlimited","daily_loss_reset":"5:00 p.m. EST","trailing_reference":"highest recorded closed account balance; locks at initial balance after an 8% gain or first payout","source_note":"First-party Instant Master Account details captured 2026-09-28."}')
) as x(program_slug, phase_number, name, target, daily_loss, maximum_loss, drawdown_type, days, rules)
  on x.program_slug = p.slug
where f.slug = 'lark-funding'
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
  ('https://larkfunding.com/', 'Lark Funding official site and live offer selector', 'Current purchase selector offered Instant, 1-Step, and 3-Step with size-specific USD prices; also advertises the conditional $1,000 Instant bonus and free-reset promotion. Captured 2026-09-28.'),
  ('https://larkfunding.com/terms-of-use', 'Lark Funding Terms of Use', 'Identifies Lark Dashboards Inc. as operator under license from Lark Funding Inc.; simulated-service description, age/legal eligibility, prohibited trading, and processing rules.'),
  ('https://larkfunding.com/refund-policy', 'Lark Funding refund policy page', 'The page displayed legal/service disclosure but no product-specific refund schedule in the reviewed capture.'),
  ('https://helpdesk.larkfunding.com/en/collections/3916922-take-an-evaluation', 'Lark Funding evaluation Help Center collection', 'Current collection lists 3-Step and Instant details; 2-Step remains in some articles but did not appear in the live selector.'),
  ('https://helpdesk.larkfunding.com/en/articles/7210469-what-markets-and-symbols-can-i-trade', 'Lark Funding markets and symbols', 'First-party Help Center markets and supported asset categories.'),
  ('https://helpdesk.larkfunding.com/en/articles/7174115-can-i-use-an-expert-advisor', 'Lark Funding Expert Advisor rules', 'First-party Help Center lists DXTrade, cTrader, and MatchTrader; EAs may be used within restrictions and there is no public API.'),
  ('https://helpdesk.larkfunding.com/en/articles/8117403-how-do-payouts-work', 'Lark Funding payout schedule', 'Official payout page gives payout timing by model, minimum withdrawal, $40 processing fee, Riseworks, and processing estimates; page still mentions 2-Step.'),
  ('https://helpdesk.larkfunding.com/en/articles/7174156-is-the-challenge-fee-refundable', 'Lark Funding challenge fee refund answer', 'Help answer last updated 2023-03-21 says challenge fee is not refundable; the age of this answer is disclosed in program notes.')
) as x(url, label, notes) on true
where f.slug = 'lark-funding'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('1-step-career-evaluation', 'https://helpdesk.larkfunding.com/en/articles/12853883-1-step-career-evaluation-details', '1-Step Career Evaluation rules', 'Official target, static/daily loss, reward split and cadence, Lark Base eligibility, leverage, commission, and Smart Restart details. Article captured 2026-09-28.'),
  ('3-step-evaluation', 'https://helpdesk.larkfunding.com/en/articles/8251071-3-step-evaluation-details', '3-Step Evaluation rules', 'Official 5% / 4% / 3% targets, static loss, no daily-loss limit, leverage, commission, split and payout add-ons. Captured 2026-09-28.'),
  ('instant-master-account', 'https://helpdesk.larkfunding.com/en/articles/10336809-instant-master-account-details', 'Instant Master Account rules', 'Official 5% daily loss, trailing 8% loss, drawdown lock, leverage, commission, no news restriction, 90% split and payout terms. Captured 2026-09-28.'),
  ('instant-master-account', 'https://helpdesk.larkfunding.com/en/articles/13714987-withdrawal-rules-1-000-instant-account', '$1,000 Instant bonus withdrawal rules', 'Official bonus-specific $100 total withdrawal cap after split, $50 minimum, and no $40 processing fee. Captured 2026-09-28.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'lark-funding'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url and s.source_label = x.label);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Firm operator, simulated service, markets, platforms, age eligibility, prohibited strategies, current offer selector and source dates reviewed against first-party pages on 2026-09-28. 2-Step Help Center references conflict with the current live selector and are not published as an offer.'
from bullish_banana.firms f
where slug = 'lark-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Offer size/price pairs captured directly from the first-party selector and normalized rules checked against current official Help Center and Terms on 2026-09-28. Program-level platform availability and weekend holding remain unstated. The 2023 refund answer is date-qualified.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'lark-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at Lark Funding', 'https://larkfunding.com/', true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'lark-funding'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
