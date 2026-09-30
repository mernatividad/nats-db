-- Refresh Blue Guardian's Forex profile and current purchasable program families.
-- Reviewed 2026-09-28 against the official Forex selector, Help Center, and platform rules.
-- Per-size fees use current displayed prices; the crossed standard price and BG25 promotion
-- were also displayed, and the promotion may change. Legacy/pro/crypto-only models are excluded.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set name = 'Blue Guardian',
    description = 'Blue Guardian offers simulated Forex evaluations and instant-funded accounts through Standard and Nano models, with account-specific payout and risk rules.',
    website_url = 'https://blueguardian.com/forex',
    status = 'published', published_at = coalesce(published_at, now()), updated_at = now()
where slug = 'blue-guardian';

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'blue-guardian'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'futures' from bullish_banana.firms where slug = 'blue-guardian'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'LC', 'Blue Guardian Limited', array['Forex', 'Indices', 'Gold and commodities', 'Cryptocurrencies']::text[],
  '{"service_model":"Blue Guardian describes its evaluations and funded accounts as simulated/demo accounts using virtual funds, not live trading or real client capital.","educational_and_payment_entities":"The current main website identifies Blue Guardian Limited as platform-services provider/operator at a Saint Lucia address; Iconic Exchange FZCO provides educational products and payment processing; Blue Guardian Marketing LLC is a related non-operational support entity. The dedicated checkout terms instead identify Iconic Exchange Limited (UK company 12087566) trading as Blue Guardian. The firm/entity relationship needs confirmation.","headquarters":"Rodney Bay, Gros-Islet, Saint Lucia (Blue Guardian Limited address disclosed in the current site footer).","platform_options":["MetaTrader 5","Match-Trader","TradeLocker"],"platform_notes":"Current Help Center lists MT5, Match-Trader, and TradeLocker. Prospective and existing U.S. clients are restricted to Match-Trader and TradeLocker. Platform availability can vary by account and size; verify checkout.","markets_note":"Official platform rules list Forex, indices, gold/commodities, and cryptocurrencies. Futures is a separate Blue Guardian market and is not part of these Forex programs.","restricted_countries":["Afghanistan","Albania","Algeria","Cuba","Iran","Jordan","Libya","Myanmar","North Korea","Philippines","Senegal","Syria","Vietnam"],"allocation_note":"Maximum active funded allocation is $400,000 across funded account types; official scaling materials contain differing ceilings ($2,000,000 and $4,000,000), so the scaling maximum needs clarification before displaying a single number."}'::jsonb
from bullish_banana.firms where slug = 'blue-guardian'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select firms.id, country.country_code, 'restricted', 'Official Blue Guardian General Information rules list this country as restricted from using its services (reviewed 2026-09-28).'
from bullish_banana.firms
cross join (values ('AF'),('AL'),('DZ'),('CU'),('IR'),('JO'),('LY'),('MM'),('KP'),('PH'),('SN'),('SY'),('VN')) as country(country_code)
where firms.slug = 'blue-guardian'
on conflict (firm_id, country_code) do update
set restriction_type = excluded.restriction_type, note = excluded.note, updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select firms.id, item.name, item.slug, item.description, item.program_type, 'published', 'USD', item.account_sizes::jsonb,
  item.max_leverage, item.profit_split_percent, item.payout_frequency, item.minimum_trading_days,
  item.news_allowed, item.weekend_holding_allowed, item.commercial_details::jsonb, now()
