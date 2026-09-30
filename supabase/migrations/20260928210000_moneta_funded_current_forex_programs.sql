-- Add Moneta Funded and its current Forex program families from first-party sources.
-- Reviewed 2026-09-28. Prices are not represented as exact because the official
-- challenge builder calculates the order price after configuration/checkout.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'Moneta Funded', 'moneta-funded',
  'Moneta Funded offers simulated Forex evaluations and instant-access programs, including timed Sprint challenges.',
  'https://www.monetafunded.com/', 'published', now()
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'published', published_at = coalesce(bullish_banana.firms.published_at, now()), updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'moneta-funded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'crypto' from bullish_banana.firms where slug = 'moneta-funded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'LC', 'Moneta Funded Ltd', array['Forex', 'Indices', 'Commodities', 'Cryptocurrencies']::text[],
  '{"registered_office":"Ground Floor, The Sotheby Building, Rodney Village, Rodney Bay, Gros-Islet, Saint Lucia","registration_number":"2025-00532","service_model":"Simulated trading challenges and simulated funded accounts; any trader-payment eligibility is subject to a separate Funded Trader Agreement","broker_relationship":"The official site describes Moneta Funded as backed by Moneta Markets; the liquidity, platform and market-data infrastructure is supplied by third parties.","platform_options":["MetaTrader 5", "Match-Trader"],"platform_restrictions":"Official site says MT5 is unavailable to clients from the USA and Canada. Confirm country eligibility for selected platform and account before purchase.","onboarding_restrictions":["Iran","Afghanistan","Thailand","Cuba","Myanmar","North Korea","United Arab Emirates","Venezuela","Vietnam","FATF, OFAC, EU or UN sanctioned jurisdictions"],"service_disclosure":"All trading is simulated. Challenge payments are subscriptions and not client money. Passing an evaluation does not automatically guarantee an offer to become a funded trader; additional verification and a separate agreement apply."}'::jsonb
from bullish_banana.firms where slug = 'moneta-funded'
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
select firms.id, item.name, item.slug, item.description, item.program_type, 'in_review', 'USD', item.account_sizes::jsonb,
  item.max_leverage, item.profit_split_percent, item.payout_frequency, item.minimum_trading_days,
  item.news_allowed, item.weekend_holding_allowed, item.commercial_details::jsonb, null
