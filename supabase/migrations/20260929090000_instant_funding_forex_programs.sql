-- Instant Funding current Forex catalog candidates.
-- Captured 2026-09-28 from the official selector and first-party rules pages.
-- Program records remain in_review until full fee/size matrices and selector variants are reconciled.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('Instant Funding', 'instant-funding', 'A simulated Forex trading provider offering instant-access accounts and evaluation challenges.', 'https://instantfunding.com/', 'published', 'forex', now())
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = case when bullish_banana.firms.status = 'published' then 'published' else excluded.status end,
    market_type = 'forex', published_at = coalesce(bullish_banana.firms.published_at, now()),
    archived_at = null, updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'instant-funding'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, supported_assets, profile_details)
select id, array['Forex','Indices','Commodities','Cryptocurrencies']::text[],
  '{"established_year":2021,"established_year_source":"Official homepage says Est. 2021 in the UK.","service_model":"Simulated trading accounts; the official site states accounts use virtual funds and do not represent real trading capital.","legal_entity_note":"Official homepage identifies Acello Ltd (UK company 12696083) as payment agent for IF Pro Ltd, trading as Instant Funding; IF Pro Ltd is identified as a Saint Lucia company (2025-00056). Verify contracting entity and applicable agreement before publication.","platforms_note":"Current public standard selector lists MetaTrader 5, cTrader and Match-Trader; product and currency support may differ.","current_forex_offers_observed":["Instant Funding PRO","IF Micro PRO","One-Phase PRO","Instant Funding Lite","One-Phase Lite"],"availability_note":"IF Micro Lite is explicitly marked Coming Soon. IF1 and Two-Phase appear in rules/help materials but were not visible in the current homepage purchase selector. Evolve is futures-style and excluded from Forex."}'::jsonb
from bullish_banana.firms where slug = 'instant-funding'
on conflict (firm_id) do update
set supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details,
  published_at, archived_at
)
select f.id, x.name, x.slug, x.description, x.program_type, 'forex', 'in_review', 'USD',
       x.account_sizes::jsonb, x.max_leverage, x.split, x.payout, x.days,
       x.news_allowed, x.weekend_allowed, x.details::jsonb, null, null
from bullish_banana.firms f
join (values
  ('Instant Funding PRO', 'instant-funding-pro', 'Immediate-access simulated account; current homepage selector identifies this as the flagship PRO model.', 'instant_funding', '[625,1250,2500,5000,10000,20000,40000,80000,120000]', 100::numeric, 80::numeric, 'Every 14 days, then weekly after a new trade', 0, false, false, '{"availability":"Visible in current official homepage selector as Instant Funding PRO, previously Original.","price_capture":"Current selector sizes captured; full size-specific fees not captured because fee varies by platform, account type and add-ons.","payout_rules":"First withdrawal 14 days after initial trade; then every 7 days after a new trade, per official selector/rules.","profit_target":"None","daily_drawdown":"None shown","maximum_drawdown":"10%","risk_note":"Official rules apply a 3% starting-balance maximum risk per trade idea to Instant Funding accounts.","news_weekend":"Not available by default; selector offers an add-on to enable major-news trading and weekend holding.","source_note":"Official homepage interactive selector and Trading Rules, captured 2026-09-28."}'),
  ('IF Micro PRO', 'if-micro-pro', 'Immediate-access Micro account currently visible in the official PRO selector; exact current terms and pricing require selector-level verification.', 'instant_funding', '[5000,10000,25000,50000,100000]', 100::numeric, 80::numeric, 'On demand', 0, true, true, '{"availability":"Visible in current official homepage selector as IF Micro PRO; homepage describes it as evolved from IF Micro.","price_capture":"Current selector sizes captured; full size-specific fees not captured because fee varies by platform, account type and add-ons.","daily_drawdown":"4%","maximum_drawdown":"6%","news_weekend":"Allowed by default.","profit_split":"80%; add-on offers 10% increase and 20% consistency option.","scaling":"Account grows 25% every 90 days after 10% profit, up to double starting balance.","source_note":"Official homepage interactive selector, captured 2026-09-28."}'),
  ('One-Phase PRO', 'one-phase-pro', 'Single-phase Forex evaluation listed in the current official homepage selector.', 'evaluation', '[10000,25000,50000,100000]', 100::numeric, 80::numeric, 'On demand', 3, false, true, '{"availability":"Visible in current official homepage selector as One-Phase PRO, previously One Phase Original.","price_capture":"Current selector sizes captured; full size-specific fees not captured because fee varies by platform, account type and add-ons.","best_day_rule":"40% of total profit.","scaling":"Account grows 25% every 90 days after 10% profit, up to double starting balance.","profit_split":"80%, can be increased to 90% after 10% profit in 3 months.","news":"Restricted by default; selector offers add-on to allow major-news trading and weekend holding.","source_note":"Official homepage interactive selector, captured 2026-09-28."}'),
  ('Instant Funding Lite', 'instant-funding-lite', 'Immediate-access Lite account with no evaluation and no consistency rule.', 'instant_funding', '[1250,2500,5000,10000,20000,40000,80000]', 100::numeric, 80::numeric, '14 days after first trade, then weekly', 0, false, false, '{"account_size_prices":[{"account_size":1250,"fee":67,"currency":"USD"},{"account_size":2500,"fee":103,"currency":"USD"},{"account_size":5000,"fee":191,"currency":"USD"},{"account_size":10000,"fee":367,"currency":"USD"},{"account_size":20000,"fee":719,"currency":"USD"},{"account_size":40000,"fee":1479,"currency":"USD"},{"account_size":80000,"fee":2959,"currency":"USD"}],"pricing_capture":"Displayed amounts from official USD homepage selector on 2026-09-28. Platform, account type and add-on selections were not fully verified; treat these as observed selector prices pending variant verification.","availability":"Visible in current official Lite selector; previously Instant Funding Go.","profit_target":"None","daily_drawdown":"4%","maximum_drawdown":"10%","payout_rules":"First payout 14 days after first trade, then weekly after a new trade.","profit_split":"80%; selector offers an add-on to increase split by 10%.","minimum_trading_days":0,"news_weekend":"Major-news trading and weekend holding not available by default; selector offers an add-on enabling both.","leverage":"Forex 1:100; commodities and indices 1:20; crypto 1:2.","source_note":"Official homepage interactive selector, captured 2026-09-28."}'),
  ('One-Phase Lite', 'one-phase-lite', 'Single-phase Lite evaluation listed in the current official homepage selector; previously One Phase Clarity.', 'evaluation', '[]', 100::numeric, null::numeric, 'On demand when eligible', 0, null::boolean, null::boolean, '{"availability":"Visible in current official Lite selector as One-Phase Lite, previously One Phase Clarity.","price_capture":"Size and fee matrix not captured; no fee inferred.","source_note":"Official homepage and trading rules, captured 2026-09-28."}')
) as x(name, slug, description, program_type, account_sizes, max_leverage, split, payout, days, news_allowed, weekend_allowed, details) on true
where f.slug = 'instant-funding'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'in_review', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, published_at = null, archived_at = null,
    updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.max_loss,
       x.drawdown_type, x.time_limit_days, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('one-phase-pro', 1, 'Evaluation', 10::numeric, 3::numeric, 8::numeric, 'static', null::integer, 3, '{"best_day_rule":"40% of total profit","source_note":"Official homepage interactive selector and One-Phase Help Center, captured 2026-09-28."}'),
  ('one-phase-lite', 1, 'Evaluation', 7::numeric, 4::numeric, 7::numeric, 'static', null::integer, 0, '{"source_note":"Official trading rules, captured 2026-09-28; verify whether current Lite selector terms retain this Help Center model."}')
) as x(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, time_limit_days, days, rules)
  on x.program_slug = p.slug
