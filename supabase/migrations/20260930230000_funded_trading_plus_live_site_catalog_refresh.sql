-- Funded Trading Plus live first-party site and pricing refresh, captured 2026-09-30.
-- This updates four currently marketed Forex offers. Staged only; do not apply without the catalog release window.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set description = 'Simulated Forex trading evaluations and direct simulated-funded accounts with performance-based rewards.',
    website_url = 'https://www.fundedtradingplus.com/',
    status = 'published', published_at = coalesce(published_at, now()), archived_at = null, updated_at = now()
where slug = 'funded-trading-plus';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
  'service_model', 'All offers use simulated trading environments; the provider states that no real market orders are executed and rewards are paid from firm funds.',
  'operating_entity', 'Acello Ltd (England and Wales company 12696083) owns and operates fundedtradingplus.com and the trading services.',
  'service_entity', 'IF Pro Ltd (Saint Lucia company 2025-00056) provides the simulated trading programs. Acello Ltd is identified as its payment agent.',
  'registered_office', 'Acello Ltd, 30 Old Bailey, London, EC4M 7AU.',
  'current_offer_capture', '2026-09-30',
  'current_forex_offers', jsonb_build_array('Instant Funding','1-Step Express','2-Step Classic','Pass Now Pay Later'),
  'platforms_observed', jsonb_build_object('country','JP','platforms',jsonb_build_array('Match Trade','MetaTrader 5'),'note','The provider page labels this as availability in the visitor current location. Do not generalize the JP selection to all regions.'),
  'platform_availability_note', 'Official pages showed Match Trade and MetaTrader 5 for the current Japan (JP) location. The site states MetaTrader 5 is unavailable via IF Pro Ltd in the United States. No complete platform-by-country matrix was found.',
  'jurisdiction_note', 'The website lists the jurisdictions recorded in the firm restrictions table as unsupported. It also says other jurisdictions may be assessed individually. Crimea is named separately in the official list.',
  'promo_capture', 'The site displayed code FUNDED30 for 30% off the Instant, 1-Step Express and 2-Step Classic pages. Expiry was not stated in the captured pages. Do not treat this code as a permanent price or assume it applies to Pass Now Pay Later.'
), updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'funded-trading-plus';

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select f.id, x.country_code, 'restricted', 'Funded Trading Plus official website sanctions, AML & CFT disclosure lists this jurisdiction as unsupported; captured 2026-09-30.'
from bullish_banana.firms f
cross join (values
  ('AF'),('BY'),('BI'),('CF'),('TD'),('CG'),('CD'),('CU'),('ER'),('GN'),('GW'),('HT'),('IR'),('LY'),('LR'),('MM'),('NI'),('KP'),('PG'),('RU'),('SO'),('SS'),('SD'),('SY'),('VU'),('VE'),('VN'),('YE'),('ZW')
) as x(country_code)
where f.slug = 'funded-trading-plus'
on conflict (firm_id, country_code) do update
set restriction_type = excluded.restriction_type, note = excluded.note, updated_at = now();

-- Current site displays platforms for the visitor's location (JP), not a universal mapping.
-- Remove the old unscoped rows and retain the sourced region-specific note on each offer.
delete from bullish_banana.program_platforms pp
using bullish_banana.programs p, bullish_banana.firms f
where pp.program_id = p.id and p.firm_id = f.id and f.slug = 'funded-trading-plus'
  and p.slug in ('one-step-express','two-step-classic','instant-program','pass-now-pay-later');

update bullish_banana.programs p
set status = 'published', market_type = 'forex', currency = 'USD',
    account_sizes = detail.account_sizes::jsonb,
    profit_split_percent = detail.split, payout_frequency = detail.payout_frequency,
    minimum_trading_days = 0, max_leverage = detail.leverage,
    news_allowed = true, weekend_holding_allowed = detail.weekend_allowed,
    description = detail.description,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || detail.commercial_details::jsonb,
    published_at = coalesce(p.published_at, now()), archived_at = null, updated_at = now()