from bullish_banana.firms
join (values
  ('Blue Guardian 1-Step Standard', '1-step-standard', 'evaluation', 'Single-phase Forex evaluation with a 9% target, 4% daily loss limit, and 6% trailing maximum loss that locks at starting balance after 6% growth.', '[5000,10000,25000,50000,100000,200000]', 50::numeric, 85::numeric, 'Every 14 days; 7-day payout add-on available', 3::integer, true, true, '{"account_size_prices":[{"account_size":5000,"fee":30,"currency":"USD"},{"account_size":10000,"fee":49,"currency":"USD"},{"account_size":25000,"fee":100,"currency":"USD"},{"account_size":50000,"fee":150,"currency":"USD"},{"account_size":100000,"fee":298,"currency":"USD"},{"account_size":200000,"fee":552,"currency":"USD"}],"payout_rules":"Base funded split 85%; 90% add-on available. Standard payout cycle is every 14 days; a 7-day add-on is available. Minimum payout is $100 via crypto or $500 via Rise. Requests are processed within 24 business hours. One-percent withdrawal buffer applies after trailing drawdown locks at breakeven.","fee_refund_policy":"The official Forex selector displayed current prices on 2026-09-28 with a 25% BG25 promotion banner. The per-size schedule records the price displayed as payable; standard crossed-out prices were $40, $66, $134, $200, $398, and $736 for the listed sizes. Promotion may expire. Challenge fee is refundable after the fourth payout for accounts purchased from 2026-01-21 onward; no refund if the account breaches first.","consistency_rule":"No funded consistency rule is stated on the current 1-Step Standard rules page.","prohibited_strategies":"Funded trading around high-impact news is restricted within five minutes before/after the event. The minimum trade holding time is 2 minutes. Stop loss is not mandatory. EAs are allowed; copy trading only between accounts owned by the same trader.","commission_details":"FX commission is $5 per lot according to current platform rules. Spreads vary by market conditions and platform.","time_limit":"No evaluation time limit. Account inactivity rule requires a trade at least once every 30 days.","current_rule_variants":"The 9% target and three qualifying profitable days apply to accounts purchased from 2026-08-20 onward; older purchases retain the former 10% target and five-day rule."}'),
  ('Blue Guardian 1-Step Nano', '1-step-nano', 'evaluation', 'Single-phase Forex evaluation with a 10% target, 4% daily loss limit, and 6% trailing maximum loss that locks at starting balance after 6% growth.', '[5000,10000,25000,50000,100000,200000]', 50::numeric, 85::numeric, 'Every 7 days', 0::integer, true, true, '{"account_size_prices":[{"account_size":5000,"fee":20,"currency":"USD"},{"account_size":10000,"fee":29,"currency":"USD"},{"account_size":25000,"fee":59,"currency":"USD"},{"account_size":50000,"fee":120,"currency":"USD"},{"account_size":100000,"fee":240,"currency":"USD"},{"account_size":200000,"fee":438,"currency":"USD"}],"payout_rules":"Base funded split 85%; official rules list an optional 100% add-on. Payout cycle every 7 days; minimum withdrawal $100 via crypto or $500 via Rise. One-percent withdrawal buffer applies after drawdown locks at breakeven.","fee_refund_policy":"The official Forex selector displayed current payable fees on 2026-09-28 with a 25% BG25 promotion banner. Standard crossed-out prices were $26.66, $38.66, $78.66, $160, $320, and $585 for the listed sizes. Promotion may expire. Fee-refund policy for completed evaluation accounts: after the fourth payout for purchases from 2026-01-21 onward; forfeited if hard-breached sooner.","consistency_rule":"50% consistency applies during both the challenge and funded stages. Five qualifying profitable days are required for funded payout eligibility; evaluation has no minimum-day requirement.","prohibited_strategies":"Funded news trading restricted five minutes before/after high-impact events. Minimum trade holding time is 2 minutes. Stop loss is not mandatory; EAs and weekend holding are allowed. Copy trades may only be between accounts owned by the same trader.","commission_details":"FX commission is $5 per lot according to current platform rules; spreads vary by platform and conditions.","time_limit":"No evaluation time limit. A trade is required at least once every 30 days.","payout_buffer":"A 1% fixed buffer applies once the 6% trailing drawdown locks at the initial balance."}'),
  ('Blue Guardian 2-Step Standard', '2-step-standard', 'evaluation', 'Two-phase Forex evaluation with 8% then 4% targets, 4% daily loss, and 8% static maximum loss.', '[5000,10000,25000,50000,100000,200000]', 50::numeric, 85::numeric, 'Every 14 days; 7-day payout add-on available', 3::integer, true, true, '{"account_size_prices":[{"account_size":5000,"fee":24,"currency":"USD"},{"account_size":10000,"fee":56,"currency":"USD"},{"account_size":25000,"fee":115,"currency":"USD"},{"account_size":50000,"fee":174,"currency":"USD"},{"account_size":100000,"fee":347,"currency":"USD"},{"account_size":200000,"fee":697,"currency":"USD"}],"payout_rules":"Base funded split 85%; 90% add-on available. Standard payout cycle every 14 days; optional 7-day add-on. Minimum withdrawal $100 via crypto or $500 via Rise. Processing within 24 business hours. Guardian Shield auto-closes trades at 2% aggregate floating loss; first trigger reduces profit share to 50%, second permanently breaches the account.","fee_refund_policy":"The official Forex selector displayed current payable fees on 2026-09-28 with a 25% BG25 promotion banner. Standard crossed-out prices were $32, $75, $154, $232, $463, and $930 for the listed sizes. Promotion may expire. Challenge fee is refundable after the fourth payout for purchases from 2026-01-21 onward, unless the account breaches first.","consistency_rule":"No funded consistency percentage is stated in the current 2-Step Standard rules page.","prohibited_strategies":"Challenge news trading allowed; funded high-impact news trading restricted within five minutes before/after event. Overnight and weekend holding allowed; EAs allowed; copy trading only between accounts owned by same trader. Minimum trade duration is 2 minutes.","commission_details":"FX commission is $5 per lot under current platform rules; spreads vary by platform and conditions.","time_limit":"No evaluation deadline. Account inactivity breach applies after 30 days without a trade.","current_rule_variants":"For purchases from 2026-08-20, three qualifying profitable days of at least 0.5% are required to pass; older purchases retain a five-day rule."}'),
  ('Blue Guardian 2-Step Nano', '2-step-nano', 'evaluation', 'Two-phase Forex evaluation with 8% then 5% targets, 3% daily loss, and 10% static maximum loss.', '[25000,50000,100000,200000]', 50::numeric, 80::numeric, 'Every 14 days', 0::integer, true, true, '{"account_size_prices":[{"account_size":25000,"fee":50,"currency":"USD"},{"account_size":50000,"fee":95,"currency":"USD"},{"account_size":100000,"fee":179,"currency":"USD"},{"account_size":200000,"fee":345,"currency":"USD"}],"payout_rules":"Funded split is 80%. Payouts every 14 days. Maximum payout per cycle is 2% of initial balance. Minimum withdrawal is $100 via crypto or $500 via Rise; processing within 24 business hours.","fee_refund_policy":"The official Forex selector displayed current payable fees on 2026-09-28 with a 25% BG25 promotion banner. Standard crossed-out prices were $66.66, $127, $239, and $460 for the listed sizes. Promotion may expire. Completed evaluation fee is refundable after the fourth payout for purchases from 2026-01-21 onward; no refund if breached before then.","consistency_rule":"50% consistency applies to the funded stage only. No minimum trading days for evaluation or payout eligibility.","prohibited_strategies":"Challenge news trading allowed; funded high-impact news trading restricted within five minutes before/after events. Overnight/weekend holding and EAs are allowed; copy trading only among accounts owned by the same person. Trade holding minimum is 2 minutes.","commission_details":"FX commission is $5 per lot under current platform rules; spreads vary by conditions and platform.","time_limit":"No evaluation time limit; one trade at least once every 30 days is required to avoid inactivity breach."}'),
  ('Blue Guardian Instant Standard', 'instant-standard', 'instant_funding', 'Immediate simulated Forex funding with no evaluation, 3% daily loss, and 6% trailing maximum loss that locks at starting balance after 6% growth.', '[5000,10000,25000,50000,100000,200000,300000,400000]', 30::numeric, 80::numeric, 'Instant payout eligibility after required trading days and consistency conditions', 5::integer, false, true, '{"account_size_prices":[{"account_size":5000,"fee":54,"currency":"USD"},{"account_size":10000,"fee":75,"currency":"USD"},{"account_size":25000,"fee":156,"currency":"USD"},{"account_size":50000,"fee":243,"currency":"USD"},{"account_size":100000,"fee":467,"currency":"USD"},{"account_size":200000,"fee":716,"currency":"USD"},{"account_size":300000,"fee":1284,"currency":"USD"},{"account_size":400000,"fee":1650,"currency":"USD"}],"payout_rules":"Base profit share is 80%; optional 90% add-on. Instant payout eligibility after five qualifying profitable days (each at least 0.5%) and applicable consistency conditions. Minimum withdrawal $100 via crypto or $500 via Rise; processing within 24 business hours. One-percent buffer after trailing loss locks at initial balance. First two payouts on $200K, $300K and $400K accounts are capped at $10,000 each.","fee_refund_policy":"The official Forex selector displayed current payable fees on 2026-09-28 with a 25% BG25 promotion banner. Standard crossed-out prices were $72, $100, $208, $324, $623, $954, $1,712, and $2,200 for the listed sizes. Promotion may expire. Instant accounts are excluded from the evaluation-fee refund policy.","consistency_rule":"20% consistency for standard sizes; official rules specify a 15% rule for $300K and $400K Instant accounts.","prohibited_strategies":"News trading is prohibited for purchases after 2025-11-13 (rules were different for older accounts). EAs and overnight/weekend holding are allowed. Guardian Shield auto-closes at 1% floating loss; first event reduces split to 50%, second permanently breaches. Minimum trade duration is 2 minutes.","commission_details":"FX commission is $5 per lot under platform rules; spreads vary by conditions and platform.","time_limit":"No evaluation time limit. Inactivity breach after 30 days without a trade.","account_size_note":"The dynamic Forex selector displayed sizes from $5K through $400K excluding $150K; the general Help Center lists $150K among firm-wide account sizes, but this size was not displayed for Instant in the selector."}'),
  ('Blue Guardian Instant Starter', 'instant-starter', 'instant_funding', 'One-time $5,000 instant-funded Forex account with 3% daily loss, 5% trailing maximum loss, one payout, and a $250 maximum profit cap.', '[5000]', 30::numeric, 90::numeric, 'One instant payout only', 5::integer, true, true, '{"account_size_prices":[{"account_size":5000,"fee":14.67,"currency":"USD"}],"payout_rules":"Fixed 90% split; instant payout after five qualifying profitable days of at least 0.5%. One payout only. $250 maximum total profit/payout cap; account closes after payout. Minimum payout $100 via crypto or $500 via Rise.","fee_refund_policy":"Dedicated checkout displayed a $14.67 subtotal before the advertised BG25 coupon. Applying the 25% coupon yields approximately $11.00, matching the current product landing-page headline; promotional price may change. Instant Starter is excluded from the evaluation-fee refund policy. Only one purchase is allowed per trader.","consistency_rule":"15% payout consistency threshold.","prohibited_strategies":"News trading, overnight/weekend holding, and EAs are allowed. Guardian Shield auto-closes at 1% aggregate floating loss. Minimum trade holding time is 2 minutes.","commission_details":"FX commission is $5 per lot under current platform rules; spreads vary by conditions and platform.","time_limit":"No evaluation period; account is limited to one payout. One trade at least once every 30 days is required unless account is already closed after payout."}')
) as item(name, slug, program_type, description, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details) on true
where firms.slug = 'blue-guardian'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = 'published', currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = coalesce(bullish_banana.programs.published_at, now()), archived_at = null, updated_at = now();

