-- Add BrightFunded and its currently advertised Forex evaluations from first-party sources.
-- Reviewed 2026-09-29. Base EUR prices are captured before time-limited discounts.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'BrightFunded',
  'brightfunded',
  'BrightFunded offers simulated Forex evaluations in 1-Step, 2-Step Bright, and 2-Step Classic formats.',
  'https://brightfunded.com/',
  'published',
  now()
)
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description,
    website_url = excluded.website_url,
    status = 'published',
    published_at = coalesce(bullish_banana.firms.published_at, now()),
    updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'brightfunded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'AE', 'BrightFunded Ltd', array['Forex']::text[],
  '{"founded_year":2023,"brand_owner":"Bright Global FZCO, trading as BrightFunded","headquarters":"Dubai, United Arab Emirates","service_model":"BrightFunded describes all customer accounts as demo accounts with simulated funds.","legal_disclosure":"The product-page footer says CFD simulated trading services are offered solely by BrightFunded Ltd, incorporated in Saint Lucia (company 2025-00358). The Terms preamble more generally identifies Bright Global FZCO as the provider of the Services. Record BrightFunded Ltd for the Forex CFD service based on the product-specific disclosure, and preserve this broader Terms wording as an entity-scope ambiguity. BrightFunded LLC, Wyoming, provides the separate futures service. Bright Transact Ltd, Cyprus, is an affiliate.","jurisdiction_notes":"The product footer says MT5 services are not intended for US or UAE residents/citizens and other restricted countries. The reviewed Terms do not provide a complete firm-wide country list. Help Center also excludes under-18 users, sanctioned persons, people with specified financial-crime/terrorism records, and users previously excluded after an account-agreement breach."}'::jsonb
from bullish_banana.firms where slug = 'brightfunded'
on conflict (firm_id) do update
set country_code = excluded.country_code,
    legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select firms.id, item.name, item.slug, item.description, 'evaluation', 'forex', 'published', 'USD',
  '[5000,10000,25000,50000,100000,200000]'::jsonb,
  null, 80, 'First reward after 30 funded days; 14-day default, weekly/biweekly add-ons; 24h processing', 5,
  true, true, item.commercial_details::jsonb, now()
from bullish_banana.firms
join (values
  ('BrightFunded 1-Step', '1-step', 'Single-phase Forex evaluation with a 10% target, 3% daily loss, 6% trailing maximum loss, five minimum trading days, and no time limit.', '{"fee_refund_policy":"Base one-time prices shown on the official page before temporary discounts: $5,000 €49; $10,000 €97; $25,000 €197; $50,000 €297; $100,000 €497; $200,000 €997. A 100% challenge-fee refund is an optional add-on, not standard. Prices reviewed 2026-09-28; confirm at checkout.","payout_rules":"Up to 90% payout ratio; optional add-ons include weekly payouts. The site advertises 24-hour guaranteed payouts. An evaluation-profit reward of 15% is credited to the first funded account after 10% funded growth and the first payout request.","consistency_rule":"No consistency rules listed in the official comparison table.","prohibited_strategies":"The official help page allows evaluation news trading; on funded accounts, significant-news restrictions apply five minutes before and after the event, subject to stated exceptions. Platform availability varies by residence; MT5 and cTrader are unavailable to US/UAE residents or citizens and restricted regions.","commission_details":"Not stated on the reviewed official pages."}'),
  ('BrightFunded 2-Step Bright', '2-step-bright', 'Two-phase Forex evaluation with 8% then 5% targets, 4% daily loss, 8% static maximum loss, five minimum trading days per phase, and no time limit.', '{"fee_refund_policy":"Base one-time prices shown on the official page before temporary discounts: $5,000 €47; $10,000 €87; $25,000 €187; $50,000 €277; $100,000 €477; $200,000 €947. A 100% challenge-fee refund is an optional add-on, not standard. Prices reviewed 2026-09-28; confirm at checkout.","payout_rules":"Up to 90% payout ratio; optional add-ons include weekly payouts. The site advertises 24-hour guaranteed payouts. An evaluation-profit reward of 15% is credited to the first funded account after 10% funded growth and the first payout request.","consistency_rule":"No consistency rules listed in the official comparison table.","prohibited_strategies":"The official help page allows evaluation news trading; on funded accounts, significant-news restrictions apply five minutes before and after the event, subject to stated exceptions. Platform availability varies by residence; MT5 and cTrader are unavailable to US/UAE residents or citizens and restricted regions.","commission_details":"Not stated on the reviewed official pages."}'),
  ('BrightFunded 2-Step Classic', '2-step-classic', 'Two-phase Forex evaluation with 10% then 5% targets, 5% daily loss, 10% static maximum loss, five minimum trading days per phase, and no time limit.', '{"fee_refund_policy":"Base one-time prices shown on the official page before temporary discounts: $5,000 €49; $10,000 €97; $25,000 €197; $50,000 €297; $100,000 €497; $200,000 €997. A 100% challenge-fee refund is an optional add-on, not standard. Prices reviewed 2026-09-28; confirm at checkout.","payout_rules":"Up to 90% payout ratio; optional add-ons include weekly payouts. The site advertises 24-hour guaranteed payouts. An evaluation-profit reward of 15% is credited to the first funded account after 10% funded growth and the first payout request.","consistency_rule":"No consistency rules listed in the official comparison table.","prohibited_strategies":"The official help page allows evaluation news trading; on funded accounts, significant-news restrictions apply five minutes before and after the event, subject to stated exceptions. Platform availability varies by residence; MT5 and cTrader are unavailable to US/UAE residents or citizens and restricted regions.","commission_details":"Not stated on the reviewed official pages."}')
) as item(name, slug, description, commercial_details) on true
where firms.slug = 'brightfunded'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'published', currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = coalesce(bullish_banana.programs.published_at, now()), updated_at = now();

