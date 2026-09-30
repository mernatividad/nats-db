-- Refresh The5ers Forex programs from first-party program pages reviewed 2026-09-28.
-- The public site currently presents High Stakes, Bootcamp, Pro Growth, and Hyper Growth.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set description = 'The5ers offers Forex evaluation programs including High Stakes, Bootcamp, and Growth, with program-specific rules and scaling paths.',
    website_url = 'https://the5ers.com/',
    updated_at = now()
where slug = 'the5ers';

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets)
select firms.id, 'GB', 'FIVE PERCENT ONLINE LTD', array['FX', 'Metals', 'Indices', 'Oil', 'Crypto']::text[]
from bullish_banana.firms
where firms.slug = 'the5ers'
on conflict (firm_id) do update
set country_code = excluded.country_code,
    legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://the5ers.com/high-stakes/', 'The5ers official program and company information', 'First-party page identifies the current High Stakes offer, available assets, MT5 Hedge platform, company operator, and operating/risk notices.'
from bullish_banana.firms
where firms.slug = 'the5ers'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://the5ers.com/high-stakes/');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Reviewed The5ers first-party program and company information on 2026-09-28; legal operator and program assets/platform were captured from the official site.'
from bullish_banana.firms
where firms.slug = 'the5ers';

-- The current High Stakes page's $2.5K New Classic table shows 10% / 5% targets.
update bullish_banana.programs
set name = 'The5ers High Stakes New Classic',
    description = 'Two-step evaluation shown for the $2,500 New Classic account: 10% then 5% targets, with 5% daily and 10% maximum loss limits.',
    account_sizes = '[2500]'::jsonb,
    max_leverage = 100,
    profit_split_percent = null,
    payout_frequency = null,
    minimum_trading_days = null,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = jsonb_build_object(
      'payout_rules', 'Official page states an 80%–100% profit share and describes fixed-payout eligibility in its scaling plan. Exact payout timing is not stated on this page.',
      'fee_refund_policy', 'The displayed $2,500 New Classic table lists a $19 Step 1 cost and marks Step 2 as refund; verify checkout terms before relying on this price.',
      'consistency_rule', 'Three profitable days are required in each challenge phase. A profitable day is defined as closed-position profit of at least 0.5% of initial balance, calculated using the page-stated midnight balance/equity formula.',
      'prohibited_strategies', 'Trading within two minutes before or after high-impact news events is not allowed.',
      'commission_details', 'Not stated on the reviewed program page.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers')
  and slug = 'high-stakes';

update bullish_banana.sources
set source_label = 'The5ers High Stakes current rules',
    notes = 'Refreshed 2026-09-28 from the current first-party page. The displayed $2.5K New Classic variant states 10% then 5% targets, 5% daily loss, 10% maximum loss, three minimum profitable days, unlimited time, MT5 Hedge, overnight/weekend permission, and a two-minute high-impact-news restriction.'
where program_id = (select programs.id from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id where firms.slug = 'the5ers' and programs.slug = 'high-stakes')
  and source_url in ('https://the5ers.com/high-stakes', 'https://the5ers.com/high-stakes/');

insert into bullish_banana.program_phases (program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, minimum_trading_days, time_limit_days, raw_rules)
select programs.id, phase.phase_number, phase.name, phase.fee, phase.target, 5, 10, null, null, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join (values
  (1, 'Step 1', 19.00::numeric, 10.000::numeric, '{"account_size":2500,"variant":"New Classic","source_note":"The current official page displays the $2.5K New Classic plan with a 10% target, 5% maximum daily loss, 10% maximum loss, three minimum profitable days, unlimited time, and a $19 Step 1 cost."}'),
  (2, 'Step 2', null::numeric, 5.000::numeric, '{"account_size":2500,"variant":"New Classic","source_note":"The current official page displays a 5% target, 5% maximum daily loss, 10% maximum loss, three minimum profitable days, unlimited time, and labels the Step 2 cost as refund."}')
) as phase(phase_number, name, fee, target, raw_rules) on true
where programs.slug = 'high-stakes'
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    minimum_trading_days = excluded.minimum_trading_days, time_limit_days = excluded.time_limit_days,
    raw_rules = excluded.raw_rules, updated_at = now();

