-- Blueberry Funded Forex catalog refresh and current offers.
-- Captured 2026-09-28. Selector variants conflicting with official written
-- availability/platform guidance are staged for review or omitted.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('Blueberry Funded', 'blueberry-funded', 'Broker-backed simulated Forex evaluations and instant-access accounts with published rules and size-specific checkout fees.', 'https://blueberryfunded.com/', 'published', 'forex', now())
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = case when bullish_banana.firms.status = 'published' then 'published' else excluded.status end,
    market_type = 'forex', published_at = coalesce(bullish_banana.firms.published_at, now()),
    archived_at = null, updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'blueberry-funded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, supported_assets, profile_details)
select id, array['Forex']::text[],
  '{"service_model":"Blueberry Funded describes itself as a broker-backed prop trading provider. Offers use simulated trading environments; no real capital is allocated under the Instant Elite Help Center guide.","established_year":null,"legal_entity_note":"The public Help Center says Blueberry Funded contracts traders through a Saint Vincent and the Grenadines entity, but the exact legal name was not confirmed in the accessible current sources. Do not infer a country of incorporation from this contracting-entity statement.","platforms_note":"Current Help Center platform guidance supports MetaTrader 5 and TraderLocker and explicitly says DXtrade, MatchTrader, cTrader and TradingView are not supported. Public checkout selector variants include DXtrade; those price options are excluded pending reconciliation.","current_forex_offers":["1-Step","Flex 1-Step","Prime","Instant Lite","Instant Elite"],"offer_availability_note":"The August 17 announcement was amended August 24: regular 1-Step remains available alongside Flex 1-Step; 2-Step is no longer offered for new purchases. Store API still returns purchasable variants for retired/undocumented products, so written lifecycle guidance governs current status."}'::jsonb
from bullish_banana.firms where slug = 'blueberry-funded'
on conflict (firm_id) do update
set supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details,
  published_at, archived_at
)
select f.id, p.name, p.slug, p.description, p.program_type, 'forex', p.status, 'USD',
       p.account_sizes::jsonb, p.max_leverage, p.split, p.payout, p.days,
       p.news_allowed, p.weekend_allowed, p.details::jsonb,
       case when p.status = 'published' then now() else null end, null
