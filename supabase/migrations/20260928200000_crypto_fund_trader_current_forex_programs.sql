-- Add Crypto Fund Trader's current Forex program families from first-party sources.
-- Reviewed 2026-09-28. Core offers have sourced price schedules; Ascend and Break
-- remain in review while availability and size-specific rules are confirmed.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'Crypto Fund Trader', 'crypto-fund-trader',
  'Crypto Fund Trader provides simulated Forex evaluations through one-phase, two-phase, three-phase, instant, Ascend, and Break programs.',
  'https://cryptofundtrader.com/', 'published', now()
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description,
    website_url = excluded.website_url, status = 'published',
    published_at = coalesce(bullish_banana.firms.published_at, now()), updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'crypto-fund-trader'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'crypto' from bullish_banana.firms where slug = 'crypto-fund-trader'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'CH', 'SWISS RLCRATES AG', array['Forex', 'Cryptocurrencies', 'Indices', 'Commodities', 'Stocks']::text[],
  '{"headquarters":"Zug, Switzerland","company_registration":"CHE-162.567.204","service_model":"Educational services and simulated trading evaluations; performance-based scholarship eligibility may follow program rules","legal_disclosure":"The official site identifies SWISS RLCRATES AG as an educational-services provider and states it acts as payment/marketing agent for RLCRATES S.L. Trading activity uses simulated/demo funds. RLCRATES S.L. is identified as the MT5 service provider.","platform_options":["Match-Trader", "MetaTrader 5", "Bybit"],"forex_platforms":["Match-Trader", "MetaTrader 5"],"platform_notes":"Bybit evaluation is for USDT crypto futures only; it is not represented as a Forex platform. Advanced Forex account leverage is listed up to 1:100; Student accounts list 1:30.","markets_note":"The firm lists simulated Forex CFDs alongside crypto, indices, commodities and stocks. Crypto market membership is recorded separately."}'::jsonb
from bullish_banana.firms where slug = 'crypto-fund-trader'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select firms.id, item.name, item.slug, item.description, item.program_type,
  case when item.slug in ('2-phase-evaluation','1-phase-evaluation','3-phase-evaluation','instant-evaluation') then 'published' else 'in_review' end,
  'USD', item.account_sizes::jsonb,
  item.max_leverage, item.profit_split_percent, item.payout_frequency, item.minimum_trading_days,
  true, true, item.commercial_details::jsonb,
  case when item.slug in ('2-phase-evaluation','1-phase-evaluation','3-phase-evaluation','instant-evaluation') then now() else null end