-- Create current page variants as separate programs so their commercial terms remain distinct.
insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details, published_at)
select firms.id, item.name, item.slug, item.description, 'evaluation', 'published', 'USD', item.account_sizes::jsonb,
       item.max_leverage, null, null, item.minimum_trading_days, true, true, item.commercial_details::jsonb, now()
from bullish_banana.firms
join (values
  ('The5ers Bootcamp', 'bootcamp', 'Three evaluation steps with published balance progression from $5,000 to a $15,000 Step 3, followed by a $20,000 Pro Trader plan.', '[5000]', 30::numeric, null::integer,
   '{"payout_rules":"The official page lists a 5% target for the $20,000 Pro Trader stage and profit share up to 100%. It shows 4% max loss, a 3% daily pause, and a $50 Pro Trader cost; payout timing is not stated.","fee_refund_policy":"The page lists a $22 Step 1 entry cost and a $50 Pro Trader cost after the three evaluation steps. Intermediate steps show no separate cost; confirm applicable checkout terms.","prohibited_strategies":"A maximum of four active Bootcamp accounts is stated; each active account must use a different strategy and method. Accounts with no activity for more than 30 consecutive days close.","commission_details":"Not stated on the reviewed program page."}'),
  ('The5ers Pro Growth', 'pro-growth', 'One-step Growth evaluation with a 10% target, 6% stop-out level, 3% daily loss, unlimited time, and three minimum profitable days.', '[5000]', 30::numeric, 3,
   '{"payout_rules":"The official page states profit share up to 100%; payout ratio varies in its scaling table. Payout timing is not stated on the reviewed page.","fee_refund_policy":"The displayed $5K Pro Growth plan lists a $52 one-time fee.","prohibited_strategies":"News trading is allowed except bracket strategies around news and other strategies restricted by the official terms. Accounts inactive for more than 30 consecutive days expire.","commission_details":"Not stated on the reviewed program page."}'),
  ('The5ers Hyper Growth', 'hyper-growth', 'One-step Growth evaluation with a 10% target, 6% stop-out level, 3% daily loss, and unlimited time. The page lists no minimum profitable days for this plan.', '[5000]', 30::numeric, null,
   '{"payout_rules":"The official page states profit share up to 100%; profit share varies in its scaling table. Payout timing is not stated on the reviewed page.","fee_refund_policy":"The reviewed official page lists a bonus from $15, not a one-time fee; the fee is not stated.","prohibited_strategies":"News trading is allowed except bracket strategies around news and other strategies restricted by the official terms. Accounts inactive for more than 30 consecutive days expire.","commission_details":"Not stated on the reviewed program page."}')
) as item(name, slug, description, account_sizes, max_leverage, minimum_trading_days, commercial_details) on true
where firms.slug = 'the5ers'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = excluded.status, currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, time_limit_days, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, phase.fee, phase.target, phase.daily_loss, phase.max_loss, null, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join (values
  ('bootcamp', 1, 'Step 1', 22.00::numeric, 6.000::numeric, null::numeric, 5.000::numeric, null::integer, '{"initial_balance":5000,"bonus":"$2 Hub Credit","source_note":"Official Bootcamp page shows $5,000 initial balance, 6% target, 5% max loss, unlimited time, and $22 entry cost."}'),
  ('bootcamp', 2, 'Step 2', null::numeric, 6.000::numeric, null::numeric, 5.000::numeric, null::integer, '{"initial_balance":10000,"source_note":"Official Bootcamp page shows $10,000 initial balance, 6% target, 5% max loss, and unlimited time."}'),
  ('bootcamp', 3, 'Step 3', null::numeric, 6.000::numeric, null::numeric, 5.000::numeric, null::integer, '{"initial_balance":15000,"post_evaluation_pro_trader":{"initial_balance":20000,"profit_target_percent":5,"maximum_loss_percent":4,"daily_pause_percent":3,"profit_share":"up to 100%","cost":50},"source_note":"Official Bootcamp page shows $15,000 initial balance, 6% target, 5% max loss, and unlimited time for Step 3. Its Pro Trader column is the subsequent funded stage, not a fourth evaluation phase."}'),
  ('pro-growth', 1, 'Growth evaluation', 52.00::numeric, 10.000::numeric, 3.000::numeric, 6.000::numeric, 3::integer, '{"source_note":"Official Growth page lists a 10% evaluation target, 6% stop-out level, 3% daily loss, unlimited time, and three minimum profitable days for Pro Growth."}'),
  ('hyper-growth', 1, 'Growth evaluation', null::numeric, 10.000::numeric, 3.000::numeric, 6.000::numeric, null::integer, '{"source_note":"Official Growth page lists a 10% evaluation target, 6% stop-out level, 3% daily loss, unlimited time, and no minimum profitable days for Hyper Growth."}')
) as phase(program_slug, phase_number, name, fee, target, daily_loss, max_loss, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    time_limit_days = excluded.time_limit_days, minimum_trading_days = excluded.minimum_trading_days,
    raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug)
