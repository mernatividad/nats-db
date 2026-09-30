set search_path = bullish_banana, extensions, public;

-- Refresh The5ers records already created by 2026-09-28 data research.
update bullish_banana.firms
set description = 'The5ers offers Forex evaluation paths including High Stakes, Bootcamp, Growth/Hyper Growth and Pro Growth, with simulated evaluations and scaled performance stages.',
    website_url = 'https://the5ers.com/',
    updated_at = now()
where slug = 'the5ers';

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'futures' from bullish_banana.firms where slug = 'the5ers'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select firms.id, 'GB', 'FIVE PERCENT ONLINE LTD', array['FX','Metals','Indices','Oil','Crypto']::text[],
  '{"brand":"The5ers","service_model":"Simulated trading evaluation followed, at the provider’s discretion and subject to verification, by professional-user performance trading.","website_operators":[{"name":"FIVE PERCENT ONLINE LTD","jurisdiction":"United Kingdom","company_number":"12553363"},{"name":"FIVE PERCENT ONLINE LTD","jurisdiction":"Israel","company_number":"515864007"}],"governing_law":"Israel","platforms":["MetaTrader 5 Hedge"],"restriction_list_non_exhaustive":true,"listed_forbidden_territories":["Afghanistan","Belarus","Bosnia and Herzegovina","Burundi","Central African Republic","Cuba","Congo Republic","Crimea","Democratic Republic of Congo","Eritrea","Guinea","Guinea-Bissau","Iraq","Iran","Israel","Laos","Lebanon","Liberia","Libya","Myanmar","North Korea","Palestinian Territory","Papua New Guinea","Russia","South Sudan","Sudan","Somalia","Syria","Vanuatu","Venezuela","Yemen"],"profile_review":"Terms identify two website operators; verify the contracting entity for each checkout and recheck the non-exhaustive restrictions before publication."}'::jsonb
from bullish_banana.firms where firms.slug = 'the5ers'
on conflict (firm_id) do update
set country_code = excluded.country_code,
    legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

-- The existing High Stakes record represents the displayed $2.5K New Classic view;
-- New and Classic are account-limit configurations, not verified independent challenges.
update bullish_banana.programs
set name = 'The5ers High Stakes (New Classic view)',
    description = 'Two-step simulated evaluation. Current High Stakes materials show 10% then 5% targets, 5% daily loss, 10% maximum loss, three profitable days in each phase, and unlimited time.',
    status = 'in_review',
    currency = 'USD',
    account_sizes = '[2500,5000,10000,25000,50000,100000]'::jsonb,
    max_leverage = 100,
    profit_split_percent = 80,
    payout_frequency = 'Every 14 days after funding',
    minimum_trading_days = 3,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = coalesce(commercial_details, '{}'::jsonb) || '{"account_size_prices":[{"account_size":2500,"fee":19,"currency":"USD"},{"account_size":100000,"fee":545,"currency":"USD"}],"payout_rules":"Payouts may be requested every 14 days after funding. Official help lists account-dependent payout caps/minimums; the full matrix is not captured.","fee_refund_policy":"The High Stakes help page says 70% of the externally paid fee is added to funded-account equity and may be withdrawn with first payout after at least 14 active days and $150 P&L. Terms say fees become non-refundable after evaluation trading begins. Resolve this scope conflict.","news_rule":"High Stakes trades may be held over high-impact news. New order execution within two minutes before/after high-impact news is restricted; window profit is excluded and losses remain the trader’s.","profitable_day_definition":"At least 0.5% of initial balance in closed-position profit, calculated from the minimum of midnight balance/equity minus previous-day balance.","account_limits":"Current official Help Center distinguishes New and Classic account limits. Their separate account counts do not establish separate challenge rule sets.","review_note":"Only the official $2.5K $19 table and a $100K $545 example are captured. Full size/fee schedule, selector mapping and New/Classic commercial differences remain open."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers') and slug = 'high-stakes';

