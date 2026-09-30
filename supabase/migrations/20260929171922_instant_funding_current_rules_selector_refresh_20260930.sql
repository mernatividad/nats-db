-- Instant Funding selector and current One-Phase Lite rule refresh.
-- Official selector and current terms were rechecked 2026-09-30. Data only;
-- no live migration application is intended by this file creation.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "legal_entity_note":"The current homepage corporate disclosure identifies IF Pro Ltd (Saint Lucia company 2025-00056) as the Instant Funding operator and Acello Ltd (UK company 12696083) as its payment agent. The current General Terms PDF instead names Acello Ltd as the contracting party and states its agreement prevails over general terms. Preserve this conflict and confirm the applicable account agreement before asserting a definitive contracting entity.",
  "platforms_note":"The live selector lists MT5, cTrader, and Match-Trader across the five visible Forex selector models checked on 2026-09-30. The selector says only MT5 is available for ZAR accounts. Actual availability remains configuration-specific; do not treat all listed platforms as universal.",
  "country_restrictions":"The linked AML Policy, version 1.1 dated March 2025, lists Afghanistan, Belarus, Burundi, Central African Republic, Republic of the Congo, Cuba, Crimea, Democratic Republic of the Congo, Eritrea, Guinea, Guinea-Bissau, Iran, Iraq, Liberia, Libya, Myanmar, North Korea, Papua New Guinea, Russia, Somalia, South Sudan, Sudan, Syria, Vanuatu, Venezuela, Yemen, and Zimbabwe. This is a dated published list, not confirmed as current in 2026; recheck before displaying eligibility.",
  "current_forex_offers_observed":["Instant Funding PRO","IF Micro PRO","One-Phase PRO","Instant Funding Lite","One-Phase Lite"],
  "availability_note":"IF Micro Lite is marked Coming Soon. A Two-Phase model remains in page content but is hidden in the current account-mode selector, so availability for new purchases is unconfirmed. IF Evolve is explicitly futures-style and excluded from the Forex catalog."
}'::jsonb,
updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'instant-funding';

update bullish_banana.programs p
set account_sizes = '[5000,10000,25000,50000,100000]'::jsonb,
    max_leverage = 30,
    profit_split_percent = 80,
    payout_frequency = 'On demand, then every 7 days',
    minimum_trading_days = 0,
    news_allowed = true,
    weekend_holding_allowed = true,
    commercial_details = p.commercial_details || '{
      "availability":"Visible in Lite mode of official selector, rechecked 2026-09-30.",
      "size_capture":"$5,000, $10,000, $25,000, $50,000, and $100,000 displayed.",
      "rules_capture":"Current selector: 9% target; 4% daily loss; 6% maximum loss; 80% split; on-demand then every 7 days; no minimum trading days; news trading and weekend holding allowed; Forex leverage 1:30.",
      "pricing_note":"Selector price changes with platform, commission model, size, currency, and add-ons. A complete base-fee matrix by configuration was not captured; retain in_review and do not treat the default displayed price as a universal fee.",
      "source_note":"Official homepage selector and product-specific card interaction, rechecked 2026-09-30."
    }'::jsonb,
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'instant-funding' and p.slug = 'one-phase-lite';

update bullish_banana.program_phases ph
set profit_target_percent = 9,
    daily_drawdown_percent = 4,
    maximum_drawdown_percent = 6,
    drawdown_type = 'static',
    minimum_trading_days = 0,
    raw_rules = ph.raw_rules || '{
      "source_note":"Official homepage selector current One-Phase Lite card, rechecked 2026-09-30; supersedes the older 7% target / 7% max-loss rules snapshot.",
      "payout_cadence":"On demand, then every 7 days",
      "profit_split":"80%",
      "news_trading":"Allowed",
      "weekend_holding":"Allowed",
      "forex_leverage":"1:30",
      "account_sizes_usd":[5000,10000,25000,50000,100000],
      "pricing_note":"No universal fee schedule inferred; selector amount depends on selected platform, account type, account size, currency, and add-ons."
    }'::jsonb,
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'instant-funding'
  and p.slug = 'one-phase-lite' and ph.phase_number = 1;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://instantfunding.com/', 'Current selector recheck — 2026-09-30',
       'Five visible Forex selector models and their account modes, displayed sizes, default selected configurations, and current rule summaries checked 2026-09-30. Selector pricing is configuration-dependent; full fee matrices remain unverified. Homepage legal disclosure conflicts with the June 2026 General Terms PDF on the named contracting party.'
from bullish_banana.firms f
where f.slug = 'instant-funding'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id and s.source_url = 'https://instantfunding.com/'
      and s.source_label = 'Current selector recheck — 2026-09-30'
  );

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://instantfunding.com/wp-content/uploads/2025/03/AML-Policy.pdf', 'AML Policy — version 1.1, March 2025',
       'Published linked AML policy contains a restricted/sanctioned country list. The document is dated March 2025 and has not been confirmed current as of 2026-09-30; do not treat its eligibility list as current without rechecking.'
from bullish_banana.firms f
where f.slug = 'instant-funding'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id and s.source_url = 'https://instantfunding.com/wp-content/uploads/2025/03/AML-Policy.pdf'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://instantfunding.com/', 'One-Phase Lite selector and rules recheck — 2026-09-30',
       'Current Lite selector shows sizes $5K–$100K, a 9% target, 4% daily and 6% maximum loss, 80% split, no minimum days, on-demand then weekly payout cadence, and news/weekend permission. Fees vary by platform, account type, currency, size, and add-ons and were not fully captured.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug = 'one-phase-lite'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = 'https://instantfunding.com/'
      and s.source_label = 'One-Phase Lite selector and rules recheck — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(),
       'Official selector and terms rechecked 2026-09-30. Five active visible Forex model variants confirmed, IF Micro Lite remains Coming Soon, and Two-Phase availability is unresolved because the page model is hidden. Operator/payment-agent disclosure conflicts with June 2026 General Terms PDF. Full configuration fee matrices and eligible jurisdiction list remain open.'
from bullish_banana.firms f where f.slug = 'instant-funding';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(),
       'Current selector rules rechecked 2026-09-30. One-Phase Lite corrected from prior 7% target / 7% maximum loss snapshot to current 9% target / 4% daily / 6% maximum loss, 80% split, zero minimum days, and on-demand then 7-day payout cadence. Program remains in_review until full size/platform/account-type/add-on fee matrix and account agreement conditions are captured.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug = 'one-phase-lite';