values ('MetaTrader 5 Hedge', 'metatrader-5-hedge')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join bullish_banana.platforms on platforms.slug = 'metatrader-5-hedge'
where programs.slug in ('high-stakes', 'bootcamp', 'pro-growth', 'hyper-growth')
on conflict do nothing;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join (values
  ('high-stakes', 'https://the5ers.com/high-stakes/', 'The5ers High Stakes', 'Current first-party page states the $2.5K New Classic two-step structure, targets, loss limits, time, minimum profitable days, platform, assets, news window, weekend policy, and scaling terms.'),
  ('bootcamp', 'https://the5ers.com/bootcamp/', 'The5ers Bootcamp', 'Current first-party page states the three-step balance/target/max-loss progression, leverage, time, costs displayed for Step 1 and Pro Trader, account rules, and weekend policy.'),
  ('pro-growth', 'https://the5ers.com/hyper-growth/', 'The5ers Growth — Pro Growth', 'Current first-party Growth page distinguishes Pro Growth and states its evaluation target, stop-out, daily loss, time, leverage, $5K plan fee, minimum profitable days, assets, platform, news and weekend policies.'),
  ('hyper-growth', 'https://the5ers.com/hyper-growth/', 'The5ers Growth — Hyper Growth', 'Current first-party Growth page distinguishes Hyper Growth and states its evaluation target, stop-out, daily loss, time, leverage, minimum profitable days, assets, platform, news and weekend policies; the listed bonus amount is not recorded as a fee.')
) as source(program_slug, url, label, notes) on true
where programs.slug = source.program_slug
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed against the current official The5ers program page on 2026-09-28. Only displayed terms are normalized; unlisted prices, timing, or account options remain unstated.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
where programs.slug in ('high-stakes', 'bootcamp', 'pro-growth', 'hyper-growth');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit ' || programs.name, source.url, true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id and programs.slug in ('high-stakes', 'bootcamp', 'pro-growth', 'hyper-growth')
join (values
  ('high-stakes', 'https://the5ers.com/high-stakes/'),
  ('bootcamp', 'https://the5ers.com/bootcamp/'),
  ('pro-growth', 'https://the5ers.com/hyper-growth/'),
  ('hyper-growth', 'https://the5ers.com/hyper-growth/')
) as source(program_slug, url) on source.program_slug = programs.slug
where firms.slug = 'the5ers'
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