-- Keep Standard 1-Step unpublished until an official leverage conflict is resolved:
-- the live selector showed 1:100, while the current platform-rules page says 1:50.
update bullish_banana.programs
set status = 'in_review', published_at = null,
    commercial_details = commercial_details || '{"leverage_source_conflict":"Live Forex selector showed 1:100 maximum for 1-Step Standard (100K selection) on 2026-09-28; Blue Guardian Platform Rules dated 2026-08-21 specify 1:50 for 1-Step evaluation. Verify selected platform/account configuration before publication."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian')
  and slug = '1-step-standard';

insert into bullish_banana.program_phases (
  program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss,
  phase.max_loss, phase.drawdown_type, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'blue-guardian'
join (values
  ('1-step-standard',1,'Evaluation',9.000::numeric,4.000::numeric,6.000::numeric,'trailing',3::integer,'{"qualifying_day_profit_percent":0.5,"target_applies_to":"Accounts purchased from 2026-08-20 onward; older purchases retain 10% target and five days.","source_note":"Official current rules page states 9% target, 4% daily loss, 6% trailing maximum loss. Drawdown locks at initial balance once account gains 6%."}'),
  ('1-step-nano',1,'Evaluation',10.000::numeric,4.000::numeric,6.000::numeric,'trailing',0::integer,'{"qualifying_day_profit_percent":0.5,"source_note":"10% target, 4% daily drawdown, 6% trailing max loss. No minimum evaluation days; minimum five qualifying days apply to funded payout eligibility. 50% consistency applies to evaluation and funded stages."}'),
  ('2-step-standard',1,'Phase 1',8.000::numeric,4.000::numeric,8.000::numeric,'static',3::integer,'{"qualifying_day_profit_percent":0.5,"minimum_days_variant":"3 days for purchases from 2026-08-20; five days for older purchases."}'),
  ('2-step-standard',2,'Phase 2',4.000::numeric,4.000::numeric,8.000::numeric,'static',3::integer,'{"qualifying_day_profit_percent":0.5,"minimum_days_variant":"3 days for purchases from 2026-08-20; five days for older purchases."}'),
  ('2-step-nano',1,'Phase 1',8.000::numeric,3.000::numeric,10.000::numeric,'static',0::integer,'{"source_note":"8% target, 3% daily loss, 10% static max loss. No minimum evaluation trading days."}'),
  ('2-step-nano',2,'Phase 2',5.000::numeric,3.000::numeric,10.000::numeric,'static',0::integer,'{"source_note":"5% target, 3% daily loss, 10% static max loss. No minimum evaluation trading days."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, minimum_days, raw_rules) on phase.program_slug = programs.slug
where programs.slug in ('1-step-standard','1-step-nano','2-step-standard','2-step-nano')
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, minimum_trading_days = excluded.minimum_trading_days,
    raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('MetaTrader 5', 'metatrader-5'), ('Match-Trader', 'match-trader'), ('TradeLocker', 'tradelocker')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'blue-guardian'
cross join bullish_banana.platforms
where programs.slug in ('1-step-standard','1-step-nano','2-step-standard','2-step-nano','instant-standard','instant-starter')
  and platforms.slug in ('metatrader-5','match-trader','tradelocker')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://blueguardian.com/forex','Blue Guardian official Forex offers and pricing','Current Forex selector reviewed 2026-09-28 lists Instant, 1-Step Standard, 1-Step Nano, 2-Step Standard and 2-Step Nano. Displayed per-size payable fee and crossed standard-price matrix captured for each selector. Banner advertised BG25/25% off; displayed promotion may expire.'),
  ('https://blueguardian.com/futures','Blue Guardian official Futures market','Main site footer links to a separate Futures market; firm membership is represented, but no Futures program is added by this Forex migration.'),
  ('https://help.blueguardian.com/en/articles/15618204-general-information-rules','Blue Guardian general account and company information','Current rules describe simulated trading, account-size list, firm restrictions, $400K active allocation and fee refund after fourth payout for completed evaluations bought from 2026-01-21. Scaling section gives a conflicting maximum versus the preceding allocation section; not normalized to one value.'),
  ('https://help.blueguardian.com/en/articles/9661525-platform-rules','Blue Guardian platforms, instruments, leverage and commissions','Rules dated 2026-08-21 list MT5, Match-Trader and TradeLocker; U.S. platform restrictions; Forex, indices, gold/commodities and crypto markets; per-model leverage and $5 Forex commission per lot.'),
  ('https://blueguardian.com/terms-and-conditions','Blue Guardian official terms and disclosures','Main-site terms disclose simulated/demo trading, company entities and prohibited practices.'),
  ('https://checkout.blueguardian.com/instant-starter/','Blue Guardian Instant Starter checkout','Dedicated $5K Instant Starter checkout currently displays a $14.67 subtotal before advertised BG25 25% coupon; landing page promotes an $11 price.'),
  ('https://blueguardian.com/instant-funding-starter','Blue Guardian Instant Starter offer page','Official offer page promotes the $5K Instant Starter at $11; its checkout displays a $14.67 subtotal before BG25 promotion.'),
  ('https://help.blueguardian.com/en/collections/18967956-account-models','Blue Guardian official CFD account models','Current Help Center account collection distinguishes active Standard/Nano/Instant products from legacy Pro/3-Step models; legacy models are not treated as current offers.'),
  ('https://help.blueguardian.com/en/articles/9660857-how-do-payouts-work','Blue Guardian official payout and refund rules','Current payout rules cover payout windows, payment minimums, processing fee, account-size reward caps, and fixed Instant Starter terms.')
) as source(url, label, notes) on true
where firms.slug = 'blue-guardian'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'blue-guardian'
join (values
  ('1-step-standard','https://help.blueguardian.com/en/articles/14062186-1-step-standard-rules','Blue Guardian 1-Step Standard rules','Updated 2026-09; current 9% target and three qualifying days apply to purchases from 2026-08-20. Includes drawdown lock, funded news restriction, payout, refund, and risk rules.'),
  ('1-step-nano','https://help.blueguardian.com/en/articles/16444654-1-step-nano-rules','Blue Guardian 1-Step Nano rules','Current Nano rules specify 10% target, 4% daily loss, 6% trailing drawdown, no evaluation minimum days, payout days, consistency, and add-on rules.'),
  ('2-step-standard','https://help.blueguardian.com/en/articles/14062291-2-step-standard-rules','Blue Guardian 2-Step Standard rules','Current rules specify 8%/4% phase targets, 4% daily loss, 8% static max loss, time-dependent minimum-day term, payout, news, and weekend rules.'),
  ('2-step-nano','https://help.blueguardian.com/en/articles/16445450-2-step-nano-rules','Blue Guardian 2-Step Nano rules','Current rules specify 8%/5% targets, 3% daily loss, 10% static max loss, no minimum days, funded 50% consistency, and capped payouts.'),
  ('instant-standard','https://help.blueguardian.com/en/articles/14061082-instant-standard-account-rules','Blue Guardian Instant Standard rules','Current no-evaluation offer with 3% daily/6% trailing limits, 20% consistency (15% for $300K/$400K), reward conditions, and account restrictions.'),
  ('instant-starter','https://help.blueguardian.com/en/articles/14061939-instant-starter','Blue Guardian Instant Starter rules','Fixed $5K one-time offer: 3% daily/5% trailing drawdown, one payout, $250 cap, and 90% share.'),
  ('instant-starter','https://checkout.blueguardian.com/instant-starter/','Blue Guardian Instant Starter current checkout price','Official checkout displayed $14.67 before applying BG25; a 25% discount brings the price to about $11.00. Fee is recorded with this promotion context.'),
  ('1-step-standard','https://help.blueguardian.com/en/articles/9661525-platform-rules','Blue Guardian leverage and platform rules','Rules dated August 21, 2026 specify 1:50 Forex evaluation leverage for 1-Step, conflicting with 1:100 shown by the current Forex selector; Standard 1-Step stays in review pending verification.')
) as source(slug, url, label, notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reverified Blue Guardian against first-party Forex offers, terms, CFD rules, platform documentation and payout rules on 2026-09-28. Company disclosure, simulated trading model, supported assets/platforms, restricted countries, and current account families are captured. Conflicting scaling maximums are noted.'
from bullish_banana.firms where slug = 'blue-guardian';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified current Blue Guardian Forex selector fees and first-party account rules on 2026-09-28. Selector prices record the displayed payable offer while the commercial note retains the crossed standard fee and observed promotion; both should be refreshed before promo expiry. All stage-specific available rules are captured.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'blue-guardian'
where programs.slug in ('1-step-standard','1-step-nano','2-step-standard','2-step-nano','instant-standard','instant-starter');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'View ' || programs.name,
  case programs.slug
    when 'instant-starter' then 'https://checkout.blueguardian.com/instant-starter/'
    else 'https://blueguardian.com/forex'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'blue-guardian'
  and programs.slug in ('1-step-standard','1-step-nano','2-step-standard','2-step-nano','instant-standard','instant-starter')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
