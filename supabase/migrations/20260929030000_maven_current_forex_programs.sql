-- Publish Maven Trading's current first-party Forex offer families.
-- Researched from the official site, pricing, FAQ and terms on 2026-09-28.
-- Unknown values remain null or are described as not stated; terms-page conflicts
-- are preserved in the relevant rule fields and source notes.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set name = 'Maven Trading',
    description = 'Maven Trading offers simulated Forex evaluations and funded-account programs, including multi-phase, instant, and direct-funded options.',
    website_url = 'https://maventrading.com/',
    status = 'published', published_at = coalesce(published_at, now()), archived_at = null, updated_at = now()
where slug = 'maven-trading';

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'maven-trading'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'AE', 'MAVEN LLC', array['Forex']::text[],
  '{"service_model":"Maven describes its accounts and performance as simulated evaluations, not investment services or customer investment accounts.","established_year":2022,"platforms_disclosed_at_firm_level":["MetaTrader 5","Match-Trader"],"platform_scope_note":"Official terms list both integrations but do not establish that every challenge tier supports both. MetaTrader is unavailable to U.S. and Canadian residents; Match-Trader availability by account and region should be confirmed at checkout.","legal_entity_conflict":"Terms identify MAVEN LLC (UAE/DIEZ, registration 105072496000001); the same site footer also identifies Maven Edu - FZCO (UAE, registration 006-0060823-070425). The relationship and offer-specific seller are not established by the public pages.","instrument_details":"Official FAQ lists more than 400 instrument options, including Forex pairs. Forex commission is $2 per side, variable spreads, and no swap fees are stated."}'::jsonb
from bullish_banana.firms where slug = 'maven-trading'
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
select f.id, p.name, p.slug, p.description, p.program_type, 'forex', 'published', 'USD',
       p.account_sizes::jsonb, null::numeric, p.profit_split_percent, p.payout_frequency,
       p.minimum_trading_days, p.news_allowed, true, p.commercial_details::jsonb, now(), null