from (values
  ('one-step-express',
   'One-step Forex evaluation with a 10% target, 4% balance-based daily loss limit and 6% relative trailing maximum loss.',
   '[{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]',
   80::numeric, 'First eligible request from Day 0; then every 7 days', 30::numeric, true,
   '{"account_size_prices":[{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":349,"currency":"USD"},{"account_size":100000,"fee":549,"currency":"USD"},{"account_size":200000,"fee":999,"currency":"USD"}],"pricing_capture":"Official 1-Step Express size selector captured 2026-09-30. Standard one-time USD fees; prices include VAT. FUNDED30 discounted prices were shown separately and are not baked into this base schedule.","price_configuration":"One evaluation step. No evaluation deadline; one completed trade is required during each 30-day period to keep an evaluation or simulated-live account active. Standard reward split is 80%; official page offers optional 90% split (+15%), 3-day reward frequency (+15%), and scaling to $5M (+15%). Reset/restart terms are subject to the current provider rules.","payout_rules":"80% standard reward split. First eligible request from Day 0 with a $50 minimum; then requests every 7 days. Scaling and reward add-ons are optional.","platforms_note":"Official product page showed Match Trade and MetaTrader 5 for its detected Japan (JP) location on 2026-09-30. Provider states platform availability depends on location; MT5 is unavailable via IF Pro Ltd in the United States. Not a global platform list.","promotion_note":"The official page displayed code FUNDED30 for 30% off at capture. Expiration was not stated. Base fee table does not assume the code is applied."}'),
  ('two-step-classic',
   'Two-step Forex evaluation with 7% targets per phase, 4% balance-based daily loss and 8% static maximum loss.',
   '[{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]',
   80::numeric, 'Every 10 calendar days', 50::numeric, true,
   '{"account_size_prices":[{"account_size":10000,"fee":89,"currency":"USD"},{"account_size":25000,"fee":169,"currency":"USD"},{"account_size":50000,"fee":319,"currency":"USD"},{"account_size":100000,"fee":549,"currency":"USD"}],"pricing_capture":"Official 2-Step Classic size selector captured 2026-09-30. Standard one-time USD fees; prices include VAT. FUNDED30 discounted prices were shown separately and are not baked into this base schedule.","price_configuration":"Both phases target 7%; daily loss is 4%, maximum loss is 8% static. Consistency is 35% during evaluation and 50% on the simulated-live account. Symbol loss limit is 3%. No evaluation deadline; one completed trade is required during each 30-day period. Swap-free by default.","payout_rules":"80% standard reward split. Requests are available every 10 calendar days; minimum request is 1% of initial account balance.","platforms_note":"Official product page showed Match Trade and MetaTrader 5 for its detected Japan (JP) location on 2026-09-30. Provider states platform availability depends on location; MT5 is unavailable via IF Pro Ltd in the United States. Not a global platform list.","promotion_note":"The official page displayed code FUNDED30 for 30% off at capture. Expiration was not stated. Base fee table does not assume the code is applied."}'),
  ('instant-program',
   'Direct Forex simulated-funded account with no evaluation, a 6% daily loss limit and 6% relative trailing maximum loss.',
   '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]',
   80::numeric, 'First eligible request from Day 0; then every 7 days', 30::numeric, false,
   '{"account_size_prices":[{"account_size":5000,"fee":249,"currency":"USD"},{"account_size":10000,"fee":429,"currency":"USD"},{"account_size":25000,"fee":1099,"currency":"USD"},{"account_size":50000,"fee":2199,"currency":"USD"},{"account_size":100000,"fee":4499,"currency":"USD"}],"pricing_capture":"Official Instant Funding size selector captured 2026-09-30. Standard one-time USD fees; prices include VAT. FUNDED30 discounted prices were shown separately and are not baked into this base schedule.","price_configuration":"No evaluation. Six percent relative trailing maximum loss and 6% balance/equity-based daily loss. A completed trade is required during each 30-day period to keep the account active. Swap-free by default.","payout_rules":"80% standard reward split. Minimum request $50, first eligible from Day 0, then every 7 days.","weekend_rule":"All open trades must be closed by 16:30 US Eastern Friday. New trades may be opened again after the market reopens.","platforms_note":"Official product page showed Match Trade and MetaTrader 5 for its detected Japan (JP) location on 2026-09-30. Provider states platform availability depends on location; MT5 is unavailable via IF Pro Ltd in the United States. Not a global platform list.","promotion_note":"The official page displayed code FUNDED30 for 30% off at capture. Expiration was not stated. Base fee table does not assume the code is applied."}'),
  ('pass-now-pay-later',
   'Pass Now Pay Later Forex evaluation: pay $4 to begin Step 1 and the size-based remaining fee after passing.',
   '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]',
   80::numeric, 'Every 10 trading days after funding', 30::numeric, true,
   '{"account_size_prices":[{"account_size":25000,"fee":4,"post_pass_fee":179,"currency":"USD"},{"account_size":50000,"fee":4,"post_pass_fee":299,"currency":"USD"},{"account_size":100000,"fee":4,"post_pass_fee":489,"currency":"USD"}],"pricing_capture":"Official Pass Now Pay Later size selector captured 2026-09-30. USD; prices include VAT. The $4 is due to activate Step 1; the remaining size-based fee is due after passing Step 1 and before the funded stage.","price_configuration":"One evaluation step with a 2% target, 4% balance-based daily loss, and 6% static maximum loss. No evaluation time limit, maximum trading days, or consistency rule on Step 1. No add-ons were offered in the captured page. After passing, the remaining fee is due before receiving the funded account.","payout_rules":"After funding: 80% standard reward split; requests every 10 trading days. A 25% consistency rule is checked at payout.","funded_rules":"After funding: no profit target, 3% balance-based daily loss, 6% trailing maximum loss that locks at starting balance, and 25% payout consistency check.","platforms_note":"Official product page showed Match Trade and MetaTrader 5 for its detected Japan (JP) location on 2026-09-30. Provider states platform availability depends on location; MT5 is unavailable via IF Pro Ltd in the United States. Not a global platform list.","promotion_note":"The site-wide FUNDED30 banner was visible, but the Pass Now Pay Later page showed no discounted due-now or post-pass price. No promotional discount is applied to this offer in the catalog."}')
) as detail(program_slug, description, account_sizes, split, payout_frequency, leverage, weekend_allowed, commercial_details)
where p.slug = detail.program_slug
  and exists (select 1 from bullish_banana.firms f where f.id = p.firm_id and f.slug = 'funded-trading-plus');

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, profit_split_percent, payout_frequency, minimum_trading_days,
  max_leverage, news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select f.id, 'Pass Now Pay Later', 'pass-now-pay-later',
       'Forex evaluation with a $4 Step 1 activation fee and remaining account-size fee due after passing.',
       'evaluation', 'forex', 'published', 'USD',
       '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]'::jsonb,
       80, 'Every 10 trading days after funding', 0, 30, true, true,
       '{"account_size_prices":[{"account_size":25000,"fee":4,"post_pass_fee":179,"currency":"USD"},{"account_size":50000,"fee":4,"post_pass_fee":299,"currency":"USD"},{"account_size":100000,"fee":4,"post_pass_fee":489,"currency":"USD"}],"pricing_capture":"Official Pass Now Pay Later size selector captured 2026-09-30. USD; prices include VAT. The $4 is due to activate Step 1; the remaining size-based fee is due after passing Step 1 and before the funded stage.","price_configuration":"One evaluation step with a 2% target, 4% balance-based daily loss, and 6% static maximum loss. No evaluation time limit, maximum trading days, or consistency rule on Step 1. No add-ons were offered in the captured page.","payout_rules":"After funding: 80% standard reward split; requests every 10 trading days. A 25% consistency rule is checked at payout.","funded_rules":"After funding: no profit target, 3% balance-based daily loss, 6% trailing maximum loss that locks at starting balance, and 25% payout consistency check.","platforms_note":"Official product page showed Match Trade and MetaTrader 5 for its detected Japan (JP) location on 2026-09-30. Provider states platform availability depends on location; MT5 is unavailable via IF Pro Ltd in the United States. Not a global platform list.","promotion_note":"The site-wide FUNDED30 banner was visible, but this page showed no discounted due-now or post-pass price. No promotional discount is applied to this offer in the catalog."}'::jsonb,
       now()