from bullish_banana.firms
join (values
  ('Crypto Fund Trader 2-Phase Evaluation', '2-phase-evaluation', 'evaluation', 'Two-phase simulated Forex evaluation with an 8% first-phase target, 5% second-phase target, 5% daily loss limit, and 10% static overall loss limit.', '[1000,5000,10000,25000,50000,100000,200000]', 100::numeric, 80::numeric, 'Performance-based scholarship requests; current FAQ lists 15 traded days or every 30 calendar days after the first request', 0::integer, '{"account_size_prices":[{"account_size":5000,"fee":58,"currency":"USD"},{"account_size":10000,"fee":110,"currency":"USD"},{"account_size":25000,"fee":240,"currency":"USD"},{"account_size":50000,"fee":389,"currency":"USD"},{"account_size":100000,"fee":660,"currency":"USD"},{"account_size":200000,"fee":1250,"currency":"USD"}],"payout_rules":"Default final-stage share shown on the official site is 80%; optional 90% bonus-performance add-on is listed at 20% of the evaluation fee. After the first request, current FAQ lists eligibility after 15 traded days or every 30 calendar days. Requires KYC and closed trades at request.","fee_refund_policy":"One-time base fees are listed in the official Terms and Conditions and match the live official shop for the currently visible 5K, 10K, 25K and 50K offers. Official terms also list a 1K Student 2-Phase account, but do not list its price; no fee is inferred. Fees include applicable taxes; payment-processor currency conversion may apply.","account_type_rules":"Student sizes listed in official terms: $1K, $5K, $10K, $25K. Advanced sizes: $50K, $100K, $200K. Forex leverage: Student 1:30; Advanced 1:100.","consistency_rule":"No evaluation consistency rule was found in the reviewed current rules. Do not infer a funded-stage consistency rule for this program.","prohibited_strategies":"Official rules prohibit reverse trading across accounts, hedging between accounts under common control, gambling/all-in behavior, high-frequency trading, tick scalping and arbitrage. Maximum simulated profit limit is $10,000 per day and/or per trade.","commission_details":"For Match-Trader and MT5 Forex, official FAQ lists $2.50 per lot per side. Swap fees may apply to overnight CFD positions.","news_and_weekend":"Official FAQ allows news trading and holding positions overnight and over weekends.","source_conflict":"Current FAQ says no minimum evaluation days, while older Evaluation Process content says five days per phase. The record follows the current FAQ; the older page is recorded as stale conflicting content."}'),
  ('Crypto Fund Trader 1-Phase Evaluation', '1-phase-evaluation', 'evaluation', 'Single-phase simulated Forex evaluation with a 10% target, 4% daily loss limit, and 6% balance-based trailing drawdown that locks at starting balance after 6% growth.', '[5000,10000,25000,50000,100000,200000]', 100::numeric, 80::numeric, 'Performance-based scholarship requests; current FAQ lists 15 traded days or every 30 calendar days after the first request', 0::integer, '{"account_size_prices":[{"account_size":5000,"fee":40,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":369,"currency":"USD"},{"account_size":100000,"fee":619,"currency":"USD"},{"account_size":200000,"fee":1199,"currency":"USD"}],"payout_rules":"Default final-stage share shown on the official site is 80%; optional 90% bonus-performance add-on is listed at 20% of the evaluation fee. Current FAQ lists 15 traded days or every 30 calendar days after the first reward request; KYC and closed trades are required.","fee_refund_policy":"One-time base fees are listed in the official Terms and Conditions and match the live official shop for the currently visible 5K, 10K, 25K, 50K, 100K and 200K Accelerated products.","account_type_rules":"Student sizes listed in official terms: $5K, $10K, $25K. Advanced sizes: $50K, $100K, $200K. Forex leverage: Student 1:30; Advanced 1:100.","consistency_rule":"No evaluation consistency rule was found in the reviewed current rules.","prohibited_strategies":"Official rules prohibit reverse trading across accounts, hedging between accounts under common control, gambling/all-in behavior, high-frequency trading, tick scalping and arbitrage. Maximum simulated profit limit is $10,000 per day and/or per trade.","commission_details":"For Match-Trader and MT5 Forex, official FAQ lists $2.50 per lot per side. Swap fees may apply to overnight CFD positions.","news_and_weekend":"Official FAQ allows news trading and holding positions overnight and over weekends.","source_conflict":"Current FAQ says no minimum evaluation days, while older Evaluation Process content says five days. This record uses the newer FAQ; the older page is recorded as stale conflicting content."}'),
  ('Crypto Fund Trader 3-Phase Evaluation', '3-phase-evaluation', 'evaluation', 'Three-phase simulated Forex evaluation with a 5% profit target and 5% daily and static overall loss limits in each phase.', '[5000,10000,25000,50000,100000,200000]', 100::numeric, 80::numeric, 'First scholarship request after 5 traded days; later requests after 15 traded days or every 30 calendar days', 0::integer, '{"account_size_prices":[{"account_size":5000,"fee":30,"currency":"USD"},{"account_size":10000,"fee":59,"currency":"USD"},{"account_size":25000,"fee":145,"currency":"USD"},{"account_size":50000,"fee":255,"currency":"USD"},{"account_size":100000,"fee":399,"currency":"USD"},{"account_size":200000,"fee":798,"currency":"USD"}],"payout_rules":"Official current FAQ says the first scholarship request may be made after 5 traded days; later requests follow 15 traded days or every 30 calendar days. Default split advertised generally as 80%; confirm evaluation-specific scholarship value and account tier in checkout.","fee_refund_policy":"Fee schedule is stated in the current official Terms and Conditions. 100K fee also matches the current official home-page offer. Confirm current full basket and selected account type at checkout.","account_type_rules":"Forex leverage: Advanced 1:100; Student 1:30. The current rules distinguish these leverage tiers.","prohibited_strategies":"Common official rules prohibit reverse trading across accounts, hedging between accounts under common control, gambling/all-in behavior, high-frequency trading, tick scalping and arbitrage. Maximum simulated profit limit is $10,000 per day and/or per trade.","commission_details":"For Match-Trader and MT5 Forex, official FAQ lists $2.50 per lot per side. Swap fees may apply to overnight CFD positions.","news_and_weekend":"Official FAQ allows news trading and holding positions overnight and over weekends.","source_conflict":"The three-phase offer is advertised on the current official home page and described in the FAQ, while availability/pricing is not visible in the paginated live shop snapshot. Kept in review pending purchase-flow confirmation."}'),
  ('Crypto Fund Trader Instant Evaluation', 'instant-evaluation', 'instant_funding', 'Zero-phase Forex simulated account with a 6% overall loss limit, 4% daily loss limit, and a 10% profit milestone for account doubling.', '[2500,5000,10000]', 30::numeric, 80::numeric, 'A Withdrawal & Upgrade may be requested at 10% growth without minimum trading days; other reward requests follow standard conditions', 0::integer, '{"account_size_prices":[{"account_size":2500,"fee":125,"currency":"USD"},{"account_size":5000,"fee":240,"currency":"USD"},{"account_size":10000,"fee":475,"currency":"USD"}],"payout_rules":"At 10% simulated growth, the account holder may request a Withdrawal & Upgrade with no minimum trading-day requirement; the account is doubled. Below that threshold, official terms refer to standard reward conditions. Current site caps active Instant evaluations at three and excludes them from standard allocation limits.","fee_refund_policy":"One-time base fees are listed in official terms and match the live shop for the $2.5K, $5K, and $10K Instant Evaluation products.","account_type_rules":"Student Forex leverage is 1:30. Official terms classify Instant accounts among Student accounts; confirm selected platform and account configuration at checkout.","consistency_rule":"No Instant evaluation consistency threshold was found in the reviewed rules.","prohibited_strategies":"Common official rules prohibit reverse trading across accounts, hedging between accounts under common control, gambling/all-in behavior, high-frequency trading, tick scalping and arbitrage. Maximum simulated profit limit is $10,000 per day and/or per trade.","commission_details":"For Match-Trader and MT5 Forex, official FAQ lists $2.50 per lot per side. Swap fees may apply to overnight CFD positions.","news_and_weekend":"Official FAQ allows news trading and holding positions overnight and over weekends."}'),
  ('Crypto Fund Trader Ascend Evaluation', 'ascend-evaluation', 'evaluation', 'Two-phase Student Forex evaluation with 8% and 5% targets that ends in an educational scholarship rather than a separate final-stage evaluation.', '[5000,10000,25000,50000,100000,200000]', 30::numeric, null::numeric, 'Scholarship available after completing the Phase 2 target; see the selected account terms for the scholarship amount', 0::integer, '{"account_size_prices":[{"account_size":5000,"fee":39,"currency":"USD"},{"account_size":10000,"fee":78,"currency":"USD"},{"account_size":25000,"fee":195,"currency":"USD"},{"account_size":50000,"fee":390,"currency":"USD"},{"account_size":100000,"fee":780,"currency":"USD"},{"account_size":200000,"fee":1560,"currency":"USD"}],"payout_rules":"The official terms say Ascend uses the same conditions as 2-Phase and awards a scholarship after both phases are passed; the updates FAQ says the scholarship request may be made immediately after the Phase 2 target. Terms list scholarship values for $5K, $10K, and $25K only; higher-size scholarship amounts are not stated in the reviewed page.","fee_refund_policy":"Base fees are listed in the official Terms and Conditions; account-level availability and current checkout fees should be confirmed.","account_type_rules":"Official terms list Ascend as a Student account; Forex leverage 1:30. Maximum allocation limit does not apply to Ascend, but the $10,000 daily/per-trade simulated profit cap still applies.","prohibited_strategies":"Common official rules prohibit reverse trading across accounts, hedging between accounts under common control, gambling/all-in behavior, high-frequency trading, tick scalping and arbitrage. Maximum simulated profit limit is $10,000 per day and/or per trade.","commission_details":"For Match-Trader and MT5 Forex, official FAQ lists $2.50 per lot per side. Swap fees may apply to overnight CFD positions.","news_and_weekend":"Official FAQ allows news trading and holding positions overnight and over weekends.","source_conflict":"Ascend prices and account sizes appear in the current legal terms, but the paginated live shop did not display these offers. Kept in review pending the current product checkout flow."}'),
  ('Crypto Fund Trader Break Evaluation', 'break-evaluation', 'evaluation', 'Single-phase simulated Forex evaluation with a size-dependent target and trailing loss, an activation charge after passing, and a payout-time 40% best-day limit on the funded account.', '[25000,50000,100000]', 100::numeric, 80::numeric, 'On-demand after meeting the funded-stage 40% best-day consistency condition', 0::integer, '{"account_size_prices":[{"account_size":25000,"fee":70,"currency":"USD","activation_fee":138},{"account_size":50000,"fee":140,"currency":"USD","activation_fee":198},{"account_size":100000,"fee":200,"currency":"USD","activation_fee":328}],"payout_rules":"Official Break page says 80% split and on-demand payouts; funded-stage consistency is 40% of total profits per best day and is checked at payout time. Activation fee is due after passing.","fee_refund_policy":"Evaluation and activation fee schedules are listed in official Terms and Conditions and live shop. Confirm total due and any limited-time offer at checkout.","account_type_rules":"Break is a one-phase product. Official Break page advertises no daily loss limit, while the legal terms specify size-dependent daily loss limits. Keep in review until this conflict is reconciled with checkout rules.","consistency_rule":"Funded stage: no single day''s profit may exceed 40% of cumulative total profits at payout request. No evaluation consistency rule listed.","prohibited_strategies":"Common official rules prohibit reverse trading across accounts, hedging between accounts under common control, gambling/all-in behavior, high-frequency trading, tick scalping and arbitrage. Maximum simulated profit limit is $10,000 per day and/or per trade.","commission_details":"For Match-Trader and MT5 Forex, official FAQ lists $2.50 per lot per side. Swap fees may apply to overnight CFD positions.","news_and_weekend":"Official FAQ allows news trading and holding positions overnight and over weekends.","account_size_rules":"Official Break page gives $25K target $1,250 and trailing loss $1,000; $50K target $3,000 and trailing loss $2,000; $100K target $6,000 and trailing loss $3,000. Legal terms state daily loss caps of 4%, 4%, and 3% respectively, while the current Break page advertises no daily loss limit. Values are retained here with the conflict flagged; do not publish until verified against current checkout/contract."}')
) as item(name, slug, program_type, description, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, commercial_details) on true
where firms.slug = 'crypto-fund-trader'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = excluded.status, currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, published_at = excluded.published_at, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss,
  phase.max_loss, phase.drawdown_type, null, 0, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'crypto-fund-trader'
