-- Refresh FTMO's existing Forex programs against current first-party pages reviewed 2026-09-28.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set description = 'FTMO offers one-step and two-step simulated trading evaluations, with program-specific account choices and reward terms.',
    website_url = 'https://ftmo.com/',
    updated_at = now()
where slug = 'ftmo';

insert into bullish_banana.firm_markets (firm_id, market_type)
select firms.id, 'futures' from bullish_banana.firms where firms.slug = 'ftmo'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, profile_details)
select firms.id, 'CZ', '{"founded_year":2015,"service_model":"Simulated trading and educational tools"}'::jsonb
from bullish_banana.firms where firms.slug = 'ftmo'
on conflict (firm_id) do update
set country_code = excluded.country_code,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

update bullish_banana.programs
set currency = 'USD',
    account_sizes = '[10000,25000,50000,100000,200000]'::jsonb,
    profit_split_percent = null,
    payout_frequency = null,
    minimum_trading_days = 4,
    news_allowed = null,
    weekend_holding_allowed = null,
    commercial_details = jsonb_build_object(
      'payout_rules', 'The 2-Step product offers up to 90% of simulated profits.',
      'fee_refund_policy', 'One-time EUR fee by simulated account size: $10,000 €89; $25,000 €250; $50,000 €345; $100,000 €540; $200,000 €1,080. 100% of the 2-Step fee is refunded with the first Reward withdrawal after successful evaluation. Prices reviewed 2026-09-28; confirm in the official order flow.',
      'consistency_rule', 'No separate consistency rule is stated for 2-Step in the current comparison table.',
      'prohibited_strategies', 'Standard and Swing account types are available for 2-Step. Current news and overnight/weekend restrictions differ by account type after evaluation; those restrictions do not apply during the Evaluation Process.',
      'commission_details', 'Not stated in the reviewed evaluation overview.'
    ),
    description = 'Two-phase simulated evaluation: 10% target in FTMO Challenge, then 5% in Verification; 5% daily loss, 10% static maximum loss, four minimum trading days, and unlimited time.',
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'ftmo') and slug = 'ftmo-2-step';

update bullish_banana.programs
set currency = 'USD',
    account_sizes = '[10000,25000,50000,100000,200000]'::jsonb,
    profit_split_percent = 90,
    payout_frequency = null,
    minimum_trading_days = null,
    news_allowed = null,
    weekend_holding_allowed = null,
    commercial_details = jsonb_build_object(
      'payout_rules', 'The 1-Step product provides a 90% reward ratio on simulated profits.',
      'fee_refund_policy', 'One-time EUR fee by simulated account size: $10,000 €79; $25,000 €199; $50,000 €319; $100,000 €499; $200,000 €999. The 1-Step fee is non-refundable. Prices reviewed 2026-09-28; confirm in the official order flow.',
      'consistency_rule', 'Best Day Rule: the most profitable day must not exceed 50% of Positive Days’ Profit; additional profit is needed if it does.',
      'prohibited_strategies', 'Standard account rules restrict selected news and overnight/weekend trading after evaluation. The evaluation period does not apply those restrictions. Swing is not offered for the 1-Step Challenge.',
      'commission_details', 'Not stated in the reviewed evaluation overview.'
    ),
    description = 'Single-phase simulated evaluation with a 10% target, 3% maximum daily loss, 10% end-of-day trailing maximum loss, 50% Best Day Rule, and unlimited time.',
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'ftmo') and slug = 'ftmo-1-step';