from bullish_banana.firms f
where f.slug = 'funded-trading-plus'
on conflict (firm_id, slug) do update set
  name = excluded.name, description = excluded.description,
  program_type = excluded.program_type, market_type = excluded.market_type,
  status = excluded.status, currency = excluded.currency,
  account_sizes = excluded.account_sizes, profit_split_percent = excluded.profit_split_percent,
  payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
  max_leverage = excluded.max_leverage, news_allowed = excluded.news_allowed,
  weekend_holding_allowed = excluded.weekend_holding_allowed,
  commercial_details = coalesce(bullish_banana.programs.commercial_details, '{}'::jsonb) || excluded.commercial_details,
  published_at = coalesce(bullish_banana.programs.published_at, now()), archived_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.max_loss, x.drawdown_type, 0, x.raw_rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('one-step-express',1,'1-Step Express Evaluation',10::numeric,4::numeric,6::numeric,'relative_trailing','{"time_limit":"Unlimited evaluation period","account_activity":"One completed trade in every 30-day period","news_trading":"Allowed subject to policy"}'),
  ('two-step-classic',1,'2-Step Classic Phase 1',7::numeric,4::numeric,8::numeric,'static','{"maximum_loss_basis":"Balance based","consistency_rule_percent":35,"symbol_loss_limit_percent":3,"time_limit":"Unlimited evaluation period","account_activity":"One completed trade in every 30-day period"}'),
  ('two-step-classic',2,'2-Step Classic Phase 2',7::numeric,4::numeric,8::numeric,'static','{"maximum_loss_basis":"Balance based","consistency_rule_percent":35,"symbol_loss_limit_percent":3,"time_limit":"Unlimited evaluation period","account_activity":"One completed trade in every 30-day period"}'),
  ('instant-program',1,'Instant Simulated-Funded Phase',null::numeric,6::numeric,6::numeric,'relative_trailing','{"evaluation":"None","account_activity":"One completed trade in every 30-day period","maximum_loss_basis":"Balance based high-water mark, locks at initial balance"}'),
  ('pass-now-pay-later',1,'Pass Now Pay Later Step 1',2::numeric,4::numeric,6::numeric,'static','{"maximum_loss_basis":"Balance based","time_limit":"Unlimited","maximum_trading_days":"None","consistency_rule":"None","remaining_fee_due":"After passing Step 1 and before funded-stage access"}')
) as x(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, raw_rules)
  on x.program_slug = p.slug