from bullish_banana.firms
join (values
  ('Moneta Funded 1-Step Challenge', '1-step-challenge', 'evaluation', 'Single-phase Forex evaluation with a 10% target, 3% daily loss limit, 6% static maximum loss, and three profitable days of at least 0.5% each.', '[5000,10000,25000,50000,100000]', 30::numeric, 88::numeric, '14 days after funded-account activation', 3::integer, false, true, '{"payout_rules":"Funded stage has an 88% profit split with 14-day payout frequency. Challenge page states funded account retains a 3% daily loss and 6% static max loss; challenge requires three qualifying profitable days of at least 0.5%.","fee_refund_policy":"The official site uses an interactive Challenge Builder. Exact base fees by size were not displayed in the reviewed public page/search output; confirm in the live builder before purchase. A time-limited FLASH40 code is advertised but is excluded from base pricing.","account_size_prices":[],"account_size_price_note":"Not captured: live configuration flow calculates the amount after challenge/account configuration. No fee has been inferred.","consistency_rule":"No consistency rule is listed for the 1-Step challenge in the current official comparison table.","prohibited_strategies":"Current comparison page says news trading is not allowed. General Rules prohibit trading practices not permitted by their rules; review full rules for exact limitations.","commission_details":"Not stated on the reviewed official challenge pages.","time_limit":"Unlimited evaluation period; inactivity breach applies if no trade is placed for 30 calendar days.","minimum_days_detail":"Three profitable trading days are required in the evaluation. Each qualifying day must close at least 0.5% profit."}'),
  ('Moneta Funded 2-Step Challenge', '2-step-challenge', 'evaluation', 'Two-phase Forex evaluation with a 5% first-phase target and 10% second-phase target. Daily and total drawdown options vary with purchased add-ons.', '[5000,10000,25000,50000,100000]', 100::numeric, 88::numeric, '14 days after funded-account activation', 3::integer, false, true, '{"payout_rules":"Funded stage has an 88% profit split and 14-day payout frequency. Current comparison page shows funded drawdown settings that vary by selected add-on. Three profitable days of at least 0.5% are required per evaluation phase.","fee_refund_policy":"Exact fee schedule was not exposed in the reviewed public pages. Use the official live Challenge Builder to verify the base fee, chosen drawdown configuration, and any add-on charges. Promotional codes are time-limited and excluded from base prices.","account_size_prices":[],"account_size_price_note":"Not captured: live configuration flow calculates amount after choosing account and drawdown options. No price inferred.","phase_rule_variants":"Official general rules state the 2-Step target is 5% in Phase 1 and 10% in Phase 2. Daily loss is 4% or 5%, and maximum loss is 8% or 10%, depending on optional drawdown add-ons. General Rules also document those configuration variants; the captured comparison table does not reliably map them to phases, so preserve them as account-level options pending checkout confirmation.","consistency_rule":"No evaluation consistency percentage is listed. Official challenge journey includes three profitable days of at least 0.5% after passing Phase 2 before funding.","prohibited_strategies":"Current comparison page says news trading is not allowed. General Rules contain further restrictions; verify selected account terms.","commission_details":"Not stated on the reviewed official challenge pages.","time_limit":"Unlimited evaluation period; inactivity breach applies if no trade is placed for 30 calendar days.","minimum_days_detail":"Three qualifying profitable trading days are required per phase. Each day needs at least 0.5% closed profit."}'),
  ('Moneta Funded Instant Funding', 'instant-funding', 'instant_funding', 'Instant-access Forex account with no evaluation phase, 3% daily loss, 5% trailing maximum loss, and a payout consistency threshold.', '[5000,10000,25000,50000,100000]', 30::numeric, null::numeric, '14 days', null::integer, false, true, '{"payout_rules":"The official comparison page lists a 60% or 88% profit split and payout every 14 days. Current general rules describe the 15% or 20% consistency settings but do not map them to the 60%/88% split in the rendered table. Verify the selected option in the builder.","fee_refund_policy":"Exact base fees by account size were not displayed in reviewed public page output. Confirm in the official live builder. Do not treat the FLASH40 promotional code as base pricing.","account_size_prices":[],"account_size_price_note":"Not captured: exact checkout price not present in retrieved public product text.","consistency_rule":"The comparison page lists 15%/20% consistency options; the mapping to payout split or selected add-on is unclear in the captured page. Keep as variant data, not one default.","prohibited_strategies":"Current official comparison page says news trading is not allowed. Confirm full rules and any account-specific strategy restrictions.","commission_details":"Not stated on the reviewed official challenge pages.","time_limit":"No evaluation deadline; inactivity breach applies if no trade is placed for 30 calendar days."}'),
  ('Moneta Funded Instant Pro', 'instant-pro', 'instant_funding', 'Instant-access Forex account with 4% daily loss, 8% trailing maximum loss, a 4% daily profit cap, and on-demand first payout requests.', '[5000,10000,25000,50000,100000]', 30::numeric, 88::numeric, 'On demand initially, then every 14 days', null::integer, true, null::boolean, '{"payout_rules":"The current product page lists an 88% profit split and on-demand payouts followed by a 14-day cycle. The product page allows news trading and overnight holding.","fee_refund_policy":"Exact base fees by account size were not exposed in the reviewed public page output. Confirm in the official live builder; promotional discounts are not used as base prices.","account_size_prices":[],"account_size_price_note":"Not captured: exact checkout price not present in retrieved public product text.","consistency_rule":"No consistency percentage listed on the official current comparison table for Instant Pro.","prohibited_strategies":"Official product page explicitly allows news trading. No other product-specific prohibited strategies were stated in the retrieved page content; consult general trading rules.","commission_details":"Not stated on the reviewed official challenge pages.","risk_limits":"4% daily drawdown, 8% trailing maximum loss, and a 4% maximum profit per day are listed on the current official product page.","time_limit":"No evaluation deadline; inactivity breach applies if no trade is placed for 30 calendar days."}'),
  ('Moneta Funded Phoenix Instant', 'phoenix-instant', 'instant_funding', 'Instant-access Forex account with a 3% daily loss limit, 6% static maximum loss, three profitable days per payout cycle, and scaling after 10% growth.', '[5000,10000,25000,50000,100000]', 30::numeric, 88::numeric, 'Every 14 days', 3::integer, false, true, '{"payout_rules":"Current Phoenix product page lists an 88% split and payouts every 14 days. Three profitable days of at least 0.5% each are required for reward eligibility. Scaling threshold is 10% growth; the balance can scale under the company plan to a maximum advertised size of $2,000,000.","fee_refund_policy":"Exact base fees by starting size were not displayed in reviewed public page output. Confirm in the official live builder. Any promotional code is temporary and is not used as base pricing.","account_size_prices":[],"account_size_price_note":"Not captured: exact checkout price not present in retrieved public product text.","consistency_rule":"Official current Phoenix page states no consistency rule.","prohibited_strategies":"Current official comparison page says news trading is not allowed. Confirm full rules for product-specific exceptions.","commission_details":"Not stated on the reviewed official challenge pages.","time_limit":"No evaluation deadline; inactivity breach applies if no trade is placed for 30 calendar days."}'),
  ('Moneta Funded Sprint Challenge', 'sprint-challenge', 'evaluation', 'Configurable Forex challenge with account size, duration, and multiplier choices; it has a time limit, static max-loss range, and direct payout eligibility after reaching the configured target.', '[10000,25000,50000,100000]', 30::numeric, 100::numeric, 'Immediate payout after successful completion', null::integer, false, null::boolean, '{"payout_rules":"Official comparison says the Sprint payout is immediate upon successful completion with 100% profit split. The final payout/payoff is configuration dependent.","fee_refund_policy":"The live builder selects account size, time limit, and multiplier and calculates the exact target, maximum loss, price, and payout. These values were not exposed in the captured public text; verify selected combinations directly in the builder.","account_size_prices":[],"account_size_price_note":"Not captured: each configuration has a calculated target, max loss, price, and payout. No price inferred.","sprint_configuration":{"account_sizes":[10000,25000,50000,100000],"duration_hours":[1,2,4,8],"multipliers":[2,5]},"risk_limits":"Official comparison page reports targets from 0.6% to 3% and static max loss from 0.3% to 1.5%, varying by selection.","consistency_rule":"No consistency rule stated on the official comparison page.","prohibited_strategies":"News trading, gap trading, and trading during the five-minute windows before and after high-impact economic news or major market opens are prohibited. The market-open restriction includes the New York, London, and Asia opens.","commission_details":"Not stated on the reviewed official challenge pages.","time_limit":"One, two, four, or eight hours, depending on the selected challenge configuration."}')
) as item(name, slug, program_type, description, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details) on true
where firms.slug = 'moneta-funded'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = 'in_review', currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, published_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss,
  phase.max_loss, phase.drawdown_type, phase.time_limit_days, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'moneta-funded'