update bullish_banana.programs
set status = 'in_review',
    description = 'Three-step Bootcamp evaluation with a progressive balance path before the performance stage; size and pricing vary by selected account.',
    account_sizes = '[20000,100000,250000]'::jsonb,
    max_leverage = 30,
    profit_split_percent = 50,
    payout_frequency = 'Every 14 days after funded account',
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = coalesce(commercial_details, '{}'::jsonb) || '{"account_size_prices":[{"account_size":20000,"fee":22,"post_pass_fee":50,"total_fee":72,"currency":"USD"},{"account_size":100000,"fee":95,"post_pass_fee":205,"total_fee":300,"currency":"USD"},{"account_size":250000,"fee":225,"post_pass_fee":350,"total_fee":575,"currency":"USD"}],"fee_refund_policy":"Official Help Center says Bootcamp fees are non-refundable.","funded_rules":"3% daily pause and 4% max loss apply to funded stage; 30-day inactivity closure; payout requests start 14 days after funded account and repeat every 14 days.","trading_conditions":"1:30 leverage. News trading is allowed except bracket strategies. Overnight and weekend holding allowed; high index swaps may apply.","review_note":"Confirm the official selector offers all fee-table sizes and verify size-to-balance progression before publication."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers') and slug = 'bootcamp';

update bullish_banana.programs
set status = 'in_review',
    description = 'One-step Pro Growth evaluation. The current $5K example shows a 10% target, 3% daily loss, 6% stop-out, three profitable days and unlimited time.',
    account_sizes = '[5000]'::jsonb,
    max_leverage = 30,
    profit_split_percent = 75,
    minimum_trading_days = 3,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = coalesce(commercial_details, '{}'::jsonb) || '{"account_size_prices":[{"account_size":5000,"fee":52,"currency":"USD"}],"payout_rules":"Current profit-split FAQ says Pro Growth starts at 75% and may scale to 100%; payout timing remains unverified.","review_note":"Confirm current selector availability and the complete size/fee schedule before publication."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers') and slug = 'pro-growth';

update bullish_banana.programs
set name = 'The5ers Growth (Hyper Growth)',
    status = 'in_review',
    description = 'One-step Growth/Hyper Growth evaluation family. Current official pages use both Growth and Hyper Growth naming; offer mapping needs confirmation.',
    account_sizes = '[5000]'::jsonb,
    max_leverage = 30,
    profit_split_percent = 50,
    minimum_trading_days = null,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = coalesce(commercial_details, '{}'::jsonb) || '{"payout_rules":"Current profit-split FAQ says Hyper Growth starts at 50% and may scale to 100%; exact payout timing is not verified.","review_note":"Resolve Growth vs Hyper Growth labels and capture current selectable sizes and base fees before publication."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers') and slug = 'hyper-growth';