-- Fees vary by selected account size, so they are recorded in the verified offer schedule above.
-- Keep phase.fee null instead of displaying a single size as though it applied to every account.
insert into bullish_banana.program_phases (program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss, phase.max_loss, phase.drawdown_type, null, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'ftmo'
join (values
  ('ftmo-2-step', 1, 'FTMO Challenge', 10.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 4::integer, '{"source_note":"Current FTMO 2-Step and Comparison pages show a 10% first-phase target, 5% maximum daily loss, 10% static maximum loss, four minimum trading days, and unlimited time."}'),
  ('ftmo-2-step', 2, 'Verification', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 4::integer, '{"source_note":"Current FTMO 2-Step and Comparison pages show a 5% Verification target and the same risk limits, minimum trading days, and unlimited time."}'),
  ('ftmo-1-step', 1, 'FTMO Challenge', 10.000::numeric, 3.000::numeric, 10.000::numeric, 'end-of-day-trailing', null::integer, '{"best_day_rule_percent":50,"source_note":"Current FTMO 1-Step and Comparison pages show a 10% target, 3% maximum daily loss, 10% end-of-day trailing maximum loss, 50% Best Day Rule, and unlimited time; no minimum trading-days requirement is listed."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug)
values ('MetaTrader 4', 'metatrader-4'), ('cTrader', 'ctrader'), ('TradingView', 'tradingview')
on conflict (slug) do update set name = excluded.name;

-- Add relationships after ensuring every current official platform exists.
insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'ftmo'
join bullish_banana.platforms on platforms.slug in ('metatrader-4', 'metatrader-5', 'ctrader', 'tradingview')
where programs.slug in ('ftmo-1-step', 'ftmo-2-step')
on conflict do nothing;

update bullish_banana.sources
set notes = case programs.slug
  when 'ftmo-1-step' then 'Refreshed 2026-09-28 from current FTMO first-party pages: one phase, 10% target, 3% daily loss, 10% end-of-day trailing maximum loss, unlimited time, 90% reward, 50% Best Day Rule, Standard account type, and current account-size choices. Fee schedule is supported by the official FTMO offer page and recorded separately.'
  when 'ftmo-2-step' then 'Refreshed 2026-09-28 from current FTMO first-party pages: 10% then 5% targets, 5% daily loss, 10% static maximum loss, four minimum trading days, unlimited time, up to 90% reward, full fee refund after first reward, and Standard/Swing account types.'
  else notes end
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'ftmo'
where sources.program_id = programs.id and programs.slug in ('ftmo-1-step', 'ftmo-2-step');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'ftmo'
join (values
  ('ftmo-1-step', 'https://ftmo.com/en/1-step-challenge/', 'FTMO 1-Step Challenge', 'Current first-party page documents the single phase, 10% target, 3% maximum daily loss, 10% maximum loss, unlimited time, 90% reward, and 50% Best Day Rule.'),
  ('ftmo-1-step', 'https://promo.ftmo.com/u26a-your-1-step/', 'FTMO 1-Step account sizes and base fees', 'First-party offer page reviewed 2026-09-28 lists account sizes and EUR one-time fees by size. The listed €399 100K discount is excluded; the displayed €499 standard price is recorded. Recheck before use.'),
  ('ftmo-2-step', 'https://ftmo.com/en/2-step-challenge/', 'FTMO 2-Step Challenge', 'Current first-party page documents 10% and 5% targets, 5% daily loss, 10% maximum loss, four minimum trading days, unlimited time, up to 90% reward, and refundable fee.'),
  ('ftmo-2-step', 'https://ftmo.com/en/comparison-table/', 'FTMO 1-Step and 2-Step comparison', 'Current first-party comparison table confirms one-time starting fees, evaluation phases, risk limits, time limits, minimum days, rewards, Best Day Rule, refund, and account types.'),
  ('ftmo-2-step', 'https://promo.ftmo.com/love-for-trading/', 'FTMO 2-Step account sizes and base fees', 'First-party offer page reviewed 2026-09-28 lists account sizes and EUR one-time fees by size. The discounted 100K offer is excluded; the displayed €540 standard price is recorded. Recheck before use.'),
  ('ftmo-1-step', 'https://ftmo.com/en/trading-platforms/', 'FTMO Trading Platforms', 'Current first-party platforms page lists FTMO MetaTrader 4, MetaTrader 5, TradingView, and cTrader; account-type availability may vary.'),
  ('ftmo-2-step', 'https://ftmo.com/en/trading-platforms/', 'FTMO Trading Platforms', 'Current first-party platforms page lists FTMO MetaTrader 4, MetaTrader 5, TradingView, and cTrader; account-type availability may vary.'),
  ('ftmo-2-step', 'https://ftmo.com/en/faq/are-the-fees-recurrent/', 'FTMO fee and refund FAQ', 'First-party FAQ confirms fees are one-time and the 2-Step fee is refunded with first Reward; 1-Step fee is not refunded.')
) as source(program_slug, url, label, notes) on true
where programs.slug = source.program_slug
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://ftmo.com/en/', 'FTMO official site', 'First-party company overview identifies the evaluation provider and simulated trading model.'
from bullish_banana.firms where firms.slug = 'ftmo'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://ftmo.com/en/');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Reviewed FTMO official company and program information on 2026-09-28; firm description and Prague office details were checked against first-party pages.'
from bullish_banana.firms where firms.slug = 'ftmo';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed FTMO first-party challenge, comparison, fee FAQ, and pricing pages on 2026-09-28. Prices are EUR base prices captured from the current official offer; recheck current checkout before reliance.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'ftmo'
where programs.slug in ('ftmo-1-step', 'ftmo-2-step');