join (values
  ('1-step-challenge',1,'Evaluation',10.000::numeric,3.000::numeric,6.000::numeric,'static',null::integer,3::integer,'{"profitable_day_requirement":"Each qualifying day must show at least 0.5% closed profit.","source_note":"Official One-Step and general rules state 10% target, 3% daily loss, 6% static max loss, three profitable days, and no time limit."}'),
  ('2-step-challenge',1,'Phase 1',5.000::numeric,null::numeric,null::numeric,'static',null::integer,3::integer,'{"profitable_day_requirement":"Each qualifying day must show at least 0.5% closed profit.","drawdown_variants":"Official rules offer either 4% daily/8% static or 5% daily/10% static depending on add-on. These are account configuration variants, not confirmed phase-specific settings; confirm selected configuration.","source_note":"Official current rules state a 5% target and three qualifying profitable days for Phase 1; drawdown settings vary by add-on."}'),
  ('2-step-challenge',2,'Phase 2',10.000::numeric,null::numeric,null::numeric,'static',null::integer,3::integer,'{"profitable_day_requirement":"Each qualifying day must show at least 0.5% closed profit.","drawdown_variants":"Official rules offer either 4% daily/8% static or 5% daily/10% static depending on add-on. These are account configuration variants, not confirmed phase-specific settings; confirm selected configuration.","source_note":"Official current rules state a 10% target and three qualifying profitable days for Phase 2; drawdown settings vary by add-on."}'),
  ('sprint-challenge',1,'Timed Challenge',null::numeric,null::numeric,null::numeric,'static',null::integer,null::integer,'{"time_limit_options_hours":[1,2,4,8],"multiplier_options":[2,5],"source_note":"Sprint has no evaluation phases in the official challenge comparison. This placeholder phase preserves the configurable target/time-limit mechanism; exact target and max loss are set by account size, duration, and multiplier."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, time_limit_days, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('MetaTrader 5', 'metatrader-5'), ('Match-Trader', 'match-trader')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'moneta-funded'
cross join bullish_banana.platforms
where programs.slug in ('1-step-challenge','2-step-challenge','instant-funding','instant-pro','phoenix-instant','sprint-challenge')
  and platforms.slug in ('metatrader-5','match-trader')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://www.monetafunded.com/','Moneta Funded official home and current challenge overview','Official first-party home page reviewed 2026-09-28 lists the current 1-Step, 2-Step, Instant Funding, Instant Pro, Phoenix Instant, and Sprint products, supported platforms and promotional codes. It identifies Moneta Funded Ltd and its Saint Lucia registration and simulated trading service.'),
  ('https://www.monetafunded.com/compare-challenges/','Moneta Funded official challenge comparison','The current comparison page lists current product families and comparison rules, including payout, leverage, timing, and risk-limit ranges. Some 2-Step and Instant values appear as selectable variants.'),
  ('https://www.monetafunded.com/general-rules/','Moneta Funded general rules','First-party General Rules reviewed 2026-09-28 specify drawdown calculations, challenge targets, profitable-day thresholds, 30-day inactivity and MT5/Match-Trader availability.'),
  ('https://www.monetafunded.com/terms-conditions/','Moneta Funded terms and conditions','Official legal terms identify Moneta Funded Ltd, the simulated account model, eligibility/contract conditions and jurisdictional restrictions. Challenge fees are non-refundable except stated legal and 14-day no-trade cases.'),
  ('https://www.monetafunded.com/one-step/','Moneta Funded One-Step challenge page','Official product page states current One-Step target, daily and max loss, profitable days, payout schedule and platform information.'),
  ('https://www.monetafunded.com/two-step/','Moneta Funded Two-Step challenge page','Official product page states phase targets, the two drawdown configurations, profitable-day rules, platform and no time limit.'),
  ('https://www.monetafunded.com/phoenix/','Moneta Funded Phoenix Instant page','Official product page states instant access, payout cycle, loss limits, profitable-day rule and scale-up information.'),
  ('https://www.monetafunded.com/sprint-challenge/','Moneta Funded Sprint challenge page','Official Sprint page explains that size, time and multiplier selections determine target, max loss, price and payout. The retrieved public text exposes configuration choices but not a complete static price matrix.'),
  ('https://www.monetafunded.com/latest-news/introducing-the-moneta-funded-sprint-challenge/','Moneta Funded Sprint product announcement','First-party product announcement details Sprint trading restrictions, including news, gaps and market-open windows.')
) as source(url, label, notes) on true
where firms.slug = 'moneta-funded'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'moneta-funded'
join (values
  ('1-step-challenge','https://www.monetafunded.com/one-step/','Moneta Funded 1-Step rules','Current official page provides evaluation and funded-stage loss limits, target, profitable days, payout terms and platform availability.'),
  ('2-step-challenge','https://www.monetafunded.com/two-step/','Moneta Funded 2-Step rules','Current official page provides phase targets, drawdown add-on variants, profitable days, no time limit, and platform availability.'),
  ('instant-funding','https://www.monetafunded.com/compare-challenges/','Moneta Funded Instant Funding rules','Current official comparison page provides no-phase access, trailing loss, payout and consistency ranges. Confirm the selected builder settings before purchase.'),
  ('instant-pro','https://www.monetafunded.com/one-step/','Moneta Funded Instant Pro rules','Current official product page provides daily/max-loss, daily-profit cap, payout timing, news permission and platform information.'),
  ('phoenix-instant','https://www.monetafunded.com/phoenix/','Moneta Funded Phoenix Instant rules','Current official Phoenix page gives instant access, payout interval, loss limits, profitable-day requirement and scale-up threshold.'),
  ('sprint-challenge','https://www.monetafunded.com/sprint-challenge/','Moneta Funded Sprint configurable rules','Official builder requires selecting account size, duration and multiplier to calculate target, max loss, price and payout; exact configuration outputs are unavailable in the captured public text.')
) as source(slug, url, label, notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed Moneta Funded first-party home, Terms and Conditions, General Rules, comparison table, product pages, and Sprint announcement on 2026-09-28. Six active Forex product families and current public rule sets are captured. Exact fees depend on interactive product configuration and remain unavailable; records are held in review until the live builder fee matrix is captured.'
from bullish_banana.firms where slug = 'moneta-funded';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed current Moneta Funded first-party product/rule page on 2026-09-28. Challenge facts recorded; exact purchase fee is not in captured public output and program remains in review pending live builder confirmation.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'moneta-funded'
where programs.slug in ('1-step-challenge','2-step-challenge','instant-funding','instant-pro','phoenix-instant','sprint-challenge');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'View ' || programs.name,
  case programs.slug
    when '1-step-challenge' then 'https://www.monetafunded.com/one-step/'
    when '2-step-challenge' then 'https://www.monetafunded.com/two-step/'
    when 'phoenix-instant' then 'https://www.monetafunded.com/phoenix/'
    when 'sprint-challenge' then 'https://www.monetafunded.com/sprint-challenge/'
    else 'https://www.monetafunded.com/'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'moneta-funded'
  and programs.slug in ('1-step-challenge','2-step-challenge','instant-funding','instant-pro','phoenix-instant','sprint-challenge')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