from bullish_banana.firms f
join (values
  ('Standard 1-Step', 'standard-1-step', 'Single-phase simulated Forex evaluation with an 8% target, 5% trailing maximum loss, and 3% daily loss limit.', 'evaluation', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 80::numeric, 'Every 10 business days', null::integer, false, '{"account_size_prices":[{"account_size":2000,"fee":14,"currency":"USD"},{"account_size":5000,"fee":18,"currency":"USD"},{"account_size":10000,"fee":34,"currency":"USD"},{"account_size":20000,"fee":62,"currency":"USD"},{"account_size":50000,"fee":153,"currency":"USD"},{"account_size":100000,"fee":342,"currency":"USD"}],"payout_rules":"Homepage and pricing state payouts every 10 business days. Fee cards show a current/coupon amount and a comparison amount; the current displayed amount is recorded as the fee. Prices are region-sensitive and were captured 2026-09-28.","fee_refund_policy":"Pricing and terms describe a full evaluation-fee refund after the third withdrawal/payout. Terms also state payments are nonrefundable except for this qualifying refund; retain both the offer wording and legal exception.","consistency_rule":"Not stated for this program in the cited official sources.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; the terms also contain an earlier approval clause, so confirm application if needed.","prohibited_strategies":"Terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior. FAQ defines excessive scalping as 50% or more trades held under one minute.","commission_details":"Forex commission $2 per side ($4 round trip); variable spreads; zero swap fees, per official FAQ. Standard plans have a red-folder news restriction 2 minutes before and after the event per FAQ/terms; weekend holding is allowed."}'),
  ('Standard 2-Step', 'standard-2-step', 'Two-phase simulated Forex evaluation with 8% and 5% targets, 8% static maximum loss, and 4% daily loss.', 'evaluation', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 80::numeric, 'Every 10 business days', 3, false, '{"account_size_prices":[{"account_size":2000,"fee":18,"currency":"USD"},{"account_size":5000,"fee":20,"currency":"USD"},{"account_size":10000,"fee":40,"currency":"USD"},{"account_size":20000,"fee":80,"currency":"USD"},{"account_size":50000,"fee":198,"currency":"USD"},{"account_size":100000,"fee":396,"currency":"USD"}],"payout_rules":"Payout every 10 business days. After evaluation pass, compliance review is stated as 1–3 days. Prices are current values displayed on the official card and were captured 2026-09-28.","fee_refund_policy":"Pricing and terms describe a full evaluation-fee refund after the third withdrawal/payout. Terms also state payments are nonrefundable except for this qualifying refund.","consistency_rule":"No funded consistency rule is stated for this model in the reviewed pages.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; the terms also contain an earlier approval clause, so confirm application if needed.","prohibited_strategies":"Terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior. FAQ defines excessive scalping as 50% or more trades held under one minute.","commission_details":"Forex commission $2 per side ($4 round trip); variable spreads; zero swap fees, per official FAQ. Daily loss is measured against the higher of balance or equity at 00:00 UTC. Three profitable days of at least 0.5% are required in each evaluation phase and funded stage. Standard plans have a red-folder news restriction 2 minutes before and after the event; weekend holding is allowed."}'),
  ('Standard 3-Step', 'standard-3-step', 'Three-phase simulated Forex evaluation with a 3% target in each phase, 3% static maximum loss, and 2% daily loss.', 'evaluation', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 80::numeric, 'Every 10 business days', null::integer, false, '{"account_size_prices":[{"account_size":2000,"fee":12,"currency":"USD"},{"account_size":5000,"fee":16,"currency":"USD"},{"account_size":10000,"fee":35,"currency":"USD"},{"account_size":20000,"fee":69,"currency":"USD"},{"account_size":50000,"fee":171,"currency":"USD"}],"payout_rules":"Pricing states payouts every 10 business days. No model-specific minimum profitable-day rule was found in the reviewed official FAQ excerpt. The official $100K account option did not have a safely verified displayed price pair on capture date.","fee_refund_policy":"Pricing and terms describe a full evaluation-fee refund after the third withdrawal/payout. Terms also state payments are nonrefundable except for this qualifying refund.","consistency_rule":"Not stated for this program in the cited official sources.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; the terms also contain an earlier approval clause, so confirm application if needed.","prohibited_strategies":"Terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior.","commission_details":"Forex commission $2 per side ($4 round trip); variable spreads; zero swap fees, per official FAQ. Standard plans have a red-folder news restriction 2 minutes before and after the event; weekend holding is allowed."}'),
  ('Instant', 'instant', 'Immediate simulated Forex funding with no evaluation; a 3% profit threshold is required before requesting a withdrawal.', 'instant_funding', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 80::numeric, 'Every 10 business days per terms; product-page timing differs', null::integer, null::boolean, '{"account_size_prices":[{"account_size":2000,"fee":14,"currency":"USD"},{"account_size":5000,"fee":20,"currency":"USD"},{"account_size":10000,"fee":34,"currency":"USD"},{"account_size":20000,"fee":62,"currency":"USD"},{"account_size":50000,"fee":153,"currency":"USD"},{"account_size":100000,"fee":342,"currency":"USD"}],"payout_rules":"No evaluation. A 3% minimum profit is required to request a withdrawal. Product page says withdrawals are available when requirements are met; terms say every 10 business days. Preserve this payout-cadence conflict and verify the live agreement.","consistency_rule":"20% consistency score: largest winning day divided by total profit, per official pricing and FAQ.","prohibited_strategies":"One-percent floating-loss/risk cap applies. Terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior. News rules conflict: FAQ describes an Instant exemption; terms apply red-folder news restrictions to all accounts. News permission is therefore unknown pending resolution.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; the terms also contain an earlier approval clause, so confirm application if needed.","commission_details":"Forex commission $2 per side ($4 round trip); variable spreads; zero swap fees, per official FAQ. Weekend holding is allowed."}'),
  ('Buy Now Pay Later', 'buy-now-pay-later', 'One-phase Forex evaluation with a $5 initial payment and a remaining fee due after passing.', 'evaluation', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 80::numeric, 'Pricing labels funded payout as instant; confirm timing at checkout', null::integer, false, '{"account_size_prices":[{"account_size":2000,"fee":45,"currency":"USD"},{"account_size":5000,"fee":74,"currency":"USD"},{"account_size":10000,"fee":122,"currency":"USD"},{"account_size":20000,"fee":194,"currency":"USD"},{"account_size":50000,"fee":364,"currency":"USD"},{"account_size":100000,"fee":594,"currency":"USD"}],"payout_rules":"Total challenge fees are $45, $74, $122, $194, $364, and $594 by ascending account size. Maven pricing presents the payment as $5 now plus $40, $69, $117, $189, $359, or $589 due after passing. Funded payout is labeled Instant on the pricing card; confirm timing at checkout.","fee_refund_policy":"Pricing states the challenge fee is refunded at the third withdrawal. The amount shown in account-size prices is the total staged challenge cost, not only the initial $5 payment.","consistency_rule":"20% consistency applies to the funded stage per official pricing/FAQ.","prohibited_strategies":"The official terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; an earlier approval clause also appears in the terms.","commission_details":"Funded-stage limits: 8% maximum loss, 4% daily loss. Evaluation target 4%, maximum loss 10%; no evaluation daily-loss amount was shown in the cited pricing source. Forex commission $2 per side, variable spreads, and zero swaps per official FAQ."}'),
  ('Omo 2-Step', 'omo-2-step', 'Two-phase simulated Forex evaluation with a 6% Phase 1 target and an 8% Phase 2 target.', 'evaluation', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 80::numeric, 'Every 10 business days', null::integer, false, '{"account_size_prices":[{"account_size":2000,"fee":9,"currency":"USD"},{"account_size":5000,"fee":15,"currency":"USD"},{"account_size":10000,"fee":38,"currency":"USD"},{"account_size":20000,"fee":74,"currency":"USD"},{"account_size":50000,"fee":143,"currency":"USD"},{"account_size":100000,"fee":284,"currency":"USD"}],"payout_rules":"Payout every 10 business days per official pricing. Pricing advertises code OMO for 40% off, but the displayed current/comparison price pair does not consistently match that percentage; the displayed current amount is stored as the fee and no discount is calculated.","fee_refund_policy":"Pricing and terms describe an evaluation-fee refund after the third withdrawal/payout; terms also state payments are generally nonrefundable except for this qualifying refund.","consistency_rule":"Not stated for this program in the cited official sources.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; the terms also contain an earlier approval clause, so confirm application if needed.","prohibited_strategies":"Terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior.","commission_details":"Forex commission $2 per side ($4 round trip); variable spreads; zero swap fees, per official FAQ. Challenge rules show 8% maximum loss and 4% daily loss; weekend holding is allowed."}'),
  ('Mini', 'mini', 'Direct-funded one-time simulated Forex account with one payout after at least 3% profit.', 'instant_funding', '[{"account_size":2000,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":20000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 70::numeric, 'One payout after the trading period', null::integer, false, '{"account_size_prices":[{"account_size":2000,"fee":16,"currency":"USD"},{"account_size":5000,"fee":20,"currency":"USD"},{"account_size":10000,"fee":34,"currency":"USD"},{"account_size":20000,"fee":80,"currency":"USD"},{"account_size":50000,"fee":198,"currency":"USD"},{"account_size":100000,"fee":396,"currency":"USD"}],"payout_rules":"One payout after the account''s 24-hour trading period ends; payout is processed the next day. Minimum 3% profit is required and the account closes after payout.","consistency_rule":"15% largest-winning-trade consistency rule.","prohibited_strategies":"One position/trade at a time and 150-second minimum hold. The official terms prohibit reverse/group hedging, high-frequency/tick scalping, grid/gap trading, account sharing, and gamified or all-in behavior.","copy_trading_rule":"Copy trading and account sharing are prohibited by the official terms.","ea_rule":"Automated trading / EAs are not permitted under the terms; an earlier approval clause also appears in the terms.","commission_details":"3% maximum loss and 2% daily loss. Forex commission $2 per side, variable spreads, and zero swaps per official FAQ. Weekend holding is allowed."}')
) as p(name, slug, description, program_type, account_sizes, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, commercial_details) on true
where f.slug = 'maven-trading'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'published', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = coalesce(bullish_banana.programs.published_at, now()), archived_at = null, updated_at = now();

-- Preserve Maven BNPL's $5 due at purchase separately from the balance due after passing.
update bullish_banana.programs p
set commercial_details = jsonb_set(
  p.commercial_details,
  '{account_size_prices}',
  '[{"account_size":2000,"fee":5,"post_pass_fee":40,"currency":"USD"},{"account_size":5000,"fee":5,"post_pass_fee":69,"currency":"USD"},{"account_size":10000,"fee":5,"post_pass_fee":117,"currency":"USD"},{"account_size":20000,"fee":5,"post_pass_fee":189,"currency":"USD"},{"account_size":50000,"fee":5,"post_pass_fee":359,"currency":"USD"},{"account_size":100000,"fee":5,"post_pass_fee":589,"currency":"USD"}]'::jsonb
)
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'maven-trading' and p.slug = 'buy-now-pay-later';

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.maximum_loss, x.drawdown_type, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('standard-1-step', 1, 'Evaluation', 8.000::numeric, 3.000::numeric, 5.000::numeric, 'trailing', null::integer, '{"source_note":"Official Maven pricing, FAQ and terms state an 8% target, 3% daily loss and 5% trailing maximum loss. Time limit and minimum trading days are not stated in the reviewed source set."}'),
  ('standard-2-step', 1, 'Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3, '{"source_note":"Official Maven sources state an 8% target, 4% daily loss, 8% static maximum loss, and three profitable days of at least 0.5%. Daily loss uses the higher balance/equity at 00:00 UTC."}'),
  ('standard-2-step', 2, 'Phase 2', 5.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3, '{"source_note":"Official Maven sources state a 5% target and the same daily and maximum loss rules as Phase 1; three profitable days of at least 0.5%."}'),
  ('standard-3-step', 1, 'Phase 1', 3.000::numeric, 2.000::numeric, 3.000::numeric, 'static', null::integer, '{"source_note":"Official Maven sources state a 3% target per phase, 2% daily loss, and 3% static maximum loss. Minimum profitable days not stated in the reviewed FAQ excerpt."}'),
  ('standard-3-step', 2, 'Phase 2', 3.000::numeric, 2.000::numeric, 3.000::numeric, 'static', null::integer, '{"source_note":"Official Maven sources state a 3% target per phase, 2% daily loss, and 3% static maximum loss. Minimum profitable days not stated in the reviewed FAQ excerpt."}'),
  ('standard-3-step', 3, 'Phase 3', 3.000::numeric, 2.000::numeric, 3.000::numeric, 'static', null::integer, '{"source_note":"Official Maven sources state a 3% target per phase, 2% daily loss, and 3% static maximum loss. Minimum profitable days not stated in the reviewed FAQ excerpt."}'),
  ('buy-now-pay-later', 1, 'Evaluation', 4.000::numeric, null::numeric, 10.000::numeric, 'static', null::integer, '{"source_note":"Official pricing shows a 4% evaluation target and 10% maximum loss; no evaluation daily-loss amount or minimum trading-day requirement was stated."}'),
  ('omo-2-step', 1, 'Phase 1', 6.000::numeric, 4.000::numeric, 8.000::numeric, 'static', null::integer, '{"source_note":"Official Maven pricing states a 6% Phase 1 target, 4% daily loss, and 8% maximum loss. Minimum profitable days not found in the official FAQ excerpt."}'),
  ('omo-2-step', 2, 'Phase 2', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', null::integer, '{"source_note":"Official Maven pricing states an 8% Phase 2 target, 4% daily loss, and 8% maximum loss. Minimum profitable days not found in the official FAQ excerpt."}')
) as x(program_slug, phase_number, name, target, daily_loss, maximum_loss, drawdown_type, days, rules)
  on x.program_slug = p.slug
where f.slug = 'maven-trading'
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
  ('https://maventrading.com/', 'Maven Trading official website', 'Current product navigation advertises Forex challenge products; the FAQ says Maven has operated since 2022 and describes simulated accounts.'),
  ('https://maventrading.com/faqs', 'Maven Trading FAQ', 'First-party Forex instruments, commission, weekend, inactivity, trading restrictions, payout rules, and product-specific help content. FAQ and terms differ on Instant news exemptions.'),
  ('https://maventrading.com/terms-and-conditions', 'Maven Trading terms', 'First-party terms identify simulated evaluation services, MAVEN LLC, account rules, restrictions, payout conditions, platforms, and fee/refund terms. Footer names a second Maven entity.')
) as x(url, label, notes) on true
where f.slug = 'maven-trading'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://maventrading.com/pricing', 'Maven Trading pricing — ' || p.name,
       'First-party pricing and offer card captured 2026-09-28. Per-size prices record the current/coupon amount shown on the card. The card also shows a comparison amount; these prices are region-sensitive and may change. Standard 3-Step $100K displayed pair could not be safely verified.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.slug in ('standard-1-step','standard-2-step','standard-3-step','instant','buy-now-pay-later','omo-2-step','mini')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://maventrading.com/pricing');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('standard-1-step', 'https://maventrading.com/terms-and-conditions', 'Maven Standard 1-Step terms', 'Official terms and pricing give 8% target, 3% daily loss, 5% trailing maximum loss, 80% split, and ten-business-day payout schedule.'),
  ('standard-2-step', 'https://maventrading.com/terms-and-conditions', 'Maven Standard 2-Step terms', 'Official terms, FAQ and pricing give phase targets, daily/static loss rules, profitable-day conditions, split, payout timing, and red-folder news restrictions.'),
  ('standard-3-step', 'https://maventrading.com/terms-and-conditions', 'Maven Standard 3-Step terms', 'Official terms and pricing give 3% targets across three phases, 2% daily loss, 3% static maximum loss, and 80% split; minimum days were not stated in the reviewed FAQ excerpt.'),
  ('instant', 'https://maventrading.com/faqs', 'Maven Instant FAQ', 'Official FAQ/pricing state no evaluation, 3% withdrawal-profit threshold, 3% trailing loss, 2% daily loss, 1% floating-risk cap, 20% consistency and 80% split. News and payout cadence conflict with terms.'),
  ('buy-now-pay-later', 'https://maventrading.com/pricing', 'Maven Buy Now Pay Later pricing', 'Official pricing states $5 now and size-dependent remainder due after passing; refund at third withdrawal; funded stage shows 8% maximum loss, 4% daily loss, 20% consistency and 80% split. No evaluation daily-loss value was found.'),
  ('omo-2-step', 'https://maventrading.com/pricing', 'Maven Omo 2-Step pricing', 'Official pricing states targets, drawdown limits, 80% split and ten-business-day payouts; code OMO promotion wording does not consistently match displayed price pairs.'),
  ('mini', 'https://maventrading.com/faqs', 'Maven Mini FAQ', 'Official pricing and FAQ describe direct-funded single-payout rules, 3% target, 3% max loss, 2% daily loss, 70% split, 15% consistency, one position, 150-second hold, and one-day payout processing.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'maven-trading'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url and s.source_label = x.label);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(), 'Firm identity, active offer menu, simulated-service disclosure, source dates, and known legal-entity conflict reviewed against first-party Maven pages on 2026-09-28.'
from bullish_banana.firms f
where f.slug = 'maven-trading'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Current program rules and displayed per-size fee observations reviewed on 2026-09-28 against Maven first-party pricing, FAQ and terms. Unknown fields remain unstated; Instant news/payout and legal/refund source conflicts are recorded in commercial details and source notes.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'maven-trading'
  and p.slug in ('standard-1-step','standard-2-step','standard-3-step','instant','buy-now-pay-later','omo-2-step','mini')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at Maven Trading', 'https://maventrading.com/pricing', true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'maven-trading'
  and p.slug in ('standard-1-step','standard-2-step','standard-3-step','instant','buy-now-pay-later','omo-2-step','mini')
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