-- Keep the per-size price schedule machine-readable for listings and comparisons.
update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
  'account_size_prices', '[{"account_size":5000,"fee":49,"currency":"EUR"},{"account_size":10000,"fee":97,"currency":"EUR"},{"account_size":25000,"fee":197,"currency":"EUR"},{"account_size":50000,"fee":297,"currency":"EUR"},{"account_size":100000,"fee":497,"currency":"EUR"},{"account_size":200000,"fee":997,"currency":"EUR"}]'::jsonb
), updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'brightfunded')
  and slug in ('1-step', '2-step-classic');

update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
  'account_size_prices', '[{"account_size":5000,"fee":47,"currency":"EUR"},{"account_size":10000,"fee":87,"currency":"EUR"},{"account_size":25000,"fee":187,"currency":"EUR"},{"account_size":50000,"fee":277,"currency":"EUR"},{"account_size":100000,"fee":477,"currency":"EUR"},{"account_size":200000,"fee":947,"currency":"EUR"}]'::jsonb
), updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'brightfunded')
  and slug = '2-step-bright';

-- Preserve current payout/refund semantics separately from the fee add-on and processing-time copy.
update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
  'fee_refund_policy', 'The comparison lists a 100% challenge-fee refund as an optional checkout add-on; its price and detailed eligibility are not stated in the reviewed pages. Separately, the Help Center says an unused account purchased within 30 days is eligible for a refund. These are distinct conditions.',
  'payout_rules', 'Help Center states the first reward split may be requested 30 days after the first funded trade; later requests are every 14 days by default, with weekly or biweekly add-ons. Profit split is 80% by default, 90% with an add-on, or can scale to 100%. The public comparison advertises processing within 24 hours; that is processing time, not payout eligibility.',
  'evaluation_reward', 'A 15% bonus of evaluation-phase profits is credited to a funded account after at least 10% funded growth and a payout request. The Help Center explicitly describes Phase 1 plus Phase 2 profits for two-step evaluations; the product page advertises the feature for 1-Step but does not restate the calculation scope.',
  'consistency_rule', 'Current comparison table says no consistency rule.',
  'verified_current_date', '2026-09-29',
  'data_review_status', 'Source-verified 2026-09-29. Optional add-on prices are not stated; platform availability varies by residence. The exact contracting-party scope in general Terms versus the CFD-specific product disclosure is preserved in the firm profile.'
), updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'brightfunded')
  and slug in ('1-step', '2-step-bright', '2-step-classic');