from bullish_banana.firms f
join (values
  ('1-Step', 'one-step', 'A one-phase evaluation with a 10% target, 4% daily loss limit and 6% static maximum loss.', 'evaluation', 'published', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', null::numeric, 80::numeric, 'Every 14 days', 3, false, true, '{"account_size_prices":[{"account_size":5000,"fee":44,"currency":"USD","platform":"MT5"},{"account_size":5000,"fee":44,"currency":"USD","platform":"TradeLocker"},{"account_size":10000,"fee":83,"currency":"USD","platform":"MT5"},{"account_size":10000,"fee":83,"currency":"USD","platform":"TradeLocker"},{"account_size":25000,"fee":165,"currency":"USD","platform":"MT5"},{"account_size":25000,"fee":165,"currency":"USD","platform":"TradeLocker"},{"account_size":50000,"fee":302,"currency":"USD","platform":"MT5"},{"account_size":50000,"fee":302,"currency":"USD","platform":"TradeLocker"},{"account_size":100000,"fee":605,"currency":"USD","platform":"MT5"},{"account_size":100000,"fee":605,"currency":"USD","platform":"TradeLocker"},{"account_size":200000,"fee":1210,"currency":"USD","platform":"MT5"},{"account_size":200000,"fee":1210,"currency":"USD","platform":"TradeLocker"}],"pricing_capture":"Official WooCommerce Store API variation current prices captured 2026-09-28. MT5 and TradeLocker options included; selector''s DXtrade prices omitted because current Help Center says DXtrade is not supported. No additional coupon is included.","payout_rules":"80% profit split; 14-day reward cycle. 1.5% risk-per-trade idea restriction applies on the funded account only. $100 minimum realized payout per official comparison.","consistency_rule":"No consistency rule stated in the official 1-Step/Flex comparison.","prohibited_strategies":"High-impact news trading is restricted. Full prohibited-strategy list should be checked in current terms before publication.","fee_refund_policy":"Not stated in the captured current 1-Step comparison; do not assume a refund.","availability_note":"Current 1-Step remains available per the August 24 amendment to the August 17 update."}'),
  ('Flex 1-Step', 'flex-one-step', 'A one-phase evaluation with a 12% target, no time limit, 3% daily loss limit and 12% static maximum loss.', 'evaluation', 'in_review', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 30::numeric, 85::numeric, 'Every 14 days', 0, false, false, '{"account_size_prices":[{"account_size":5000,"fee":105,"currency":"USD","platform":"MT5"},{"account_size":5000,"fee":105,"currency":"USD","platform":"TradeLocker"},{"account_size":10000,"fee":155,"currency":"USD","platform":"MT5"},{"account_size":10000,"fee":155,"currency":"USD","platform":"TradeLocker"},{"account_size":25000,"fee":330,"currency":"USD","platform":"MT5"},{"account_size":25000,"fee":330,"currency":"USD","platform":"TradeLocker"},{"account_size":50000,"fee":490,"currency":"USD","platform":"MT5"},{"account_size":50000,"fee":490,"currency":"USD","platform":"TradeLocker"},{"account_size":100000,"fee":835,"currency":"USD","platform":"MT5"},{"account_size":100000,"fee":835,"currency":"USD","platform":"TradeLocker"},{"account_size":200000,"fee":1600,"currency":"USD","platform":"MT5"},{"account_size":200000,"fee":1600,"currency":"USD","platform":"TradeLocker"}],"pricing_capture":"Official WooCommerce Store API current-price variants captured 2026-09-28. MT5 and TradeLocker listed; DXtrade omitted pending platform support conflict.","availability_note":"Help Center defines Flex sizes through $100K, but Store API also returns a $200K variant. $200K is excluded and model is in review until the live offer configuration is reconciled.","payout_rules":"85% split and 14-day cycle. If a single trade idea contributes more than 60% of the profit target, four funded trading days are required before payout. Minimum payout is 1% of initial balance.","consistency_rule":"No consistency rule. Profit concentration condition is separate and can trigger four payout days.","risk_per_trade_rule":"1% of initial balance per idea from day one; first occurrence may soft-breach, second closes account.","news_rule":"Opening or closing positions within five minutes of high-impact news is prohibited.","fee_refund_policy":"Not stated in the captured current Flex materials."}'),
  ('Prime', 'prime', 'A two-phase evaluation with 8% and 6% targets, 4% daily loss and 10% static maximum loss.', 'evaluation', 'published', '[{"account_size":2500,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 3, false, null::boolean, '{"account_size_prices":[{"account_size":2500,"fee":37,"currency":"USD","platform":"MT5"},{"account_size":2500,"fee":37,"currency":"USD","platform":"TradeLocker"},{"account_size":5000,"fee":69,"currency":"USD","platform":"MT5"},{"account_size":5000,"fee":69,"currency":"USD","platform":"TradeLocker"},{"account_size":10000,"fee":112,"currency":"USD","platform":"MT5"},{"account_size":10000,"fee":112,"currency":"USD","platform":"TradeLocker"},{"account_size":25000,"fee":206,"currency":"USD","platform":"MT5"},{"account_size":25000,"fee":206,"currency":"USD","platform":"TradeLocker"},{"account_size":50000,"fee":406,"currency":"USD","platform":"MT5"},{"account_size":50000,"fee":406,"currency":"USD","platform":"TradeLocker"},{"account_size":100000,"fee":812,"currency":"USD","platform":"MT5"},{"account_size":100000,"fee":812,"currency":"USD","platform":"TradeLocker"},{"account_size":200000,"fee":1462,"currency":"USD","platform":"MT5"},{"account_size":200000,"fee":1462,"currency":"USD","platform":"TradeLocker"}],"pricing_capture":"Official WooCommerce Store API variation prices captured 2026-09-28; MT5 and TradeLocker only. DXtrade selector prices excluded pending support reconciliation.","payout_rules":"80% split; 14-day reward cycle. Three active days per cycle for purchases from 2026-08-17; older accounts retain five-day terms.","consistency_rule":"None.","risk_per_trade_rule":"No risk-per-trade limit. No lot-size restriction.","news_rule":"Do not open a position within two minutes either side of scheduled high-impact news; management/closing of existing positions allowed.","fee_refund_policy":"Not stated in current Prime materials.","active_day_definition":"Closed trades generating at least 0.5% profit count toward an active day."}'),
  ('Instant Lite', 'instant-lite', 'Immediate-access simulated Forex account with a 2% daily limit, 4% trailing-lock maximum loss and a payout consistency check.', 'instant_funding', 'published', '[{"account_size":1250,"currency":"USD"},{"account_size":2500,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', null::numeric, 80::numeric, 'Every 14 days', 0, null::boolean, null::boolean, '{"account_size_prices":[{"account_size":1250,"fee":42.5,"currency":"USD","platform":"MT5"},{"account_size":1250,"fee":42.5,"currency":"USD","platform":"TradeLocker"},{"account_size":2500,"fee":65,"currency":"USD","platform":"MT5"},{"account_size":2500,"fee":65,"currency":"USD","platform":"TradeLocker"},{"account_size":5000,"fee":95,"currency":"USD","platform":"MT5"},{"account_size":5000,"fee":95,"currency":"USD","platform":"TradeLocker"},{"account_size":10000,"fee":139,"currency":"USD","platform":"MT5"},{"account_size":10000,"fee":139,"currency":"USD","platform":"TradeLocker"},{"account_size":25000,"fee":349,"currency":"USD","platform":"MT5"},{"account_size":25000,"fee":349,"currency":"USD","platform":"TradeLocker"},{"account_size":50000,"fee":449,"currency":"USD","platform":"MT5"},{"account_size":50000,"fee":449,"currency":"USD","platform":"TradeLocker"},{"account_size":100000,"fee":785,"currency":"USD","platform":"MT5"},{"account_size":100000,"fee":785,"currency":"USD","platform":"TradeLocker"}],"pricing_capture":"Official WooCommerce Store API current-price variants captured 2026-09-28. MT5 and TradeLocker only; DXtrade omitted pending support reconciliation.","risk_per_trade_rule":"1.5% per trade idea measured per instrument; hard breach closes account.","consistency_rule":"At payout, best day must be within 15% of total profit behind the request.","payout_rules":"80% split; 14-day cycle; $100 realized profit minimum; no minimum payout days."}'),
  ('Instant Elite', 'instant-elite', 'Immediate simulated Forex account with a 10% trailing maximum loss that locks at starting balance and no daily loss limit.', 'instant_funding', 'published', '[{"account_size":2500,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 5, false, true, '{"account_size_prices":[{"account_size":2500,"fee":100,"currency":"USD","platform":"MT5"},{"account_size":2500,"fee":100,"currency":"USD","platform":"TradeLocker"},{"account_size":5000,"fee":200,"currency":"USD","platform":"MT5"},{"account_size":5000,"fee":200,"currency":"USD","platform":"TradeLocker"},{"account_size":10000,"fee":400,"currency":"USD","platform":"MT5"},{"account_size":10000,"fee":400,"currency":"USD","platform":"TradeLocker"},{"account_size":25000,"fee":800,"currency":"USD","platform":"MT5"},{"account_size":25000,"fee":800,"currency":"USD","platform":"TradeLocker"},{"account_size":50000,"fee":1500,"currency":"USD","platform":"MT5"},{"account_size":50000,"fee":1500,"currency":"USD","platform":"TradeLocker"},{"account_size":100000,"fee":2800,"currency":"USD","platform":"MT5"},{"account_size":100000,"fee":2800,"currency":"USD","platform":"TradeLocker"}],"pricing_capture":"Official WooCommerce Store API current-price variants captured 2026-09-28. Only MT5 and TradeLocker included; DXtrade variants omitted because current Help Center says DXtrade is unsupported.","payout_rules":"80% split; default payout every 14 days. Requires $100 realized profit and five qualifying active days (0.5% closed profit) per payout cycle. Paid add-ons can shorten payout timing or reduce day requirement.","consistency_rule":"None.","risk_per_trade_rule":"1.5% per trade idea for purchases from 2026-03-12.","news_rule":"High-impact news trading is not permitted.","fee_refund_policy":"Not stated in the current Instant Elite guide."}'),
  ('2-Step Challenge', 'two-step-challenge-legacy', 'Legacy two-phase evaluation retained for historical and account-holder rule reference; no longer available for new purchases.', 'evaluation', 'archived', '[]', null::numeric, 80::numeric, null, null::integer, null::boolean, null::boolean, '{"availability_note":"Official Aug 17 notice says the 2-Step is no longer available for new purchases. Public Store API still returns legacy variations marked purchasable; do not treat that flag as current availability."}'),
  ('Instant Pro', 'instant-pro', 'Instant-access variant returned by the public Store API without a current model-specific Help Center rules page.', 'instant_funding', 'in_review', '[{"account_size":2500,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"}]', null::numeric, null::numeric, null, null::integer, null::boolean, null::boolean, '{"account_size_prices":[{"account_size":2500,"fee":125,"currency":"USD","platform":"MT5"},{"account_size":5000,"fee":250,"currency":"USD","platform":"MT5"},{"account_size":10000,"fee":500,"currency":"USD","platform":"MT5"},{"account_size":25000,"fee":1125,"currency":"USD","platform":"MT5"},{"account_size":50000,"fee":2250,"currency":"USD","platform":"MT5"}],"availability_note":"Store API lists purchasable MT5 variations, but a current model-specific Help Center rules page was not verified. Keep in review and out of verified recommendations."}')
) as p(name, slug, description, program_type, status, account_sizes, max_leverage, split, payout, days, news_allowed, weekend_allowed, details)
  on true
where f.slug = 'blueberry-funded'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = excluded.status, currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = case when excluded.status = 'published' then coalesce(bullish_banana.programs.published_at, now()) else null end,
    archived_at = case when excluded.status = 'archived' then coalesce(bullish_banana.programs.archived_at, now()) else null end,
    updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.max_loss,
       x.drawdown_type, x.time_limit_days, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('one-step', 1, 'Evaluation', 10::numeric, 4::numeric, 6::numeric, 'static', null::integer, 3, '{"time_limit":"None","risk_per_trade_idea":"1.5% applies on funded account only","news":"Restricted","weekend_holding":"Allowed","source_note":"Official 1-Step/Flex comparison, captured 2026-09-28."}'),
  ('flex-one-step', 1, 'Evaluation', 12::numeric, 3::numeric, 12::numeric, 'static', null::integer, 0, '{"time_limit":"None","risk_per_trade_idea":"1% from day one","profit_concentration":"A single idea >60% of target triggers four funded payout days","news":"No opening/closing within five minutes of high-impact event","weekend_holding":"Not allowed","source_note":"Official Flex 1-Step rules page, captured 2026-09-28."}'),
  ('prime', 1, 'Phase 1', 8::numeric, 4::numeric, 10::numeric, 'static', null::integer, 3, '{"minimum_days":"Three active days per reward cycle for accounts purchased on/after 2026-08-17; older purchases require five","source_note":"Official Prime rules, captured 2026-09-28."}'),
  ('prime', 2, 'Phase 2', 6::numeric, 4::numeric, 10::numeric, 'static', null::integer, 3, '{"minimum_days":"Three active days per reward cycle for accounts purchased on/after 2026-08-17; older purchases require five","source_note":"Official Prime rules, captured 2026-09-28."}'),
  ('instant-lite', 1, 'Instant-funded account', null::numeric, 2::numeric, 4::numeric, 'trailing lock', null::integer, 0, '{"evaluation":"None","max_drawdown":"4% trailing, locks at starting balance after reaching 4% profit","risk_per_trade_idea":"1.5% per instrument; hard breach","consistency":"Best day within 15% of total payout-request profit","minimum_realized_profit_usd":100,"payout_cycle":"14 days","source_note":"Official Instant Lite post-Aug 17 rules, captured 2026-09-28."}'),
  ('instant-elite', 1, 'Instant-funded account', null::numeric, null::numeric, 10::numeric, 'trailing lock', null::integer, 5, '{"evaluation":"None","trailing_rule":"Trails equity highs then locks at starting balance once account reaches 10% profit","active_day":"At least 0.5% realized closed-trade profit","minimum_realized_profit_usd":100,"source_note":"Current Instant Elite guide, captured 2026-09-28."}'),
  ('two-step-challenge-legacy', 1, 'Legacy Phase 1', 8::numeric, 4::numeric, 10::numeric, 'static', null::integer, null::integer, '{"availability":"Retired to new purchases on 2026-08-17; historic account terms only."}'),
  ('two-step-challenge-legacy', 2, 'Legacy Phase 2', 6::numeric, 4::numeric, 10::numeric, 'static', null::integer, null::integer, '{"availability":"Retired to new purchases on 2026-08-17; historic account terms only."}')
) as x(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, time_limit_days, days, rules)
  on x.program_slug = p.slug
where f.slug = 'blueberry-funded'
on conflict (program_id, phase_number) do update
set name = excluded.name, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent,
    maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules,
    updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('MetaTrader 5', 'metatrader-5'), ('TradeLocker', 'tradelocker')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'blueberry-funded'
cross join bullish_banana.platforms pl
where p.slug in ('one-step','flex-one-step','prime','instant-lite','instant-elite')
  and pl.slug in ('metatrader-5','tradelocker')
on conflict do nothing;

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select f.id, x.code, 'restricted', 'Blueberry Funded Help Center purchase restriction list, captured 2026-09-28.'
from bullish_banana.firms f
cross join (values ('AF'),('AS'),('AU'),('BY'),('CU'),('GU'),('IR'),('IQ'),('MM'),('KP'),('RU'),('SO'),('SY'),('US'),('UM'),('YE')) as x(code)
where f.slug = 'blueberry-funded'
on conflict (firm_id, country_code) do update set restriction_type = excluded.restriction_type, note = excluded.note, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://help.blueberryfunded.com/en/articles/9563981-what-is-blueberry-funded','About Blueberry Funded','First-party company profile describes Blueberry Funded as broker-backed and using Blueberry Markets infrastructure.'),
  ('https://help.blueberryfunded.com/en/articles/16390779-what-s-changing-on-17-august-2026','August 2026 offer lifecycle update','The Aug 24 amendment confirms regular 1-Step remains available with Flex; 2-Step is no longer available for new purchases; Prime day requirement updated.'),
  ('https://help.blueberryfunded.com/en/articles/16591514-what-s-the-difference-between-the-1-step-and-the-flex-1-step','1-Step and Flex 1-Step rules comparison','Current size bands and comparative targets, drawdown, days, payouts, news, weekend and risk-per-idea rules.'),
  ('https://help.blueberryfunded.com/en/articles/12136509-what-is-the-prime-challenge','Prime Challenge rules','Current Prime targets, drawdown, purchase-date trading-day variants, payout cycle, split, leverage, news and risk rules.'),
  ('https://help.blueberryfunded.com/en/articles/16390472-what-are-the-rules-on-a-flex-1-step-account','Flex 1-Step full rules','Current Flex targets, loss rules, platform-independent restrictions, payout, risk-per-idea and news/weekend conditions.'),
  ('https://help.blueberryfunded.com/en/articles/16385107-new-what-are-the-rules-on-an-instant-lite-account','Instant Lite current rules','Post-Aug 17 rules confirm 4% trailing lock, 2% daily limit, 1.5% risk per trade idea, 80% split, 14-day payout cycle, $100 minimum profit and 15% best-day consistency.'),
  ('https://help.blueberryfunded.com/en/articles/11874076-instant-access-sim-account-complete-guide','Instant Elite rules','Current Instant Elite drawdown, active payout-day requirement, split, minimum realized profit, leverage, trading restrictions and supported sizes.'),
  ('https://help.blueberryfunded.com/en/articles/11879872-what-account-sizes-are-available-for-instant-access-sim-accounts','Instant account sizes','Official size list for Instant products; compare against current selector options before adding unlisted sizes.'),
  ('https://help.blueberryfunded.com/en/articles/10741972-platform-downloads','Supported trading platforms','Current platform help page names MT5 and TraderLocker and explicitly says DXtrade, MatchTrader, cTrader and TradingView are not supported.'),
  ('https://help.blueberryfunded.com/en/articles/9550574-are-any-countries-restricted-from-purchasing-an-evaluation','Restricted countries','Current country purchase restrictions captured 2026-09-28.'),
  ('https://blueberryfunded.com/wp-json/wc/store/v1/products?slug=bbf-challenges','Official Blueberry Funded Store API selector','Captured current product and variation price variants on 2026-09-28. Selector exposes legacy/undocumented options, including variants conflicting with official support guidance; only compatible current MT5/TradeLocker options are used.')
) as x(url, label, notes) on true
where f.slug = 'blueberry-funded'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('one-step','https://help.blueberryfunded.com/en/articles/16591514-what-s-the-difference-between-the-1-step-and-the-flex-1-step','1-Step rules comparison','Official current rules and size range; Store API fees captured per size for MT5 and TradeLocker.'),
  ('flex-one-step','https://help.blueberryfunded.com/en/articles/16390472-what-are-the-rules-on-a-flex-1-step-account','Flex 1-Step rules','Rules and size scope from current Help Center; Store API $200K variant conflicts with documented $100K maximum, so status remains in review.'),
  ('prime','https://help.blueberryfunded.com/en/articles/12136509-what-is-the-prime-challenge','Prime rules','Current rule source; Store API fees captured per size for MT5 and TradeLocker.'),
  ('instant-lite','https://help.blueberryfunded.com/en/articles/16390779-what-s-changing-on-17-august-2026','Instant Lite relaunch','Announcement confirms no minimum days, 2% daily loss, 4% trailing-lock max loss and 15% payout consistency.'),
  ('instant-lite','https://help.blueberryfunded.com/en/articles/16385107-new-what-are-the-rules-on-an-instant-lite-account','Instant Lite current rules','Post-Aug 17 Help Center rules detail 4% trailing lock, 2% daily loss, risk-per-idea, payout cycle/split, minimum profit and consistency check.'),
  ('instant-lite','https://help.blueberryfunded.com/en/articles/11879872-what-account-sizes-are-available-for-instant-access-sim-accounts','Instant Lite selector size list','Current selector size/price variants recorded; platform options filtered to MT5 and TradeLocker.'),
  ('instant-elite','https://help.blueberryfunded.com/en/articles/11874076-instant-access-sim-account-complete-guide','Instant Elite complete guide','Current rules, payout requirements and restrictions. Prices captured from current Store API for supported platforms.'),
  ('two-step-challenge-legacy','https://help.blueberryfunded.com/en/articles/16390779-what-s-changing-on-17-august-2026','Retired 2-Step notice','Official lifecycle notice confirms no new 2-Step purchases after 2026-08-17; archived record kept for existing account holders.'),
  ('instant-pro','https://blueberryfunded.com/wp-json/wc/store/v1/products?slug=bbf-challenges','Instant Pro selector variants (review)','Store API exposes purchasable variants, but no current offer rules page was identified. Listing remains under review.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'blueberry-funded'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at Blueberry Funded', 'https://blueberryfunded.com/', true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'blueberry-funded' and p.status = 'published'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Blueberry Funded first-party company profile, current platform guidance, offer lifecycle announcement, restriction list and official selector API reviewed on 2026-09-28. Exact legal entity name remains unknown; selector/platform and stale-variant conflicts are preserved in profile notes.'
from bullish_banana.firms f
where slug = 'blueberry-funded'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), case
  when p.status = 'published' then 'Current first-party Help Center rules and supported-platform Store API price variants reviewed 2026-09-28. Values are a dated offer snapshot; verify checkout before purchase.'
  when p.status = 'archived' then 'Official lifecycle notice states this model is retired to new purchases; retained for existing account-holder reference.'
  else 'Selector/rules evidence contains unresolved availability, platform or current-rules conflicts; listing remains under review and excluded from verified recommendations.' end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blueberry-funded'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);