join (values
  ('2-phase-evaluation',1,'Phase 1',8.000::numeric,5.000::numeric,10.000::numeric,'static','{"daily_loss_calculation":"Equity-based breach; daily loss reference balance is reset at 12:05 AM UTC.","source_note":"Current official FAQ and terms state an 8% target, 5% daily loss and fixed 10% overall loss for Phase 1."}'),
  ('2-phase-evaluation',2,'Phase 2',5.000::numeric,5.000::numeric,10.000::numeric,'static','{"daily_loss_calculation":"Equity-based breach; daily loss reference balance is reset at 12:05 AM UTC.","source_note":"Current official FAQ and terms state a 5% target, 5% daily loss and fixed 10% overall loss for Phase 2."}'),
  ('1-phase-evaluation',1,'Evaluation',10.000::numeric,4.000::numeric,6.000::numeric,'trailing','{"daily_loss_calculation":"Equity-based breach; daily loss reference balance is reset at 12:05 AM UTC. Trailing maximum loss follows balance high-water mark and locks at initial balance after 6% growth.","source_note":"Current official FAQ and terms state a 10% target, 4% daily loss and 6% trailing maximum loss."}'),
  ('3-phase-evaluation',1,'Phase 1',5.000::numeric,5.000::numeric,5.000::numeric,'static','{"daily_loss_calculation":"Equity-based breach; daily loss reference balance is reset at 12:05 AM UTC.","source_note":"Official current three-phase FAQ states a 5% target, 5% daily loss and fixed 5% maximum loss in each phase."}'),
  ('3-phase-evaluation',2,'Phase 2',5.000::numeric,5.000::numeric,5.000::numeric,'static','{"daily_loss_calculation":"Equity-based breach; daily loss reference balance is reset at 12:05 AM UTC.","source_note":"Official current three-phase FAQ states a 5% target, 5% daily loss and fixed 5% maximum loss in each phase."}'),
  ('3-phase-evaluation',3,'Phase 3',5.000::numeric,5.000::numeric,5.000::numeric,'static','{"daily_loss_calculation":"Equity-based breach; daily loss reference balance is reset at 12:05 AM UTC.","source_note":"Official current three-phase FAQ states a 5% target, 5% daily loss and fixed 5% maximum loss in each phase."}'),
  ('ascend-evaluation',1,'Phase 1',8.000::numeric,5.000::numeric,10.000::numeric,'static','{"source_note":"Official terms state Ascend uses the same conditions as the two-phase evaluation."}'),
  ('ascend-evaluation',2,'Phase 2',5.000::numeric,5.000::numeric,10.000::numeric,'static','{"source_note":"Official terms state Ascend uses the same conditions as the two-phase evaluation."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('Match-Trader', 'match-trader'), ('MetaTrader 5', 'metatrader-5')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'crypto-fund-trader'
cross join bullish_banana.platforms
where programs.slug in ('2-phase-evaluation','1-phase-evaluation','3-phase-evaluation','instant-evaluation','ascend-evaluation','break-evaluation')
  and platforms.slug in ('match-trader','metatrader-5')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://cryptofundtrader.com/','Crypto Fund Trader Forex offering and company disclosure','Official home page lists Forex among simulated markets, program types, general news/overnight claims, the Swiss contact address and SWISS RLCRATES AG disclosure. Account-specific terms may differ.'),
  ('https://cryptofundtrader.com/terms-and-conditions/','Crypto Fund Trader fees and legal terms','Official terms state fee schedules by account size and product, account type/leverage distinction, service entity disclosures, simulated account status, and trading objectives. Reviewed 2026-09-28.'),
  ('https://cryptofundtrader.com/faq/','Crypto Fund Trader current FAQ','Official FAQ states current evaluation drawdown calculations, minimum days, platforms, Forex instruments and commission, news/weekend permissions, payout/KYC conditions, and prohibited strategies. Reviewed 2026-09-28.'),
  ('https://cryptofundtrader.com/last-updates-faq/','Crypto Fund Trader product update FAQ','Official product FAQ details Ascend, three-phase and Instant account conditions, platform-specific Forex leverage and scholarship schedules. Reviewed 2026-09-28.'),
  ('https://cryptofundtrader.com/shop/','Crypto Fund Trader live product shop','Official shop lists current Evaluation, Accelerated, Instant Evaluation, Break Evaluation and Break Activation Fee products. Base listed prices align with the official terms for the products visible on the captured page; availability may change.'),
  ('https://cryptofundtrader.com/break-challenge/','Crypto Fund Trader Break challenge page','Official Break product page provides current displayed account-size targets, trailing loss, funded split, payout consistency and advertised no-daily-loss claim; the latter conflicts with the legal terms.'),
  ('https://cryptofundtrader.com/evaluation-process/','Crypto Fund Trader evaluation process article','First-party article contains evaluation objectives but appears older than the current FAQ; its five-day minimum conflicts with the current FAQ statement of no evaluation minimum days.')
) as source(url, label, notes) on true
where firms.slug = 'crypto-fund-trader'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'crypto-fund-trader'
join (values
  ('2-phase-evaluation','https://cryptofundtrader.com/faq/','Crypto Fund Trader 2-Phase Forex rules','Official FAQ gives 8% then 5% targets, 5% daily and 10% fixed maximum loss, Forex platform leverage, commission, general permissions and payout conditions.'),
  ('1-phase-evaluation','https://cryptofundtrader.com/faq/','Crypto Fund Trader 1-Phase Forex rules','Official FAQ gives 10% target, 4% daily loss and 6% balance-based trailing maximum loss that locks at starting balance after 6% growth.'),
  ('3-phase-evaluation','https://cryptofundtrader.com/last-updates-faq/','Crypto Fund Trader 3-Phase rules','Official updated FAQ gives each phase''s 5% target, 5% daily and fixed 5% overall loss, account-type leverage, and first-request scholarship conditions.'),
  ('instant-evaluation','https://cryptofundtrader.com/last-updates-faq/','Crypto Fund Trader Instant rules','Official updated FAQ identifies Instant/zero-phase account growth and upgrade, eligibility limits, and Forex leverage.'),
  ('ascend-evaluation','https://cryptofundtrader.com/last-updates-faq/','Crypto Fund Trader Ascend rules','Official updated FAQ and legal terms describe Ascend as a Student account with two phases and scholarship after Phase 2.'),
  ('break-evaluation','https://cryptofundtrader.com/break-challenge/','Crypto Fund Trader Break rules','Current official Break page details size-dependent targets and trailing limits, funded 40% consistency, activation charge and a no-daily-loss claim; the legal terms differ on daily loss.')
) as source(slug, url, label, notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed Crypto Fund Trader official Terms and Conditions, FAQ, product update FAQ, live product shop, Break product page and Evaluation Process on 2026-09-28. Four core offer families have verified terms and are staged for publication. Ascend remains in review until current checkout availability is confirmed; Break remains in review because official daily-loss terms conflict by source. The older five-day evaluation page is superseded by the current FAQ that states no evaluation minimum days.'
from bullish_banana.firms where slug = 'crypto-fund-trader';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), case when programs.status = 'published'
  then 'Verified current program family and core terms against Crypto Fund Trader official Terms, current FAQ and live product shop on 2026-09-28. Per-size schedules are first-party sourced; listed 1K two-phase account has no fee disclosed.'
  else 'Verified available facts against Crypto Fund Trader first-party pages on 2026-09-28. Remains in review until its presence in the current checkout and/or conflicting size-specific rules are resolved.' end
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'crypto-fund-trader'
where programs.slug in ('2-phase-evaluation','1-phase-evaluation','3-phase-evaluation','instant-evaluation','ascend-evaluation','break-evaluation');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'View ' || programs.name,
  case when programs.slug = 'break-evaluation' then 'https://cryptofundtrader.com/break-challenge/' else 'https://cryptofundtrader.com/' end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'crypto-fund-trader'
  and programs.slug in ('2-phase-evaluation','1-phase-evaluation','3-phase-evaluation','instant-evaluation','ascend-evaluation','break-evaluation')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