where f.slug = 'funded-trading-plus'
on conflict (program_id, phase_number) do update set
  name = excluded.name, profit_target_percent = excluded.profit_target_percent,
  daily_drawdown_percent = excluded.daily_drawdown_percent,
  maximum_drawdown_percent = excluded.maximum_drawdown_percent,
  drawdown_type = excluded.drawdown_type, minimum_trading_days = excluded.minimum_trading_days,
  raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, s.url, s.label, s.notes
from bullish_banana.firms f
cross join (values
  ('https://www.fundedtradingplus.com/','Funded Trading Plus official website','Current site identifies Acello Ltd as website/service operator, IF Pro Ltd as simulated-program provider, describes simulated accounts, states geographic exclusions, and advertises current offers and FUNDED30 promotion; reviewed 2026-09-30.'),
  ('https://www.fundedtradingplus.com/prop-trading-challenges/compare-challenges','Funded Trading Plus challenge comparison','Current first-party comparison lists Instant Funding, 1-Step Express, 2-Step Classic, and Pass Now Pay Later, confirming the four currently marketed challenge paths; reviewed 2026-09-30.'),
  ('https://www.fundedtradingplus.com/terms-conditions/','Funded Trading Plus Terms & Conditions','Official terms page linked from the current website; review jurisdiction-specific details at publication.'),
  ('https://www.fundedtradingplus.com/disclaimers/','Funded Trading Plus disclaimers and jurisdiction policy','Official site explains simulated services, company roles, geographic exclusions, and MetaTrader 5 unavailability via IF Pro Ltd in the United States; reviewed 2026-09-30.')
) as s(url,label,notes)
where f.slug = 'funded-trading-plus'
  and not exists (select 1 from bullish_banana.sources old where old.firm_id = f.id and old.source_url = s.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.url, s.label, s.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('one-step-express','https://www.fundedtradingplus.com/prop-trading-challenges/one-step','1-Step Express live price and offer details','Current official size selector, standard USD fee and separately displayed FUNDED30 price; 10% target, 4% daily loss, 6% trailing loss, 1:30 Forex leverage, news/weekend terms, platform options for detected JP location, payout cycle and add-ons; reviewed 2026-09-30.'),
  ('two-step-classic','https://www.fundedtradingplus.com/prop-trading-challenges/two-step','2-Step Classic live price and offer details','Current official size selector, standard USD fee and separately displayed FUNDED30 price; phase targets, loss limits, consistency, symbol limit, 1:50 leverage, news/weekend terms, region-specific platforms and payout cycle; reviewed 2026-09-30.'),
  ('instant-program','https://www.fundedtradingplus.com/prop-trading-challenges/instant-funding','Instant Funding live price and offer details','Current official size selector, standard USD fee and separately displayed FUNDED30 price; no evaluation, loss limits, 1:30 leverage, news rules, Friday close requirement, payout cycle and region-specific platforms; reviewed 2026-09-30.'),
  ('pass-now-pay-later','https://www.fundedtradingplus.com/prop-trading-challenges/pnpl','Pass Now Pay Later live offer and deferred fee details','Official page says $4 starts Step 1, with the size-based remaining fee due after passing; captured $25K/$50K/$100K fees, Step 1 and funded rules, no add-ons, news/weekend terms and region-specific platforms on 2026-09-30.')
) as s(program_slug,url,label,notes) on s.program_slug = p.slug
where f.slug = 'funded-trading-plus'
  and not exists (select 1 from bullish_banana.sources old where old.program_id = p.id and old.source_url = s.url);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at Funded Trading Plus', s.url, true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
join (values
  ('one-step-express','https://www.fundedtradingplus.com/prop-trading-challenges/one-step'),
  ('two-step-classic','https://www.fundedtradingplus.com/prop-trading-challenges/two-step'),
  ('instant-program','https://www.fundedtradingplus.com/prop-trading-challenges/instant-funding'),
  ('pass-now-pay-later','https://www.fundedtradingplus.com/prop-trading-challenges/pnpl')
) as s(program_slug,url) on s.program_slug = p.slug
where f.slug = 'funded-trading-plus'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(), 'Rechecked the current Funded Trading Plus website and official product pages on 2026-09-30. It directly documents four Forex paths, account-size fees, the deferred PNPL balance, current Japan platform choices, provider/payment-agent entity roles, simulated-service model, and named geographic exclusions. Region-wide platform variations are recorded with scope caveats.'
from bullish_banana.firms f where f.slug = 'funded-trading-plus';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Current first-party product page and size selector reviewed on 2026-09-30. Base fees are recorded separately from FUNDED30 discounts. Platform choices are scoped to the detected JP location; region-wide mapping is not inferred.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'funded-trading-plus'
  and p.slug in ('one-step-express','two-step-classic','instant-program','pass-now-pay-later');
