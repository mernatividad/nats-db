-- Ment Funding's current one-step Forex evaluation snapshot, captured 2026-09-29.
-- Hold in review: the public selector offers a $2M Forex tier, but July 2026 Terms
-- state a $1M maximum active evaluation/funded allocation per person.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type)
values (
  'Ment Funding', 'ment-funding',
  'Ment Funding offers a one-step simulated Forex evaluation with a static loss limit and a separate funded payout schedule.',
  'https://mentfunding.com/', 'in_review', 'forex'
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'in_review', market_type = 'forex', published_at = null, archived_at = null,
    updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'ment-funding'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, null, null, array['Forex', 'Commodities', 'Indices', 'Futures', 'Equities']::text[],
  '{"service_model":"The current Forex selector describes a one-step evaluation. Current public materials use both funded/live-account language and an assessment-to-Trader-Agreement model; the exact account legal counterparty and post-evaluation account arrangement need confirmation.","platforms_disclosed_at_firm_level":["DXtrade","MatchTrader","cTrader","GooeyPro"],"platform_scope_note":"The FAQ lists these platforms for Forex but does not map platform availability to account size, drawdown configuration, or region.","legal_entity_conflict":"July 2026 Terms refer to the Prop Account Group of Companies and name Dashboard Analytix, Prop Account LLC, and Prop Account Cayman, LC; the public pages do not identify the exact Forex customer contracting entity. Contact page gives a US headquarters and registered address, which does not resolve the contracting entity.","supported_markets_note":"Official site presents Forex, Futures, and Equities products; the Forex offering also lists commodities and indices as tradable instruments.","jurisdiction_note":"FAQ says most countries are accepted with a small sanctions-related restricted list, but does not enumerate the full list. Confirm eligibility in the account order flow.","allocation_conflict":"Public Forex selector offers a directly purchasable $2,000,000 size, while Terms section 13 state a maximum of $1,000,000 in active evaluation or funded plans per person. Keep the firm and offer in review until Ment clarifies the controlling limit."}'::jsonb
from bullish_banana.firms where slug = 'ment-funding'
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
select f.id, 'Forex 1-Step Evaluation', 'forex-1-step',
       'Single-phase Forex evaluation with a 10% target, 5% daily loss limit, and 6% static maximum loss.',
       'evaluation', 'forex', 'in_review', 'USD',
       '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":400000,"currency":"USD"},{"account_size":1000000,"currency":"USD"},{"account_size":2000000,"currency":"USD"}]'::jsonb,
       20::numeric, 75::numeric, 'First payout from day one; then every 30 days', null::integer,
       false, null::boolean,
       '{"account_size_prices":[{"account_size":25000,"fee":250,"list_fee":325,"currency":"USD"},{"account_size":50000,"fee":450,"list_fee":585,"currency":"USD"},{"account_size":100000,"fee":750,"list_fee":1105,"currency":"USD"},{"account_size":200000,"fee":1500,"list_fee":2145,"currency":"USD"},{"account_size":400000,"fee":3000,"list_fee":4225,"currency":"USD"},{"account_size":1000000,"fee":8600,"list_fee":9750,"currency":"USD"},{"account_size":2000000,"fee":17200,"list_fee":21000,"currency":"USD"}],"pricing_capture":"Live Forex selector price pairs captured 2026-09-29 before applying a checkout promo code. The site banner advertised code RETURNSDAY for 16% off through 2026-09-30; the final code-adjusted payable amount was not calculated or verified in checkout.","maximum_drawdown":"6% static from starting balance; the page says the threshold locks at starting balance after first payout.","daily_drawdown":"5% from the prior day balance, reset at 5 PM EST.","profit_target":"10% in one evaluation phase.","time_limit":"No maximum evaluation period stated; official Forex rules say there are no time limits.","minimum_trading_days":"No minimum trading days stated for the Forex evaluation.","profit_split":"75% default; 90% is a paid checkout add-on.","payout_rules":"First payout may be requested from day one; subsequent withdrawals are every 30 days. The balance is debited for the firm share and the maximum drawdown locks at the starting balance on withdrawal.","consistency_rule":"No rule stated for account sizes from $25K through $1M. For the $2M Forex tier, the page states a 35% funded-account consistency requirement before a payout. The $2M tier also has a 2.5% daily profit cap.","forex_leverage":"Up to 1:20; the firm notes actual leverage may be lower depending on market conditions.","news_rule":"Opening a position within three minutes before or after a news event is prohibited; holding an existing position through the event is allowed.","weekend_holding":"Positions close by 3:45 PM EST Friday unless the weekend-holding checkout add-on is purchased.","trading_methods":"The public Forex rules allow EAs, hedging, and scalping; Terms prohibit third-party/off-the-shelf passing strategies, EAs used for copy trading, and cross-account hedging. Same-owner account copying only.","inactivity_rule":"At least one trade must be opened or closed in each 30-day period.","commission_details":"Official commissions and products page states Forex pairs incur $7 per standard lot; listed spreads are averages or targets, not fixed guarantees.","refund_policy":"Purchases are final; the current Refund Policy states no refunds for services rendered immediately upon purchase.","platforms":"DXtrade, MatchTrader, cTrader, and GooeyPro are named for Forex at firm level; plan-specific availability is not stated.","allocation_conflict":"The selector offers $2M directly, while Terms section 13 cap active evaluation/funded plans at $1M per person. Keep the offer in review pending written clarification.","review_note":"Firm and program remain in review for the $2M allocation/Terms conflict, exact contracting entity, full jurisdiction list, plan-specific platform availability, and final promo-code checkout amount."}'::jsonb,
       null, null
from bullish_banana.firms f
where f.slug = 'ment-funding'
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
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select p.id, 1, 'Evaluation', 10::numeric, 5::numeric, 6::numeric, 'static', null::integer,
       null::integer,
       '{"daily_loss_basis":"Prior-day closing balance; reset at 5 PM EST.","maximum_loss_basis":"Static 6% of starting balance; locks to starting balance after first payout.","daily_profit_cap":"No cap is stated for $25K to $1M. The $2M Forex account is subject to a 2.5% daily profit cap.","consistency":"No rule is stated for $25K to $1M. The $2M account has a 35% funded-stage consistency condition before payout.","duration":"No minimum or maximum time limit is stated for this one-step Forex evaluation.","source_note":"Official Forex selector and rules captured 2026-09-29. Account-size-specific exceptions and open Terms conflict are recorded in program commercial details."}'::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'ment-funding' and p.slug = 'forex-1-step'
on conflict (program_id, phase_number) do update
set name = excluded.name, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent,
    maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules,
    updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://mentfunding.com/', 'Ment Funding homepage and Forex selector', 'Current Forex account sizes, selected account price pairs, public rules, payout terms, scaling, platforms and instruments reviewed 2026-09-29.'),
  ('https://mentfunding.com/terms-of-service', 'Ment Funding Terms of Service', 'Terms marked updated July 2026; Prop Account group/entity wording, assessment agreement terms, trading restrictions and $1M per-person active allocation cap.'),
  ('https://mentfunding.com/refund-policy', 'Ment Funding Refund Policy', 'Policy marked updated 2026-06-16; states purchases are final and services are nonrefundable.'),
  ('https://mentfunding.com/commissions-and-products/', 'Ment Funding commissions and products', 'Forex pairs, per-lot commission, and average/target spread information; page marked updated 2026-06-16.'),
  ('https://mentfunding.com/contact/', 'Ment Funding contact and company information', 'Public contact page names a US headquarters and address but does not resolve which group entity contracts for Forex accounts.')
) as x(url, label, notes) on true
where f.slug = 'ment-funding'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('https://mentfunding.com/', 'Forex selector and rules', 'Seven Forex sizes and displayed current/list price pairs selected in the official selector on 2026-09-29. Public rules state one phase, 10% target, 5% daily loss, 6% static maximum loss, no evaluation time or minimum-day limit, 75% default split, and size-specific exceptions.'),
  ('https://mentfunding.com/terms-of-service', 'Terms and eligibility conflict', 'Terms section 13 states a maximum $1M in active evaluation or funded plans per person; official selector simultaneously offers a direct $2M Forex size. Terms govern where terms/policy conflict.'),
  ('https://mentfunding.com/refund-policy', 'Refund terms', 'Current policy states one-time evaluation purchases are final and nonrefundable.'),
  ('https://mentfunding.com/commissions-and-products/', 'Forex instruments and costs', 'Official instrument-cost disclosure states $7 commission per standard lot and describes displayed spreads as average/target values.')
) as x(url, label, notes) on true
where f.slug = 'ment-funding' and p.slug = 'forex-1-step'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, '2026-09-29T00:00:00Z'::timestamptz,
       'Current Forex selector, public company disclosures, Terms, refund policy and commissions page reviewed 2026-09-29. Kept in review for unresolved operator, jurisdiction, platform-scope, and $2M allocation conflicts.'
from bullish_banana.firms f
where f.slug = 'ment-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-29T00:00:00Z'::timestamptz,
       'One-step Forex rules and all seven selector price pairs captured on 2026-09-29. Discount code advertised separately and excluded from fee calculations. Program remains in review pending resolution of the $2M Terms allocation conflict and account-specific contracting details.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'ment-funding' and p.slug = 'forex-1-step'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View Ment Funding Forex evaluation', 'https://mentfunding.com/#standard', true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'ment-funding' and p.slug = 'forex-1-step'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
