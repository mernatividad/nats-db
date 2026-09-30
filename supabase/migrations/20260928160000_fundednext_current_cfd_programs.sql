-- Refresh FundedNext's currently offered CFD/Forex challenge models from first-party pages,
-- reviewed 2026-09-28. Models with incomplete account-size/price evidence stay in review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set description = 'FundedNext offers multiple simulated CFD evaluation models, including Forex challenges with distinct targets, risk limits, and reward schedules.',
    website_url = 'https://fundednext.com/usa/cfds',
    updated_at = now()
where slug = 'fundednext';

insert into bullish_banana.firm_profiles (firm_id, legal_entity_name, profile_details)
select firms.id, 'FundedNext Limited', '{"service_model":"Simulated trading using virtual funds","website_operator":"FundedNext Limited","program_operator":"FundedNext Ltd.","operational_entities":["GrowthNext F.Z.E.","Incenteco Trading LTD.","Abutor Investments LTD."]}'::jsonb
from bullish_banana.firms where firms.slug = 'fundednext'
on conflict (firm_id) do update
set legal_entity_name = excluded.legal_entity_name,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

update bullish_banana.programs
set name = 'FundedNext Stellar 2-Step',
    description = 'Two-phase Forex evaluation with 8% then 5% targets, 5% daily loss, 10% static maximum loss, five minimum trading days per phase, and no time limit.',
    program_type = 'evaluation',
    status = 'published',
    currency = 'USD',
    account_sizes = '[6000,15000,25000,50000,100000,200000]'::jsonb,
    max_leverage = 30,
    profit_split_percent = null,
    payout_frequency = 'First reward after 21 days; subsequent rewards every 14 days',
    minimum_trading_days = 5,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = jsonb_build_object(
      'payout_rules', 'The official page states reward share up to 80% for this model. First reward eligibility is 21 days; subsequent rewards are every 14 days.',
      'fee_refund_policy', 'Displayed USD base one-time prices by account size: $6,000 $49.99; $15,000 $109.99; $25,000 $189.99; $50,000 $269.99; $100,000 $529.99; $200,000 $1,049.99. The page also displays a time-limited $6K discount; it is excluded here. The challenge fee is refunded with the first reward. Prices reviewed 2026-09-28; verify checkout before purchase.',
      'prohibited_strategies', 'News trading and weekend holding are allowed on the challenge and FundedNext Account according to the official challenge page. The FundedNext Account rules also show a 3% at-any-time maximum risk condition and a 40% news-trading-profit field; confirm the applicable definitions in the official rulebook.',
      'commission_details', 'Not stated on the reviewed program page.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'fundednext') and slug = 'stellar-2-step';

insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details, published_at)
select firms.id, item.name, item.slug, item.description, item.program_type, item.status, 'USD', '[]'::jsonb,
       null, null, item.payout_frequency, item.minimum_trading_days, item.news_allowed, item.weekend_holding_allowed,
       item.commercial_details::jsonb, case when item.status = 'published' then now() else null end
