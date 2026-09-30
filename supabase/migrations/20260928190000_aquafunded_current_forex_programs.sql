-- Add AquaFunded's current Forex model family from first-party site and Help Center.
-- Reviewed 2026-09-28. The official price selector currently throws a JSON parsing
-- error, so model-specific sizes and fees remain explicitly unavailable/in review.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'AquaFunded', 'aquafunded',
  'AquaFunded offers simulated Forex evaluation and instant-funding models with model-specific rules, payout cycles, and risk limits.',
  'https://www.aquafunded.com/', 'published', now()
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'published', published_at = coalesce(bullish_banana.firms.published_at, now()), updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'aquafunded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'AE', 'Aqua Funded FZCO', array['Forex', 'Indices', 'Metals']::text[],
  '{"brand_operator":"Aqua Funded FZCO, trading as AquaFunded","service_provider":"AquaFunded LTD","headquarters":"Dubai, United Arab Emirates","service_model":"Simulated trading services","platform_options":["Match Trade", "TradeLocker", "MetaTrader 5", "cTrader"],"platform_notes":"The official Forex configurator offers platform selection and states that cTrader has an additional fee; confirm model and location compatibility at checkout.","separate_markets":"AquaFunded also advertises Crypto and Futures through separate market offerings; only its Forex catalog is represented in this migration."}'::jsonb
from bullish_banana.firms where slug = 'aquafunded'
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
  null, null, item.commercial_details::jsonb, null