insert into bullish_banana.program_phases (
  program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss,
  phase.max_loss, phase.drawdown_type, null, 5, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'brightfunded'
join (values
  ('1-step', 1, 'Evaluation', 10.000::numeric, 3.000::numeric, 6.000::numeric, 'trailing', '{"source_note":"Official BrightFunded 1-Step help and comparison pages state a 10% target, 3% daily drawdown, 6% trailing maximum drawdown, five minimum trading days, and no time limit."}'),
  ('2-step-bright', 1, 'Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', '{"source_note":"Official BrightFunded current rules state an 8% first-phase target, 4% daily drawdown, 8% static maximum drawdown, five minimum trading days, and no time limit."}'),
  ('2-step-bright', 2, 'Phase 2', 5.000::numeric, 4.000::numeric, 8.000::numeric, 'static', '{"source_note":"Official BrightFunded current rules state a 5% second-phase target with the same 4% daily and 8% static maximum drawdown, five minimum trading days, and no time limit."}'),
  ('2-step-classic', 1, 'Phase 1', 10.000::numeric, 5.000::numeric, 10.000::numeric, 'static', '{"source_note":"Official BrightFunded current rules state a 10% first-phase target, 5% daily drawdown, 10% static maximum drawdown, five minimum trading days, and no time limit."}'),
  ('2-step-classic', 2, 'Phase 2', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', '{"source_note":"Official BrightFunded current rules state a 5% second-phase target with the same 5% daily and 10% static maximum drawdown, five minimum trading days, and no time limit."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

update bullish_banana.program_phases
set raw_rules = raw_rules || jsonb_build_object(
  'day_requirement_label', '5 trading days; a trade must remain open for at least 60 seconds; profit or loss counts'
), updated_at = now()
where program_id in (
  select id from bullish_banana.programs
  where firm_id = (select id from bullish_banana.firms where slug = 'brightfunded')
    and slug in ('1-step', '2-step-bright', '2-step-classic')
);

insert into bullish_banana.platforms (name, slug) values
  ('DXtrade', 'dxtrade'), ('cTrader', 'ctrader'), ('MetaTrader 5', 'metatrader-5')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'brightfunded'
cross join bullish_banana.platforms
where programs.slug in ('1-step', '2-step-bright', '2-step-classic')
  and platforms.slug in ('dxtrade', 'ctrader', 'metatrader-5')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://brightfunded.com/about-us', 'BrightFunded company history', 'First-party company history reviewed 2026-09-29; identifies the 2023 launch and Dubai headquarters. Current Terms and Contact pages are used for contracting entity and affiliated-company roles.'
from bullish_banana.firms where firms.slug = 'brightfunded'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://brightfunded.com/about-us');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms firms
join (values
  ('https://brightfunded.com/terms-and-conditions', 'BrightFunded Terms and Conditions', 'Reviewed 2026-09-29. General Terms preamble names Bright Global FZCO as provider of the Services. Product footer names BrightFunded Ltd as sole provider of CFD simulated trading; record the scope ambiguity rather than collapsing the disclosures.'),
  ('https://brightfunded.com/contact-us', 'BrightFunded legal entities and service model', 'Reviewed 2026-09-29. Contact page identifies Bright Global FZCO (Dubai), BrightFunded Ltd (Saint Lucia) and BrightFunded LLC (Wyoming) as distinct entities, and confirms simulated accounts.'),
  ('https://brightfunded.com/comparison-table', 'Current BrightFunded comparison table', 'Reviewed 2026-09-29. Confirms current 1-Step, 2-Step Bright and 2-Step Classic offers, account sizes, targets, losses, five minimum days, no consistency rule, 24-hour processing claim and optional add-ons. Current DOUBLE25 discount excluded from base prices.'),
  ('https://help.brightfunded.com/en/articles/9241590-how-do-i-get-funded', 'BrightFunded evaluation and eligibility rules', 'Current Help Center article dated 2026-04-13 reviewed 2026-09-29; confirms evaluation phases/rules, five days, no time limit, 15% evaluation-profit reward conditions, age and eligibility restrictions.'),
  ('https://help.brightfunded.com/en/articles/9241600-how-long-does-the-evaluation-process-take', 'BrightFunded trading-day definition', 'Current Help Center article reviewed 2026-09-29; a qualifying day requires at least one trade open for at least 60 seconds; it counts whether the trade wins or loses.'),
  ('https://help.brightfunded.com/en/articles/9268736-how-does-my-reward-split-work-on-my-funded-account', 'BrightFunded reward split and payout schedule', 'Current Help Center article dated 2026-03-18 reviewed 2026-09-29; first request after 30 days from first funded trade; later requests every 14 days by default, with weekly/biweekly add-ons; default 80%, 90% add-on, and scaling to 100%.'),
  ('https://help.brightfunded.com/en/articles/9460023-can-i-get-a-refund-for-my-brightfunded-challenge', 'BrightFunded purchase refund conditions', 'Current Help Center refund article reviewed 2026-09-29; an unused account may be refunded when purchased within 30 days. Distinct from the optional 100% challenge-fee refund add-on.'),
  ('https://help.brightfunded.com/en/articles/10855521-what-trading-platform-does-brightfunded-offer', 'BrightFunded platform and location conditions', 'Current Help Center platform page; MT5 and cTrader have residence/citizenship restrictions. Platform availability must be confirmed by the actual selected account and user location.'),
  ('https://help.brightfunded.com/en/articles/9241694-can-i-trade-news', 'BrightFunded news rules', 'Current Help Center distinguishes evaluation news trading from funded high-impact-news restrictions and exceptions; reviewed 2026-09-29.')
) as source(url, label, notes) on true
where firms.slug = 'brightfunded'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'brightfunded'
join (values
  ('1-step', 'https://brightfunded.com/1-step', 'BrightFunded 1-Step', 'First-party page and all six account-size price points reviewed in the public selector 2026-09-29. Base fees are EUR 49/97/197/297/497/997 for $5K/$10K/$25K/$50K/$100K/$200K. Active 30% 3YEARS offer is excluded from base prices. Page states 10% target, 3% daily loss, 6% trailing max loss, five days, unlimited period, payout ratio, evaluation reward, add-ons and news treatment.'),
  ('2-step-bright', 'https://brightfunded.com/2-step-bright', 'BrightFunded 2-Step Bright', 'First-party page and all six account-size price points reviewed in the public selector 2026-09-29. Base fees are EUR 47/87/187/277/477/947 for $5K/$10K/$25K/$50K/$100K/$200K. Active 30% 3YEARS offer is excluded from base prices. Page states 8%/5% targets, 4% daily loss, 8% static max loss, five days per phase, unlimited period, payout ratio, evaluation reward, add-ons and news treatment.'),
  ('2-step-classic', 'https://brightfunded.com/2-step-classic', 'BrightFunded 2-Step Classic', 'First-party page and all six account-size price points reviewed in the public selector 2026-09-29. Base fees are EUR 49/97/197/297/497/997 for $5K/$10K/$25K/$50K/$100K/$200K. Active 30% 3YEARS offer is excluded from base prices. Page states 10%/5% targets, 5% daily loss, 10% static max loss, five days per phase, unlimited period, payout ratio, evaluation reward, add-ons and news treatment.'),
  ('1-step', 'https://brightfunded.com/comparison-table', 'BrightFunded challenge comparison', 'First-party table compares all current challenge models, account sizes, evaluation reward, targets, risk limits, minimum days, payout ratio, news restrictions, payout timing, consistency rules, and time limits.'),
  ('1-step', 'https://help.brightfunded.com/en/articles/10855521-what-trading-platform-does-brightfunded-offer', 'BrightFunded supported platforms', 'First-party help page lists DXtrade, cTrader, and MT5 and documents location-based platform restrictions for MT5 and cTrader.'),
  ('2-step-bright', 'https://help.brightfunded.com/en/articles/10855521-what-trading-platform-does-brightfunded-offer', 'BrightFunded supported platforms', 'First-party help page lists DXtrade, cTrader, and MT5 and documents location-based platform restrictions for MT5 and cTrader.'),
  ('2-step-classic', 'https://help.brightfunded.com/en/articles/10855521-what-trading-platform-does-brightfunded-offer', 'BrightFunded supported platforms', 'First-party help page lists DXtrade, cTrader, and MT5 and documents location-based platform restrictions for MT5 and cTrader.'),
  ('1-step', 'https://help.brightfunded.com/en/articles/9241694-can-i-trade-news', 'BrightFunded news trading rules', 'First-party help page distinguishes evaluation news trading from funded-account significant-news restrictions and exceptions.'),
  ('2-step-bright', 'https://help.brightfunded.com/en/articles/9241694-can-i-trade-news', 'BrightFunded news trading rules', 'First-party help page distinguishes evaluation news trading from funded-account significant-news restrictions and exceptions.'),
  ('2-step-classic', 'https://help.brightfunded.com/en/articles/9241694-can-i-trade-news', 'BrightFunded news trading rules', 'First-party help page distinguishes evaluation news trading from funded-account significant-news restrictions and exceptions.'),
  ('1-step', 'https://help.brightfunded.com/en/articles/9268323-is-it-allowed-to-hold-positions-over-the-weekend', 'BrightFunded weekend holding rules', 'First-party help page says weekend holding is permitted and describes the optional swap-free add-on.'),
  ('2-step-bright', 'https://help.brightfunded.com/en/articles/9268323-is-it-allowed-to-hold-positions-over-the-weekend', 'BrightFunded weekend holding rules', 'First-party help page says weekend holding is permitted and describes the optional swap-free add-on.'),
  ('2-step-classic', 'https://help.brightfunded.com/en/articles/9268323-is-it-allowed-to-hold-positions-over-the-weekend', 'BrightFunded weekend holding rules', 'First-party help page says weekend holding is permitted and describes the optional swap-free add-on.'),
  ('1-step', 'https://help.brightfunded.com/en/articles/9241600-how-long-does-the-evaluation-process-take', 'BrightFunded evaluation duration', 'First-party help page states unlimited evaluation time, five minimum trading days for 1-Step and each 2-Step phase, and defines a counted trading day.')
) as source(program_slug, url, label, notes) on true
where programs.slug = source.program_slug
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'brightfunded'
join (values
  ('https://brightfunded.com/comparison-table', 'Current challenge terms and add-ons', 'First-party comparison reviewed 2026-09-29. Current table lists account sizes, targets, drawdown, minimum trading days, no consistency rules, payouts processed within 24 hours and challenge add-ons. DOUBLE25 promotion is time-sensitive and excluded from base prices.'),
  ('https://help.brightfunded.com/en/articles/9268736-how-does-my-reward-split-work-on-my-funded-account', 'Funded payout eligibility and reward split', 'First-party Help Center article: first request 30 days after first funded trade; subsequent default every 14 days; weekly and biweekly add-ons; 80% default split, 90% add-on, scale-up to 100%.'),
  ('https://help.brightfunded.com/en/articles/9460023-can-i-get-a-refund-for-my-brightfunded-challenge', 'Refund rules', 'First-party Help Center article states refunds can be requested for unused accounts purchased within the preceding 30 days. Separate this from the optional 100% challenge-fee refund add-on.'),
  ('https://help.brightfunded.com/en/articles/9241600-how-long-does-the-evaluation-process-take', 'Evaluation duration and trading-day definition', 'First-party Help Center states there is no evaluation time limit, five minimum trading days per phase, and a day counts after a trade remains open for at least 60 seconds regardless of profit or loss.'),
  ('https://brightfunded.com/terms-and-conditions', 'Current service terms', 'Current official Terms name Bright Global FZCO as service provider and describe simulated demo accounts; full eligibility terms remain subject to the official Terms.')
) as source(url, label, notes) on true
where programs.slug in ('1-step', '2-step-bright', '2-step-classic')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed BrightFunded current Terms, Contact/company pages, all three public product pages and price matrices, comparison table, and Help Center on 2026-09-29. CFD-specific product footer names BrightFunded Ltd while general Terms preamble names Bright Global FZCO; both scopes and the ambiguity are recorded. PropFirmMatch was used only to identify the candidate.'
from bullish_banana.firms where slug = 'brightfunded';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed current BrightFunded product page, all six static base prices, comparison table and Help Center sources on 2026-09-29. Published facts are sourced; optional add-on prices are not stated and platform availability is residence dependent. Active promotions are excluded from base fees.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'brightfunded'
where programs.slug in ('1-step', '2-step-bright', '2-step-classic');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit ' || programs.name, source.url, true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id and programs.slug in ('1-step', '2-step-bright', '2-step-classic')
join (values
  ('1-step', 'https://brightfunded.com/1-step'),
  ('2-step-bright', 'https://brightfunded.com/2-step-bright'),
  ('2-step-classic', 'https://brightfunded.com/2-step-classic')
) as source(program_slug, url) on source.program_slug = programs.slug
where firms.slug = 'brightfunded'
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
