set search_path = bullish_banana, extensions, public;

-- Refresh Alpha Capital's currently buyable Forex lineup from first-party sources reviewed 2026-09-30.
update bullish_banana.firms
set name = 'Alpha Capital',
    description = 'UK-based simulated evaluation provider offering Alpha One, Alpha Pro, Alpha Swing and Alpha Direct Forex paths.',
    website_url = 'https://alphacapitalgroup.uk/',
    updated_at = now()
where slug = 'alpha-capital-group';

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'alpha-capital-group'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, established_on, legal_entity_name, supported_assets, profile_details)
select firms.id, 'GB', null, 'Alpha Capital Group Limited', array['Forex','Metals','Indices','Oil']::text[],
  '{"company_number":"13719951","registered_office":"1 Allied Business Centre, Coldharbour Lane, Harpenden, England, AL5 4UT","service_model":"Simulated evaluation and virtual qualified accounts; the Terms say traders do not access live markets or control live funds.","website_operating_entity":"Alpha Capital Group Limited","supported_markets":"Forex, metals, indices and oil are identified in plan-specific leverage tables.","platforms_note":"Product pages expose platform selection at checkout. Help Center references MetaTrader 5, cTrader, DXtrade and TradeLocker; exact platform availability by plan remains to verify.","restriction_note":"Terms limit service to countries where available but do not provide a complete country list in the reviewed pages. Confirm current checkout eligibility for each jurisdiction.","account_allocation":"Up to $400,000 total qualified allocation per household and $300,000 per strategy/asset are described in the current Help Center.","profile_review":"No complete official country eligibility list or per-product platform map was captured."}'::jsonb
from bullish_banana.firms where firms.slug = 'alpha-capital-group'
on conflict (firm_id) do update
set country_code = excluded.country_code,
    legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

update bullish_banana.programs
set status = 'in_review',
    name = 'Alpha Pro 8%',
    description = 'Two-step simulated evaluation: 8% Phase 1 target and 5% Phase 2 target, 8% static max loss, 4% balance-based daily limit and three minimum trading days per phase.',
    account_sizes = '[5000,10000,25000,50000,100000,200000]'::jsonb,
    max_leverage = 100,
    profit_split_percent = 80,
    payout_frequency = 'On-demand or bi-weekly, selected at purchase',
    minimum_trading_days = 3,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = coalesce(commercial_details, '{}'::jsonb) || '{"account_size_prices":[{"account_size":25000,"fee":177,"currency":"USD"}],"price_schedule_note":"The official 2026 price article reports $177 for Alpha Pro 8% at $25K on-demand. Full size and bi-weekly matrices are not captured.","payout_rules":"80% standard performance fee. Bi-weekly or on-demand cadence is selected at purchase; on-demand requires at least 2% gross profit and a 40% Best Day Rule. Bi-weekly requires at least $100 gross profit and five trading days before first request.","funded_rules":"Alpha Pro qualified accounts cannot hold over weekends. Qualified account trade execution is restricted around specified high-impact news windows.","news_rule":"Evaluation trading is unrestricted. Qualified Pro account trading is restricted for opening or closing on targeted instruments from five minutes before to five minutes after applicable releases.","commission_details":"Standard evaluation has no commissions; Raw evaluation is $2.50 per lot per transaction, both directions. Optional swap-free changes commission and disables EAs.","platforms_note":"MT5, cTrader, DXtrade and TradeLocker are referenced in official material; exact option mapping for this plan remains unverified.","review_note":"Complete Pro 8% and Pro 10% account-size fee matrices and product-specific platform options remain outstanding."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'alpha-capital-group') and slug = 'alpha-pro-8';

insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details)
select firms.id, candidate.name, candidate.slug, candidate.description, candidate.program_type, 'in_review', 'USD', candidate.account_sizes::jsonb, candidate.max_leverage, candidate.profit_split_percent, candidate.payout_frequency, candidate.minimum_trading_days, candidate.news_allowed, candidate.weekend_holding_allowed, candidate.commercial_details::jsonb
from bullish_banana.firms
join (values
  ('Alpha One 10%', 'alpha-one-10', 'One-step simulated evaluation with a 10% target, 6% high-water-mark trailing max loss, 4% daily loss and one minimum trading day.', 'evaluation', '[5000,10000,25000,50000,100000,200000]', 30::numeric, 80::numeric, 'On-demand', 1::integer, true, true,
   '{"account_size_prices":[{"account_size":5000,"fee":47,"currency":"USD"},{"account_size":10000,"fee":87,"currency":"USD"},{"account_size":25000,"fee":187,"currency":"USD"},{"account_size":50000,"fee":277,"currency":"USD"},{"account_size":100000,"fee":477,"currency":"USD"},{"account_size":200000,"fee":947,"currency":"USD"}],"price_schedule_note":"Official Alpha Capital pricing article states these Alpha One 10% checkout prices as of 2026-09-21; active promotions excluded. Article says 6% and 12% variants were unavailable for new purchases at that capture.","payout_rules":"80% standard performance fee; optional 90% add-on. On-demand requests require 2% gross profit and 40% Best Day Rule.","news_rule":"Evaluation news trading unrestricted. Qualified account: no opening or closing positions on targeted instruments in the five minutes before/after listed releases.","weekend_rule":"Weekend holding allowed in evaluation and Qualified Account.","review_note":"Reconfirm pricing and live selector; current plan page still advertises multiple target variants while the 2026-09-21 price article says only 10% was buyable."}'),
  ('Alpha Pro 6%', 'alpha-pro-6', 'Two-step simulated evaluation with 6% targets in each phase, 6% static max loss, 3% daily loss and three minimum trading days per phase.', 'evaluation', '[5000,10000,25000,50000,100000,200000]', 100::numeric, 80::numeric, 'On-demand or bi-weekly', 3::integer, true, true,
   '{"account_size_prices":[{"account_size":5000,"fee":27,"currency":"USD"},{"account_size":10000,"fee":47,"currency":"USD"},{"account_size":25000,"fee":117,"currency":"USD"},{"account_size":50000,"fee":217,"currency":"USD"},{"account_size":100000,"fee":397,"currency":"USD"},{"account_size":200000,"fee":797,"currency":"USD"}],"price_schedule_note":"Official 2026 price article labels these Alpha Pro 6% fees On-Demand prices; bi-weekly prices are higher and not captured.","payout_rules":"80% standard performance fee; bi-weekly or on-demand choice is fixed at signup. On-demand requires 2% gross profit and 40% Best Day Rule; bi-weekly requires $100 gross profit and five trading days before first request.","funded_rules":"Qualified Alpha Pro accounts cannot hold positions over weekends.","news_rule":"Evaluation news trading unrestricted; Qualified account opening and closing on targeted instruments restricted within five minutes of listed high-impact events.","review_note":"Bi-weekly price matrix, full product selector and per-platform availability remain to verify."}'),
  ('Alpha Pro 10%', 'alpha-pro-10', 'Two-step simulated evaluation with 10% then 5% targets, 10% static max loss, 5% balance-based daily limit and three minimum trading days per phase.', 'evaluation', '[5000,10000,25000,50000,100000,200000]', 100::numeric, 80::numeric, 'On-demand or bi-weekly', 3::integer, true, true,
   '{"payout_rules":"80% standard performance fee; bi-weekly or on-demand choice is fixed at signup. On-demand requires 2% gross profit and 40% Best Day Rule; bi-weekly requires $100 gross profit and five trading days before first request.","funded_rules":"Qualified Alpha Pro accounts cannot hold positions over weekends.","news_rule":"Evaluation news trading unrestricted; Qualified account opening and closing on targeted instruments restricted within five minutes of listed high-impact events.","review_note":"Full account-size checkout prices, per-platform availability and selected fee cadence prices remain to verify."}'),
  ('Alpha Swing', 'alpha-swing', 'Two-step simulated evaluation with 10% then 5% targets, 10% static max loss, 5% balance-based daily loss and three minimum days per phase.', 'evaluation', '[5000,10000,25000,50000,100000,200000]', 30::numeric, 80::numeric, 'On-demand only', 3::integer, true, true,
   '{"payout_rules":"80% standard performance fee. On-demand only; requests require 2% gross profit and a 40% Best Day Rule.","news_rule":"Major news trading is allowed. If a trade opens in the two minutes before/after release, its duration must exceed two minutes.","weekend_rule":"Weekend holding allowed in evaluation and Qualified Account.","review_note":"Complete account-size checkout fees, platform options and funded add-ons remain to verify."}'),
  ('Alpha Direct', 'alpha-direct', 'Instant-qualified simulated account with no evaluation target, 5% high-water-mark trailing max loss, 3% daily loss and 1% maximum open risk per asset.', 'instant_funding', '[2500,5000,10000,25000,50000,100000,200000]', 30::numeric, 90::numeric, 'On-demand only', null::integer, true, false,
   '{"payout_rules":"90% performance fee. First on-demand request requires a 3% retained profit buffer plus at least 1% additional gross profit and the 15% Best Day Rule.","risk_rule":"1% maximum open drawdown per asset from first trade; 10-minute same-asset, same-direction loss combination rule applies.","news_rule":"News trading allowed except opening or closing trades on targeted instruments within five minutes before/after listed releases.","weekend_rule":"Weekend holding is not allowed.","ea_rule":"Expert Advisors are disabled.","account_limitations":"Alpha Direct accounts cannot be merged or scaled; maximum allocation is shared across Alpha Capital plans.","review_note":"Current product page confirms size range to $200K but complete live fee schedule and platform mapping have not been captured."}')
) as candidate(name, slug, description, program_type, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details) on true
where firms.slug = 'alpha-capital-group'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = excluded.status, currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = coalesce(bullish_banana.programs.commercial_details, '{}'::jsonb) || excluded.commercial_details,
    updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily, phase.maximum, phase.drawdown_type, null, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group'