where f.slug = 'instant-funding'
on conflict (program_id, phase_number) do update
set name = excluded.name, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent,
    maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules,
    updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('MetaTrader 5', 'metatrader-5'), ('cTrader', 'ctrader'), ('Match-Trader', 'match-trader')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'instant-funding'
cross join bullish_banana.platforms pl
where p.slug in ('instant-funding-pro','if-micro-pro','one-phase-pro','instant-funding-lite','one-phase-lite')
  and pl.slug in ('metatrader-5','ctrader','match-trader')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://instantfunding.com/','Official homepage and interactive program selector','Firm disclosure, simulated-account statement, current product selector, platform/account-type controls, sizes, Lite fees and Lite rules captured 2026-09-28.'),
  ('https://instantfunding.com/trading-rules/','Official Trading Rules','Current and legacy product-specific Forex rules; historical/rules-only products are not assumed purchasable.'),
  ('https://instantfunding.com/help/choose-your-trading-program/','Official Help Center program selector','Cross-check current product families and archived models.'),
  ('https://instantfunding.com/help/one-phase/','One-Phase PRO rules','One-Phase evaluation targets and current payout/rule details; captured 2026-09-28.'),
  ('https://instantfunding.com/help/if-micro/','IF Micro rules','Micro account rule details; current homepage labels IF Micro Lite as coming soon, so distinguish legacy guidance from active variants.'),
  ('https://instantfunding.com/wp-content/uploads/2026/06/Instant-Funding-General-Terms-Conditions.pdf','General Terms and Conditions','Official general terms PDF indexed on Instant Funding; confirm against live footer link and account agreement before publication.')
) as x(url, label, notes) on true
where f.slug = 'instant-funding'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('instant-funding-pro','https://instantfunding.com/','Current PRO selector','Selector visibility verified; current full fee matrix and account-type/platform variants remain to capture.'),
  ('if-micro-pro','https://instantfunding.com/','Current PRO selector','Selector visibility verified; current full fee matrix and current IF Micro PRO rule reconciliation remain open.'),
  ('one-phase-pro','https://instantfunding.com/help/one-phase/','One-Phase PRO rules','Official current rule source; full selector price matrix remains open.'),
  ('instant-funding-lite','https://instantfunding.com/','Current Lite selector','Current sizes and displayed USD fees observed; platform, account type, and add-on selections must be verified before publication.'),
  ('one-phase-lite','https://instantfunding.com/trading-rules/','One-Phase Lite rules','Model is selector-visible; reconcile current Lite selector with Help Center rule details and capture full fee matrix before publication.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'instant-funding'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Instant Funding official homepage, current selector, Trading Rules, Help Center program index and legal disclosures reviewed 2026-09-28. Five current selector-visible Forex models are staged; legal, fee-variant and per-model publication checks remain open.'
from bullish_banana.firms f
where slug = 'instant-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Selector availability observed 2026-09-28. Program remains in review until current rule variant, full sizes/fees, platform/account-type conditions and source coverage are reconciled.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding'
  and p.slug in ('instant-funding-pro','if-micro-pro','one-phase-pro','instant-funding-lite','one-phase-lite')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);