from bullish_banana.firms
join (values
  ('FundedNext Stellar 1-Step', 'stellar-1-step', 'Single-phase Forex evaluation with a 10% target, 3% daily loss, 6% static maximum loss, and two minimum trading days.', 'evaluation', 'in_review', null::text, 2::integer, null::boolean, null::boolean,
   '{"payout_rules":"The official comparison page states the first reward is available within 7 days and subsequent rewards every 5 business days; reward share is up to 95%.","fee_refund_policy":"Account-size choices and current base fee schedule have not yet been confirmed from a directly accessible first-party product page.","commission_details":"Not stated on the reviewed official comparison page."}'),
  ('FundedNext Stellar Lite', 'stellar-lite', 'Two-phase Forex evaluation with 8% then 4% targets, 4% daily loss, 8% static maximum loss, five minimum trading days per phase, and no time limit.', 'evaluation', 'in_review', null::text, 5::integer, null::boolean, null::boolean,
   '{"payout_rules":"The official comparison page states reward share up to 80%, first reward eligibility after 21 days, and subsequent rewards every 14 days.","fee_refund_policy":"Account-size choices, fee schedule, and refund policy have not yet been confirmed from a directly accessible first-party product page.","commission_details":"Not stated on the reviewed official comparison page."}'),
  ('FundedNext Stellar Instant', 'stellar-instant', 'Instant simulated FundedNext Account with no evaluation challenge or profit target; a 6% trailing maximum loss is listed.', 'instant_funding', 'in_review', 'On demand at 5% account growth, or every 14 days at 1% or more growth', null::integer, null::boolean, null::boolean,
   '{"payout_rules":"The official comparison page lists reward share up to 80%; rewards can be requested on demand at 5% account growth, or bi-weekly at 1% or more growth.","fee_refund_policy":"Current account-size choices and entry-fee schedule have not yet been confirmed from a directly accessible first-party product page.","commission_details":"Not stated on the reviewed official comparison page."}')
) as item(name, slug, description, program_type, status, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details) on true
where firms.slug = 'fundednext'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = excluded.status, currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss, phase.max_loss, phase.drawdown_type, null, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'fundednext'
join (values
  ('stellar-2-step', 1, 'Phase 1', 8.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 5::integer, '{"source_note":"FundedNext''s current official page states an 8% Phase 1 target, 5% daily loss, 10% static maximum loss, five minimum trading days, and no time limit."}'),
  ('stellar-2-step', 2, 'Phase 2', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 5::integer, '{"source_note":"FundedNext''s current official page states a 5% Phase 2 target with the same loss limits, five minimum trading days, and no time limit."}'),
  ('stellar-1-step', 1, 'Evaluation', 10.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 2::integer, '{"source_note":"FundedNext''s current official comparison lists one phase, 10% target, 3% daily loss, 6% static maximum loss, two minimum trading days, and no time limit."}'),
  ('stellar-lite', 1, 'Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 5::integer, '{"source_note":"FundedNext''s current official comparison lists an 8% first target, 4% daily loss, 8% static maximum loss, five minimum trading days, and no time limit."}'),
  ('stellar-lite', 2, 'Phase 2', 4.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 5::integer, '{"source_note":"FundedNext''s current official comparison lists a 4% second target with the same loss limits, five minimum trading days, and no time limit."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

update bullish_banana.programs
set commercial_details = commercial_details || '{"payout_rules":"No evaluation challenge. The official comparison page lists no profit target and no daily loss limit; maximum loss is 6% trailing."}'::jsonb
where firm_id = (select id from bullish_banana.firms where slug = 'fundednext') and slug = 'stellar-instant';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://fundednext.com/usa/cfds', 'FundedNext current CFD program catalog', 'First-party catalog reviewed 2026-09-28 lists Stellar 2-Step, Stellar 1-Step, Stellar Lite, and Stellar Instant and identifies the Forex/CFD evaluation business.'
from bullish_banana.firms where firms.slug = 'fundednext'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://fundednext.com/usa/cfds');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://fundednext.com/usa/cfds/stellar-2-step', 'FundedNext Stellar 2-Step', 'Current first-party program page reviewed 2026-09-28 states two targets, loss limits, five days per phase, unlimited time, account sizes and base fees, reward cycle, fee refund, news/weekend rules, and leverage.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'fundednext'
where programs.slug = 'stellar-2-step'
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = 'https://fundednext.com/usa/cfds/stellar-2-step');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://fundednext.com/general-rules/cfds/trading-objectives', 'FundedNext CFD trading objectives', 'First-party general rules compare the targets, loss limits, drawdown types, minimum days, time limits, reward shares, payout eligibility, and refund terms for the four current Stellar models.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'fundednext'
where programs.slug in ('stellar-2-step', 'stellar-1-step', 'stellar-lite', 'stellar-instant')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = 'https://fundednext.com/general-rules/cfds/trading-objectives');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Reviewed FundedNext first-party CFD overview and legal disclosure on 2026-09-28. The website operator and simulated program model are recorded; the separate operating entities are preserved in profile notes.'
from bullish_banana.firms where firms.slug = 'fundednext';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), case programs.slug
  when 'stellar-2-step' then 'Reviewed the current FundedNext first-party Stellar 2-Step page and CFD trading objectives on 2026-09-28; base fees are captured by account size, with the limited-time discount excluded.'
  else 'Reviewed the current FundedNext first-party CFD trading objectives comparison on 2026-09-28. Account sizes and prices remain in review pending direct product-page confirmation.'
end
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'fundednext'
where programs.slug in ('stellar-2-step', 'stellar-1-step', 'stellar-lite', 'stellar-instant');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit ' || programs.name,
  case programs.slug
    when 'stellar-1-step' then 'https://fundednext.com/usa/cfds'
    when 'stellar-lite' then 'https://fundednext.com/usa/cfds'
    when 'stellar-instant' then 'https://fundednext.com/usa/cfds'
    else 'https://fundednext.com/usa/cfds/stellar-2-step'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id and programs.slug in ('stellar-2-step', 'stellar-1-step', 'stellar-lite', 'stellar-instant')
where firms.slug = 'fundednext'
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