join (values
  ('alpha-pro-8', 1, 'Alpha Pro 8% Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3::integer, '{"source_note":"Official 8% plan guide and Terms reviewed 2026-09-30."}'),
  ('alpha-pro-8', 2, 'Alpha Pro 8% Phase 2', 5.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3::integer, '{"source_note":"Official 8% plan guide and Terms reviewed 2026-09-30."}'),
  ('alpha-one-10', 1, 'Alpha One 10% evaluation', 10.000::numeric, 4.000::numeric, 6.000::numeric, 'high-water-mark-trailing', 1::integer, '{"source_note":"Official current Alpha One guide; high-water-mark trailing max loss remains until capped at initial balance."}'),
  ('alpha-pro-6', 1, 'Alpha Pro 6% Phase 1', 6.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 3::integer, '{"source_note":"Official Alpha Pro 6% Help Center guide reviewed 2026-09-30."}'),
  ('alpha-pro-6', 2, 'Alpha Pro 6% Phase 2', 6.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 3::integer, '{"source_note":"Official Alpha Pro 6% Help Center guide reviewed 2026-09-30."}'),
  ('alpha-pro-10', 1, 'Alpha Pro 10% Phase 1', 10.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 3::integer, '{"source_note":"Official Alpha Pro 8%/10% Help Center guide and current Terms reviewed 2026-09-30."}'),
  ('alpha-pro-10', 2, 'Alpha Pro 10% Phase 2', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 3::integer, '{"source_note":"Official Alpha Pro 8%/10% Help Center guide and current Terms reviewed 2026-09-30."}'),
  ('alpha-swing', 1, 'Alpha Swing Phase 1', 10.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 3::integer, '{"source_note":"Official Alpha Swing Help Center guide reviewed 2026-09-30."}'),
  ('alpha-swing', 2, 'Alpha Swing Phase 2', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 3::integer, '{"source_note":"Official Alpha Swing Help Center guide reviewed 2026-09-30."}')
) as phase(program_slug, phase_number, name, target, daily, maximum, drawdown_type, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://alphacapitalgroup.uk/terms-and-conditions', 'Alpha Capital Group current Terms', 'Reviewed 2026-09-30. Identifies Alpha Capital Group Limited (England and Wales company 13719951), simulated services, plan rules, allocation limits, account conditions and jurisdiction availability wording.'
from bullish_banana.firms where firms.slug = 'alpha-capital-group'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = firms.id and s.source_url = 'https://alphacapitalgroup.uk/terms-and-conditions');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group'
join (values
  ('alpha-one-10', 'https://alphacapitalgroup.uk/product/alpha-one', 'Alpha One official product page', 'Current official page describes one-step simulated evaluation, target/drawdown variants, account size range, fees and risk rules. The 2026-09-21 official pricing article reports only One 10% available for new checkout at capture.'),
  ('alpha-one-10', 'https://help.alphacapitalgroup.uk/en/articles/10097421-alpha-one-6-10-12', 'Alpha One evaluation rules', 'Updated 2026-07-22. Defines targets, trailing max loss, daily limits, minimum days, leverage, asset-specific maximum lots, news and weekend terms.'),
  ('alpha-one-10', 'https://alphacapitalgroup.uk/posts/how-much-does-a-prop-firm-evaluation-cost-2026', 'Alpha Capital fee schedule, 2026-09-21 capture', 'Official article says live checkout list fees for Alpha One 10% at $5K–$200K and notes Alpha One 6% and 12% were not purchasable at that capture. Promotions excluded.'),
  ('alpha-pro-6', 'https://help.alphacapitalgroup.uk/en/articles/11378706-alpha-pro-6', 'Alpha Pro 6% rules', 'Updated 2026-07-22. Defines 6%/6% targets, 6% static max loss, 3% daily loss based on highest end-of-day balance/equity, three minimum days per phase and leverage.'),
  ('alpha-pro-6', 'https://alphacapitalgroup.uk/posts/how-much-does-a-prop-firm-evaluation-cost-2026', 'Alpha Pro 6% on-demand fee schedule', 'Official article captured 2026-09-21 lists size-specific on-demand base prices; bi-weekly prices are higher and not captured.'),
  ('alpha-pro-8', 'https://help.alphacapitalgroup.uk/en/articles/8420429-alpha-pro-8-10', 'Alpha Pro 8% and 10% rules', 'Updated 2026-07-22. Defines 8%/5% and 10%/5% targets, respective static/daily loss limits, three days per phase and leverage.'),
  ('alpha-pro-8', 'https://help.alphacapitalgroup.uk/en/articles/16004122-90-profit-split-and-swap-free-add-ons', 'Alpha plan add-ons', 'Updated 2026-07-24. Describes optional 90% split and swap-free add-on availability and a $25K Pro 8% on-demand fee example; full schedule remains incomplete.'),
  ('alpha-pro-10', 'https://help.alphacapitalgroup.uk/en/articles/8420429-alpha-pro-8-10', 'Alpha Pro 10% rules', 'Updated 2026-07-22. Defines 10% then 5% targets, 10% static max loss, 5% daily loss, three days per phase and leverage.'),
  ('alpha-swing', 'https://help.alphacapitalgroup.uk/en/articles/9789907-alpha-swing', 'Alpha Swing rules', 'Updated 2026-07-24. Defines 10% then 5% targets, 10% static max loss, 5% balance-based daily loss, three days each phase, 1:30 FX leverage, news exception, weekend rules, and on-demand eligibility.'),
  ('alpha-direct', 'https://help.alphacapitalgroup.uk/en/articles/16003693-alpha-direct', 'Alpha Direct rules', 'Updated 2026-07-24. No evaluation, 5% trailing max loss, 3% daily loss, 1% maximum risk per asset, 90% split, 3% buffer plus 1% request threshold and 15% Best Day Rule; weekend/EA/account limits.'),
  ('alpha-direct', 'https://alphacapitalgroup.uk/product/alpha-direct', 'Alpha Direct official product page', 'Current product page shows instant-qualified service, account sizes $2.5K-$200K, no evaluation, 90% split and checkout-driven configurations. Current base fee matrix was not captured.'),
  ('alpha-direct', 'https://help.alphacapitalgroup.uk/en/articles/6934203-what-is-leverage-and-what-leverage-is-offered-during-the-evaluation-and-for-qualified-analyst-accounts', 'Alpha plan leverage', 'Updated 2026-07-22. Lists FX leverage by Alpha program; 1:30 for One, Swing and Direct; 1:100 for Pro.')
) as source(program_slug, url, label, notes) on true
where programs.slug = source.program_slug
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Reviewed current Alpha Capital Terms, official product pages and Help Center on 2026-09-30. Company identity, simulated service model and supported asset groups captured; country eligibility and platform mapping remain open.'
from bullish_banana.firms where firms.slug = 'alpha-capital-group';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed current first-party offer and rules on 2026-09-30. Keep in_review until all current checkout price/platform configurations and the complete account-size fee schedule are confirmed.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group'
where programs.slug in ('alpha-one-10','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing','alpha-direct');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit ' || programs.name, source.url, true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
join (values
  ('alpha-one-10','https://alphacapitalgroup.uk/product/alpha-one'),
  ('alpha-pro-6','https://alphacapitalgroup.uk/product/alpha-pro'),
  ('alpha-pro-8','https://alphacapitalgroup.uk/product/alpha-pro'),
  ('alpha-pro-10','https://alphacapitalgroup.uk/product/alpha-pro'),
  ('alpha-swing','https://alphacapitalgroup.uk/product/alpha-swing'),
  ('alpha-direct','https://alphacapitalgroup.uk/product/alpha-direct')
) as source(program_slug, url) on source.program_slug = programs.slug
where firms.slug = 'alpha-capital-group'
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');

update bullish_banana.firm_profiles
set profile_details = profile_details || '{"terms_principal_place_of_business":"6-7 Waterside Station Road, Harpenden AL5 4US","company_address_review":"The current Terms introduction gives 6-7 Waterside Station Road as principal place of business; the site footer gives 1 Allied Business Centre, Coldharbour Lane, AL5 4UT as registered office. Preserve both address claims pending corporate-record confirmation."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'alpha-capital-group');

-- Live USD base-fee matrix captured from the official product selector on 2026-09-30.
-- Payout cadence is represented separately because selector prices differ by cadence.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || price.details::jsonb,
    updated_at = now()
from bullish_banana.firms f
join (values
  ('alpha-one-10', '{"account_size_prices":[{"account_size":5000,"fee":47,"currency":"USD"},{"account_size":10000,"fee":87,"currency":"USD"},{"account_size":25000,"fee":187,"currency":"USD"},{"account_size":50000,"fee":277,"currency":"USD"},{"account_size":100000,"fee":477,"currency":"USD"},{"account_size":200000,"fee":947,"currency":"USD"}],"selector_capture":"2026-09-30","price_basis":"Base selector price; promotions excluded.","available_variants_note":"Current selector surfaced Alpha One 10% as the buyable variant; 6% and 12% were not confirmed as purchasable."}'),
  ('alpha-pro-6', '{"account_size_prices":[{"account_size":5000,"fee":27,"currency":"USD"},{"account_size":10000,"fee":47,"currency":"USD"},{"account_size":25000,"fee":117,"currency":"USD"},{"account_size":50000,"fee":217,"currency":"USD"},{"account_size":100000,"fee":397,"currency":"USD"},{"account_size":200000,"fee":797,"currency":"USD"}],"biweekly_account_size_prices":[{"account_size":5000,"fee":30,"currency":"USD"},{"account_size":10000,"fee":55,"currency":"USD"},{"account_size":25000,"fee":127,"currency":"USD"},{"account_size":50000,"fee":227,"currency":"USD"},{"account_size":100000,"fee":427,"currency":"USD"},{"account_size":200000,"fee":847,"currency":"USD"}],"selector_capture":"2026-09-30","price_basis":"Base selector prices; promotions excluded."}'),
  ('alpha-pro-8', '{"account_size_prices":[{"account_size":5000,"fee":37,"currency":"USD"},{"account_size":10000,"fee":57,"currency":"USD"},{"account_size":25000,"fee":177,"currency":"USD"},{"account_size":50000,"fee":297,"currency":"USD"},{"account_size":100000,"fee":527,"currency":"USD"},{"account_size":200000,"fee":997,"currency":"USD"}],"biweekly_account_size_prices":[{"account_size":5000,"fee":40,"currency":"USD"},{"account_size":10000,"fee":67,"currency":"USD"},{"account_size":25000,"fee":197,"currency":"USD"},{"account_size":50000,"fee":327,"currency":"USD"},{"account_size":100000,"fee":577,"currency":"USD"},{"account_size":200000,"fee":1097,"currency":"USD"}],"selector_capture":"2026-09-30","price_basis":"Base selector prices; promotions excluded."}'),
  ('alpha-pro-10', '{"account_size_prices":[{"account_size":5000,"fee":33,"currency":"USD"},{"account_size":10000,"fee":77,"currency":"USD"},{"account_size":25000,"fee":177,"currency":"USD"},{"account_size":50000,"fee":267,"currency":"USD"},{"account_size":100000,"fee":447,"currency":"USD"},{"account_size":200000,"fee":897,"currency":"USD"}],"biweekly_account_size_prices":[{"account_size":5000,"fee":37,"currency":"USD"},{"account_size":10000,"fee":87,"currency":"USD"},{"account_size":25000,"fee":197,"currency":"USD"},{"account_size":50000,"fee":297,"currency":"USD"},{"account_size":100000,"fee":497,"currency":"USD"},{"account_size":200000,"fee":997,"currency":"USD"}],"selector_capture":"2026-09-30","price_basis":"Base selector prices; promotions excluded."}'),
  ('alpha-swing', '{"account_size_prices":[{"account_size":5000,"fee":70,"currency":"USD"},{"account_size":10000,"fee":147,"currency":"USD"},{"account_size":25000,"fee":247,"currency":"USD"},{"account_size":50000,"fee":357,"currency":"USD"},{"account_size":100000,"fee":577,"currency":"USD"},{"account_size":200000,"fee":1097,"currency":"USD"}],"selector_capture":"2026-09-30","price_basis":"Base selector prices; on-demand cadence only; promotions excluded."}'),
  ('alpha-direct', '{"account_size_prices":[{"account_size":2500,"fee":30,"currency":"USD"},{"account_size":5000,"fee":67,"currency":"USD"},{"account_size":10000,"fee":97,"currency":"USD"},{"account_size":25000,"fee":197,"currency":"USD"},{"account_size":50000,"fee":257,"currency":"USD"},{"account_size":100000,"fee":457,"currency":"USD"},{"account_size":200000,"fee":897,"currency":"USD"}],"selector_capture":"2026-09-30","price_basis":"Base selector prices; instant account; promotions excluded."}')
) as price(program_slug, details) on true
where f.slug = 'alpha-capital-group' and p.firm_id = f.id and p.slug = price.program_slug;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://alphacapitalgroup.uk/product', 'Alpha Capital live product selector, captured 2026-09-30', 'Current selector matrices captured for Alpha One 10%, Alpha Pro 6/8/10 on-demand and bi-weekly, Alpha Swing on-demand, and Alpha Direct. Base prices exclude promotional codes; selector variants and terms should be rechecked before publication.'
from bullish_banana.firms where firms.slug = 'alpha-capital-group'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = firms.id and s.source_url = 'https://alphacapitalgroup.uk/product');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Re-captured current USD base fee matrices from Alpha Capital live product selector on 2026-09-30. Promotions excluded. Country matrix and plan-specific platform mapping remain open.'
from bullish_banana.firms where firms.slug = 'alpha-capital-group';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Current USD selector base prices captured on 2026-09-30 for all sizes and applicable payout cadences. Promotions excluded; keep in_review pending jurisdiction and remaining plan-specific product detail checks.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group'
where programs.slug in ('alpha-one-10','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing','alpha-direct');