insert into bullish_banana.program_phases (program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, phase.fee, phase.target, phase.daily, phase.maximum, phase.drawdown_type, null, phase.days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join (values
  ('high-stakes', 1, 'High Stakes Step 1', 19.00::numeric, 10.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 3::integer, '{"day_requirement_label":"3 profitable days","minimum_profitable_days":3,"account_size":2500,"variant":"New Classic view","source_note":"Current official page, reviewed 2026-09-30."}'),
  ('high-stakes', 2, 'High Stakes Step 2', null::numeric, 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 3::integer, '{"day_requirement_label":"3 profitable days","minimum_profitable_days":3,"account_size":2500,"variant":"New Classic view","source_note":"Current official page, reviewed 2026-09-30."}'),
  ('bootcamp', 1, 'Bootcamp Step 1', 22.00::numeric, 6.000::numeric, null::numeric, 5.000::numeric, 'static', null::integer, '{"initial_balance":5000,"source_note":"Current Bootcamp page: 6% target, 5% max loss, unlimited time."}'),
  ('bootcamp', 2, 'Bootcamp Step 2', null::numeric, 6.000::numeric, null::numeric, 5.000::numeric, 'static', null::integer, '{"initial_balance":10000,"source_note":"Current Bootcamp page: 6% target, 5% max loss, unlimited time."}'),
  ('bootcamp', 3, 'Bootcamp Step 3', null::numeric, 6.000::numeric, null::numeric, 5.000::numeric, 'static', null::integer, '{"initial_balance":15000,"post_evaluation_pro_trader":{"initial_balance":20000,"profit_target_percent":5,"maximum_loss_percent":4,"daily_pause_percent":3,"profit_share":"up to 100%","cost":50},"source_note":"Pro Trader stage is funded/performance stage, not an evaluation phase."}'),
  ('pro-growth', 1, 'Pro Growth evaluation', 52.00::numeric, 10.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 3::integer, '{"day_requirement_label":"3 profitable days","minimum_profitable_days":3,"source_note":"Current $5K example on the official Growth page."}'),
  ('hyper-growth', 1, 'Growth / Hyper Growth evaluation', null::numeric, 10.000::numeric, 3.000::numeric, 6.000::numeric, 'static', null::integer, '{"source_note":"Current official page shows a 10% target, 3% daily loss, 6% stop-out, and no minimum profitable-day count for Hyper Growth; current offer naming/mapping remains under review."}')
) as phase(program_slug, phase_number, name, fee, target, daily, maximum, drawdown_type, days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

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

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://the5ers.com/terms-and-conditions/', 'The5ers Terms and Conditions', 'Reviewed 2026-09-30. Terms describe simulated evaluation, discretionary professional-user acceptance, fee/refund conditions, non-exhaustive forbidden territories, two website-operating legal entities, and Israeli governing law.'
from bullish_banana.firms where firms.slug = 'the5ers'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = firms.id and s.source_url = 'https://the5ers.com/terms-and-conditions/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join (values
  ('high-stakes', 'https://the5ers.com/high-stakes/', 'The5ers High Stakes', 'Current page reviewed 2026-09-30. States 10% then 5% targets, 5% daily loss, 10% max loss, three profitable days, no time limit, 1:100 leverage, MT5 Hedge, overnight/weekend holding, and account-size/capacity limits.'),
  ('high-stakes', 'https://the5ers.com/faqs/how-many-high-stakes-accounts-can-i-have/', 'The5ers High Stakes account limits', 'Updated 2026-09-15. Distinguishes New and Classic account limits; this does not establish separate challenge rules or independent program records.'),
  ('high-stakes', 'https://the5ers.com/faqs/payout-policy-and-hub-credit-in-the-high-stakes-program/', 'The5ers High Stakes payout and fee policy', 'Updated 2026-09-14. Payouts every two weeks after funding, account-size payout caps/minimums, and 70% fee amount eligible after 14 active days and $150 P&L. Terms contain a conflicting fee non-refund clause after trading begins.'),
  ('high-stakes', 'https://the5ers.com/faqs/can-i-trade-during-news/', 'The5ers news rules', 'Updated 2026-08-10. High Stakes order execution in the two minutes before/after high-impact news is restricted; holding trades is allowed; window profits do not count and losses remain trader losses.'),
  ('bootcamp', 'https://the5ers.com/bootcamp/', 'The5ers Bootcamp', 'Current official page reviewed 2026-09-30. Three 6% evaluation targets, 5% max loss per evaluation stage, 1:30 leverage, no time limit and balance progression.'),
  ('bootcamp', 'https://the5ers.com/faqs/how-does-the-bootcamp-program-work/', 'The5ers Bootcamp rules', 'Updated 2026-09-06. Non-refundable fee, no time limit, 30-day inactivity, 14-day payout cycle, news except bracketing, weekend holding and funded daily-pause details.'),
  ('pro-growth', 'https://the5ers.com/hyper-growth/', 'The5ers Growth — Pro Growth', 'Current official page reviewed 2026-09-30. $5K example: 10% target, 3% daily loss, 6% stop-out, three profitable days and $52 fee.'),
  ('hyper-growth', 'https://the5ers.com/hyper-growth/', 'The5ers Growth / Hyper Growth', 'Current official page reviewed 2026-09-30. Growth naming differs between current site navigation and Help Center. 10% target, 3% daily loss, 6% stop-out; verify current offer mapping.'),
  ('pro-growth', 'https://the5ers.com/faqs/how-much-is-the-profit-split-in-the5ers/', 'The5ers profit split guidance', 'Updated 2026-06-14. High Stakes starts at 80%, Bootcamp and Hyper Growth at 50%, Pro Growth at 75%; scaling may reach 100% subject to program conditions.')
) as source(program_slug, url, label, notes) on true
where programs.slug = source.program_slug
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Reviewed current The5ers Terms, program pages and Help Center on 2026-09-30. Legal operators and restrictions are captured; purchase-level contracting entity and full restrictions still need confirmation.'
from bullish_banana.firms where firms.slug = 'the5ers';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed current official program page and Help Center on 2026-09-30. Program remains in_review until complete current fees, size mapping, funded terms and variant naming are verified.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
where programs.slug in ('high-stakes', 'bootcamp', 'pro-growth', 'hyper-growth');