from bullish_banana.firms
join (values
  ('AquaFunded 1-Step Standard', '1-step-standard', 'evaluation', 'Single-phase Forex evaluation with a 9% target, 3% daily drawdown, 6% trailing maximum drawdown, and three qualifying evaluation days.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', 3::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. The Help Center lists biweekly rewards and a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific account-size options and fees are not reliably available from the current official selector. The rendered selector has a JSON parsing error; price remains unverified.","prohibited_strategies":"See the linked current 1-Step Standard rules. Model-specific news, weekend, and platform compatibility should be confirmed in the applicable checkout terms.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded 1-Step Pro', '1-step-pro', 'evaluation', 'Single-phase Forex evaluation with a 6% target, 3% daily drawdown, 6% trailing maximum drawdown that locks at starting balance after 6% growth, and five qualifying evaluation days.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', 5::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. Biweekly rewards are listed, with a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific account-size options and fees are not reliably available from the current official selector; price remains unverified.","consistency_rule":"The funded stage has a 25% best-day consistency requirement; this limits payout eligibility, not account access.","prohibited_strategies":"The current Help Center describes a maximum floating-loss policy. Confirm model-specific news, weekend, and platform compatibility in applicable terms.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded 1-Step Flex', '1-step-flex', 'evaluation', 'Single-phase Forex evaluation with a 10% target, 3% daily drawdown, and 12% static maximum drawdown for purchases made on or after 31 August 2026. No evaluation minimum-day requirement is listed.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', null::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. The page lists biweekly rewards and a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific sizes and fees are not verifiable from the currently failing official price selector. The 12% static maximum-loss term applies to new purchases on or after 31 August 2026; older purchases retain a 10% limit.","prohibited_strategies":"WaveStop is funded-stage-only. Confirm model-specific news, weekend, and platform compatibility in applicable terms.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded 2-Step Standard', '2-step-standard', 'evaluation', 'Two-phase Forex evaluation with 8% then 5% targets, 5% daily drawdown, 8% static maximum drawdown, and three qualifying days per phase.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', 3::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. The Help Center lists biweekly rewards and a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific account-size options and fees are not verifiable from the current official selector; price remains unverified.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded 2-Step Pro', '2-step-pro', 'evaluation', 'Two-phase Forex evaluation with 10% then 5% targets, 5% daily drawdown, 10% trailing maximum drawdown, and no evaluation minimum-day requirement.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', null::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. Biweekly rewards are listed, with a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific account-size options and fees are not verifiable from the current official selector; price remains unverified.","consistency_rule":"The funded stage has a 50% best-day consistency requirement for purchases on or after 31 August 2026; confirm the purchase-date rule for older accounts.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded 2-Step Elite', '2-step-elite', 'evaluation', 'Two-phase Forex evaluation with 8% then 5% targets, 4% daily drawdown, 10% static maximum drawdown, and three qualifying days per phase.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', 3::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. The Help Center lists biweekly rewards and a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific account-size options and fees are not verifiable from the current official selector; price remains unverified.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded 3-Step', '3-step', 'evaluation', 'Three-phase Forex evaluation with a 6% target in each phase, 4% daily drawdown, and 8% static maximum drawdown. No minimum evaluation days are listed.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', null::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split is an optional add-on. Biweekly rewards are listed, with a first-payout-in-7-days add-on.","fee_refund_policy":"Model-specific account-size options and fees are not verifiable from the current official selector; price remains unverified.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded Instant Funding Standard', 'instant-funding-standard', 'instant_funding', 'Immediate Forex funding with a 3% daily loss limit, 5% trailing maximum loss, five qualifying days before reward requests, and a 15% consistency threshold.', '[]', 50::numeric, 90::numeric, 'Biweekly; on-demand may be an optional checkout add-on', 5::integer, '{"payout_rules":"Standard reward share is 90%; 100% profit split and first payout on demand are listed as checkout add-ons. Rewards are otherwise biweekly.","fee_refund_policy":"Model-specific account-size options and fees are not verifiable from the current official selector; price remains unverified.","prohibited_strategies":"The current page also specifies a one-percent floating-loss three-strike policy. Confirm platform and location compatibility at checkout.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded Instant Funding Pro', 'instant-funding-pro', 'instant_funding', 'Immediate Forex funding with a 3% daily loss limit, 6% trailing maximum loss, five qualifying days per reward cycle, and a 20% best-day rule for new accounts purchased on or after 8 September 2026.', '[]', 50::numeric, 90::numeric, 'Biweekly; on-demand may be an optional checkout add-on', 5::integer, '{"payout_rules":"Standard Pro share is 90%; a 100% split and first payout on demand may be offered as add-ons. Rewards are otherwise biweekly.","fee_refund_policy":"Model-specific account-size options and fees are not verifiable from the current official selector; price remains unverified.","prohibited_strategies":"A maximum floating-loss policy applies (stricter for $300K and $400K accounts). Confirm model-specific platform availability at checkout.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded Instant Flex', 'instant-flex', 'instant_funding', 'Immediate Forex funding with account sizes advertised from $5,000 to $100,000, a 2% daily limit, 4% trailing maximum loss, no consistency rule, and a 5% reward-cycle cap.', '[]', 50::numeric, 90::numeric, 'Biweekly', 7::integer, '{"payout_rules":"90% standard share; biweekly rewards after seven qualifying days. Each reward cycle has a 5% account-balance profit cap.","fee_refund_policy":"The Help Center gives a $5K–$100K range but the exact available size options and current fees are not verifiable from the official selector; price remains unverified.","prohibited_strategies":"Combined floating loss of 1% breaches the account. Confirm model-specific platform availability at checkout.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded Pay After Pass', 'pay-after-pass', 'evaluation', 'Pay-after-pass Forex model with a 3% evaluation target; the funded stage has 3% daily and 5% trailing maximum loss limits and a 15% payout consistency rule.', '[]', 50::numeric, 90::numeric, 'Biweekly; on-demand may be an optional checkout add-on', null::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split and first payout on demand may be offered as checkout add-ons. The funded phase requires five qualifying days before payout.","fee_refund_policy":"The official Help Center says the customer starts with $5 and pays the remaining fee after passing; full model-size-dependent remaining fees are not verifiable from the current selector.","prohibited_strategies":"A one-percent combined floating-loss limit applies on the funded account.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded TryAqua $1', 'tryaqua-1', 'instant_funding', 'Limited TryAqua instant-funding model with a $1,000 starting balance, a 30-day term, 3% daily and 5% trailing maximum loss, five qualifying days, and a $100 maximum withdrawal.', '[1000]', 100::numeric, 90::numeric, 'Every 14 days', 5::integer, '{"payout_rules":"90% share; rewards may be requested every 14 days after qualifying requirements. Total withdrawals are capped at $100; the account expires 30 days after the first trade.","fee_refund_policy":"The model is titled TryAqua $1; no separate refund term is stated on the reviewed Help Center page.","consistency_rule":"The largest winning day must be 15% or less of total profits to request a payout.","prohibited_strategies":"A 2% floating-loss breach applies. Confirm current availability and purchase terms before relying on this limited offer.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded TryAqua $10', 'tryaqua-10', 'instant_funding', 'Limited TryAqua instant-funding model with a $5,000 starting balance, a 30-day term, 3% daily and 5% trailing maximum loss, five qualifying days, and a $100 maximum withdrawal.', '[5000]', 100::numeric, 90::numeric, 'Every 14 days', 5::integer, '{"payout_rules":"90% share; rewards may be requested every 14 days after qualifying requirements. Total withdrawals are capped at $100; the account expires 30 days after the first trade.","fee_refund_policy":"The model is titled TryAqua $10; no separate refund term is stated on the reviewed Help Center page.","consistency_rule":"The largest winning day must be 15% or less of total profits to request a payout.","prohibited_strategies":"A 2% floating-loss breach applies. Confirm current availability and purchase terms before relying on this limited offer.","commission_details":"Not stated on the reviewed model page."}'),
  ('AquaFunded AquaMan', 'aquaman', 'evaluation', 'Limited-availability Forex evaluation that requires a 2% target; the official Help Center says AquaMan is released for purchase on selected weekends.', '[]', 100::numeric, 90::numeric, 'Biweekly; an earlier first payout may be available as a checkout add-on', null::integer, '{"payout_rules":"Standard funded share is 90%; a 100% split and first payout in seven days may be offered as add-ons. Reward requests are generally biweekly.","fee_refund_policy":"Model-specific size and fee are not verifiable from the current official selector. Availability is limited and released on selected weekends.","consistency_rule":"The funded stage has a 15% best-day consistency requirement.","prohibited_strategies":"A 2% floating-loss rule applies to funded accounts. Confirm current offer window and platform compatibility before purchase.","commission_details":"Not stated on the reviewed model page."}')
) as item(name, slug, program_type, description, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, commercial_details) on true
where firms.slug = 'aquafunded'
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
  phase.max_loss, phase.drawdown_type, null, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'aquafunded'
join (values
  ('1-step-standard', 1, 'Evaluation', 9.000::numeric, 3.000::numeric, 6.000::numeric, 'trailing', 3::integer, '{"source_note":"The current AquaFunded 1-Step Standard Help Center page gives a 9% target, 3% daily drawdown, 6% trailing maximum drawdown and three qualifying evaluation days."}'),
  ('1-step-pro', 1, 'Evaluation', 6.000::numeric, 3.000::numeric, 6.000::numeric, 'trailing', 5::integer, '{"source_note":"The current AquaFunded 1-Step Pro page gives a 6% target, 3% daily drawdown, 6% trailing maximum drawdown that locks at initial balance after 6% growth, and five qualifying days."}'),
  ('1-step-flex', 1, 'Evaluation', 10.000::numeric, 3.000::numeric, 12.000::numeric, 'static', null::integer, '{"source_note":"For purchases from 2026-08-31, the current 1-Step Flex page gives a 10% target, 3% daily drawdown and 12% static maximum drawdown. It lists no evaluation minimum days."}'),
  ('2-step-standard', 1, 'Step 1', 8.000::numeric, 5.000::numeric, 8.000::numeric, 'static', 3::integer, '{"source_note":"Current 2-Step Standard rules: 8% first target, 5% daily loss, 8% static overall loss, and three qualifying days."}'),
  ('2-step-standard', 2, 'Step 2', 5.000::numeric, 5.000::numeric, 8.000::numeric, 'static', 3::integer, '{"source_note":"Current 2-Step Standard rules: 5% second target with the same 5% daily and 8% static overall loss limits, and three qualifying days."}'),
  ('2-step-pro', 1, 'Step 1', 10.000::numeric, 5.000::numeric, 10.000::numeric, 'trailing', null::integer, '{"source_note":"Current 2-Step Pro rules: 10% first target, 5% daily loss, 10% trailing overall loss; no evaluation minimum days."}'),
  ('2-step-pro', 2, 'Step 2', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'trailing', null::integer, '{"source_note":"Current 2-Step Pro rules: 5% second target with 5% daily loss and 10% trailing overall loss; no evaluation minimum days."}'),
  ('2-step-elite', 1, 'Step 1', 8.000::numeric, 4.000::numeric, 10.000::numeric, 'static', 3::integer, '{"source_note":"Current 2-Step Elite rules: 8% first target, 4% daily loss, 10% static overall loss, and three qualifying days."}'),
  ('2-step-elite', 2, 'Step 2', 5.000::numeric, 4.000::numeric, 10.000::numeric, 'static', 3::integer, '{"source_note":"Current 2-Step Elite rules: 5% second target with the same 4% daily and 10% static overall loss limits, and three qualifying days."}'),
  ('3-step', 1, 'Step 1', 6.000::numeric, 4.000::numeric, 8.000::numeric, 'static', null::integer, '{"source_note":"Current 3-Step rules: 6% target per phase, 4% daily loss, 8% static maximum loss, and no minimum trading days."}'),
  ('3-step', 2, 'Step 2', 6.000::numeric, 4.000::numeric, 8.000::numeric, 'static', null::integer, '{"source_note":"Current 3-Step rules: 6% target per phase, 4% daily loss, 8% static maximum loss, and no minimum trading days."}'),
  ('3-step', 3, 'Step 3', 6.000::numeric, 4.000::numeric, 8.000::numeric, 'static', null::integer, '{"source_note":"Current 3-Step rules: 6% target per phase, 4% daily loss, 8% static maximum loss, and no minimum trading days."}'),
  ('pay-after-pass', 1, 'Evaluation', 3.000::numeric, null::numeric, null::numeric, null::text, null::integer, '{"source_note":"Current Pay After Pass rules require a 3% evaluation target; the linked source specifies risk limits and five qualifying days for the funded stage."}'),
  ('aquaman', 1, 'Evaluation', 2.000::numeric, 3.000::numeric, 6.000::numeric, 'trailing', null::integer, '{"source_note":"Current AquaMan rules state a 2% target, 3% daily limit and 6% trailing maximum loss; it is released for purchase on selected weekends."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('Match Trade', 'match-trade'), ('TradeLocker', 'tradelocker'),
  ('MetaTrader 5', 'metatrader-5'), ('cTrader', 'ctrader')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'aquafunded'
cross join bullish_banana.platforms
where programs.slug in ('1-step-standard','1-step-pro','1-step-flex','2-step-standard','2-step-pro','2-step-elite','3-step','instant-funding-standard','instant-funding-pro','instant-flex','pay-after-pass','tryaqua-1','tryaqua-10','aquaman')
  and platforms.slug in ('match-trade','tradelocker','metatrader-5','ctrader')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://www.aquafunded.com/forex-funded-account', 'AquaFunded Forex models and company disclosure', 'First-party Forex page reviewed 2026-09-28. The page identifies Forex, indices, metals, the simulated trading service and legal entities; lists model/platform/account-size selectors and promotional refund messaging. The live selector currently throws a JSON parsing error, so individual prices and size options were not captured.'
from bullish_banana.firms where firms.slug = 'aquafunded'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://www.aquafunded.com/forex-funded-account');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://help.aquafunded.com/en/collections/11518293-forex-models', 'AquaFunded current Forex model index', 'First-party Help Center index reviewed 2026-09-28 lists 15 model articles. The older Instant Funding Standard page is explicitly retained only for pre-2026-09-08 accounts; this migration adds the current model families and does not add that legacy ruleset as a purchasable offer.'
from bullish_banana.firms where firms.slug = 'aquafunded'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://help.aquafunded.com/en/collections/11518293-forex-models');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'aquafunded'
join (values
  ('1-step-standard','https://help.aquafunded.com/en/articles/15281183-1-step-standard','AquaFunded 1-Step Standard rules','Current official rules state its target, drawdown, qualifying days, reward split, reward frequency, leverage and funded-stage terms.'),
  ('1-step-pro','https://help.aquafunded.com/en/articles/15281185-1-step-pro','AquaFunded 1-Step Pro rules','Current official rules state its target, drawdown, qualifying days, reward split, reward frequency, leverage and consistency conditions.'),
  ('1-step-flex','https://help.aquafunded.com/en/articles/10476451-1-step-flex','AquaFunded 1-Step Flex rules','Current official rules state its target, drawdown, purchase-date update, funded-stage rules, payouts and leverage.'),
  ('2-step-standard','https://help.aquafunded.com/en/articles/15281226-2-step-standard','AquaFunded 2-Step Standard rules','Current official rules state both phase targets, daily and total loss, qualifying days, reward split and leverage.'),
  ('2-step-pro','https://help.aquafunded.com/en/articles/15281229-2-step-pro','AquaFunded 2-Step Pro rules','Current official rules state both phase targets, trailing drawdown, funded consistency, qualifying days, reward terms and leverage.'),
  ('2-step-elite','https://help.aquafunded.com/en/articles/15281231-2-step-elite','AquaFunded 2-Step Elite rules','Current official rules state both phase targets, daily/static loss, qualifying days, reward terms and leverage.'),
  ('3-step','https://help.aquafunded.com/en/articles/10476458-3-step-model','AquaFunded 3-Step rules','Current official rules state the three targets, daily and total loss, unlimited time, no minimum evaluation days, reward terms and leverage.'),
  ('instant-funding-standard','https://help.aquafunded.com/en/articles/10476448-new-instant-funding-standard','AquaFunded current Instant Funding Standard rules','Current official page was updated after the 2026-09-08 rules change; it states risk, reward, consistency, minimum days, and leverage. Legacy account terms are excluded.'),
  ('instant-funding-pro','https://help.aquafunded.com/en/articles/15281078-instant-funding-pro','AquaFunded Instant Funding Pro rules','Current official rules state daily/trailing loss, reward split/cycle, funded consistency, maximum floating-loss policy and leverage.'),
  ('instant-flex','https://help.aquafunded.com/en/articles/17066639-instant-flex','AquaFunded Instant Flex rules','Current official rules state account-size range, daily/trailing loss, absence of consistency, 5% reward cap, minimum days, leverage and floating-loss policy.'),
  ('pay-after-pass','https://help.aquafunded.com/en/articles/13322298-pay-after-pass-model','AquaFunded Pay After Pass rules','Current official rules state the $5 entry payment, 3% evaluation target, funded risk and consistency terms, reward schedule and leverage.'),
  ('tryaqua-1','https://help.aquafunded.com/en/articles/11786783-tryaqua-1-model','AquaFunded TryAqua $1 rules','Official limited model page states $1,000 balance, 30-day term, drawdown, qualifying days, 15% consistency, $100 withdrawal cap and leverage.'),
  ('tryaqua-10','https://help.aquafunded.com/en/articles/14037595-tryaqua-10-model','AquaFunded TryAqua $10 rules','Official limited model page states $5,000 balance, 30-day term, drawdown, qualifying days, 15% consistency, $100 withdrawal cap and leverage.'),
  ('aquaman','https://help.aquafunded.com/en/articles/11018168-aquaman-model','AquaFunded AquaMan rules','Current official page states a 2% evaluation target, drawdown, funded consistency and risk rules; availability is limited to random weekend releases.')
) as source(slug, url, label, notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://help.aquafunded.com/en/articles/9250906-how-do-rewards-work', 'AquaFunded reward processing rules', 'First-party help article reviewed 2026-09-28 states payout eligibility, the 24 business-hour payout guarantee, 3% processing charge, minimum withdrawal and payout caps for initial rewards.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'aquafunded'
where programs.slug in ('1-step-standard','1-step-pro','1-step-flex','2-step-standard','2-step-pro','2-step-elite','3-step','instant-funding-standard','instant-funding-pro','instant-flex','pay-after-pass','tryaqua-1','tryaqua-10','aquaman')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = 'https://help.aquafunded.com/en/articles/9250906-how-do-rewards-work');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://help.aquafunded.com/en/articles/15255671-are-there-minimum-trading-days', 'AquaFunded minimum qualifying days by model', 'First-party article reviewed 2026-09-28 distinguishes model-specific evaluation and funded-stage minimum days.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'aquafunded'
where programs.slug in ('1-step-standard','1-step-pro','1-step-flex','2-step-standard','2-step-pro','2-step-elite','3-step','instant-funding-standard','instant-funding-pro','instant-flex','pay-after-pass','tryaqua-1','tryaqua-10','aquaman')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = 'https://help.aquafunded.com/en/articles/15255671-are-there-minimum-trading-days');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed AquaFunded first-party Forex page, legal disclosure and official Help Center model index on 2026-09-28. The live pricing selector currently fails to parse its data; model-specific sizes and fees remain unverified.'
from bullish_banana.firms where slug = 'aquafunded';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed the current model-specific AquaFunded first-party Help Center page on 2026-09-28. Challenge rules are captured, but model-level sizes and fees remain in review because the official pricing selector is currently failing.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'aquafunded'
where programs.slug in ('1-step-standard','1-step-pro','1-step-flex','2-step-standard','2-step-pro','2-step-elite','3-step','instant-funding-standard','instant-funding-pro','instant-flex','pay-after-pass','tryaqua-1','tryaqua-10','aquaman');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit ' || programs.name, 'https://www.aquafunded.com/forex-funded-account', true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'aquafunded'
  and programs.slug in ('1-step-standard','1-step-pro','1-step-flex','2-step-standard','2-step-pro','2-step-elite','3-step','instant-funding-standard','instant-funding-pro','instant-flex','pay-after-pass','tryaqua-1','tryaqua-10','aquaman')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
