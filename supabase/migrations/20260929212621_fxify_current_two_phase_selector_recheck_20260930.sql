-- Recheck FXIFY's interactive Two Phase selector on 2026-09-30.
-- Captures current variant availability and visible base fees/rules without
-- treating promo pricing as base; unresolved terms keep offers in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set account_sizes = case p.slug
      when 'two-phase-classic' then '[5000,10000,15000,25000,50000,100000]'::jsonb
      when 'two-phase-standard' then '[5000,10000,15000,25000,50000,100000,200000,400000]'::jsonb
      else p.account_sizes
    end,
    max_leverage = case p.slug
      when 'two-phase-pro' then 30
      else p.max_leverage
    end,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
      case p.slug
        when 'two-phase-standard' then jsonb_build_object(
          'account_size_prices', '[
            {"account_size":5000,"fee":59,"currency":"USD"},
            {"account_size":10000,"fee":89,"currency":"USD"},
            {"account_size":15000,"fee":119,"currency":"USD"},
            {"account_size":25000,"fee":199,"currency":"USD"},
            {"account_size":50000,"fee":379,"currency":"USD"},
            {"account_size":100000,"fee":549,"currency":"USD"},
            {"account_size":200000,"fee":1049,"currency":"USD"},
            {"account_size":400000,"fee":2950,"currency":"USD"}
          ]'::jsonb,
          'live_selector_recheck_2026_09_30', jsonb_build_object(
            'variant_available', true,
            'selector_account_sizes', '[5000,10000,15000,25000,50000,100000,200000,400000]'::jsonb,
            'verified_base_fee_rows', '[
              {"account_size":5000,"fee":59,"currency":"USD"},
              {"account_size":10000,"fee":89,"currency":"USD"},
              {"account_size":15000,"fee":119,"currency":"USD"},
              {"account_size":25000,"fee":199,"currency":"USD"},
              {"account_size":50000,"fee":379,"currency":"USD"},
              {"account_size":100000,"fee":549,"currency":"USD"},
              {"account_size":200000,"fee":1049,"currency":"USD"},
              {"account_size":400000,"fee":2950,"currency":"USD"}
            ]'::jsonb,
            'phase_1_observation', '10% target; 4% daily loss; 10% trailing max drawdown; five minimum trading days; unlimited maximum days.',
            'funded_observation', 'Up to 90% split; selector says on-demand first payout and five minimum funded trading days; the page also lists 14 or 30 day payout frequency. Reconcile cadence and account-specific terms before publication.',
            'platforms_observed', '["MetaTrader 5","DXtrade","TradingView"]'::jsonb,
            'promotion_observation', 'Selector showed CHART30 at 30% off. The page header separately displayed FIFTY40 (40% off $50K, excluding Instant Lite) and ONESTEP35 (35% off One Phase). These are volatile promotions, not base fees.',
            'price_matrix_status', 'Base fees directly captured at every currently listed size: $5K, $10K, $15K, $25K, $50K, $100K, $200K and $400K. Configuration effects may change price; retain the selector capture as the base fee schedule and keep plan customizations under review.'
          )
        )
        when 'two-phase-pro' then jsonb_build_object(
          'max_leverage_observation', 30,
          'account_size_prices', '[{"account_size":10000,"fee":129,"currency":"USD"},{"account_size":25000,"fee":225,"currency":"USD"},{"account_size":50000,"fee":375,"currency":"USD"},{"account_size":100000,"fee":599,"currency":"USD"},{"account_size":150000,"fee":849,"currency":"USD"},{"account_size":200000,"fee":1099,"currency":"USD"},{"account_size":250000,"fee":1350,"currency":"USD"}]'::jsonb,
          'live_selector_recheck_2026_09_30', jsonb_build_object(
            'variant_available', true,
            'selector_account_sizes', '[10000,25000,50000,100000,150000,200000,250000]'::jsonb,
            'account_size_prices', '[
              {"account_size":10000,"fee":129,"currency":"USD"},
              {"account_size":25000,"fee":225,"currency":"USD"},
              {"account_size":50000,"fee":375,"currency":"USD"},
              {"account_size":100000,"fee":599,"currency":"USD"},
              {"account_size":150000,"fee":849,"currency":"USD"},
              {"account_size":200000,"fee":1099,"currency":"USD"},
              {"account_size":250000,"fee":1350,"currency":"USD"}
            ]'::jsonb,
            'verified_base_fee_rows', '[
              {"account_size":10000,"fee":129,"currency":"USD"},
              {"account_size":25000,"fee":225,"currency":"USD"},
              {"account_size":50000,"fee":375,"currency":"USD"},
              {"account_size":100000,"fee":599,"currency":"USD"},
              {"account_size":150000,"fee":849,"currency":"USD"},
              {"account_size":200000,"fee":1099,"currency":"USD"},
              {"account_size":250000,"fee":1350,"currency":"USD"}
            ]'::jsonb,
            'phase_1_observation', '4% target; 4% daily loss; 8% static max loss; three minimum trading days; unlimited maximum days.',
            'funded_observation', '80% split; 10 day payout frequency; $4,000 max gains per day; selector says on-demand payout No and fee refund after first payout No.',
            'trading_conditions_observed', 'Leverage up to 30:1; EAs, weekend holding, and news trading allowed.',
            'platforms_observed', '["MetaTrader 5","DXtrade","TradingView"]'::jsonb,
            'promotion_observation', 'The selector showed CHART30 at 30% off; the $10K base fee was $129 and the displayed promo was $90.30. Do not store promo as base.',
            'price_matrix_status', 'Base fees directly captured at every currently listed size: $10K, $25K, $50K, $100K, $150K, $200K and $250K. Configuration effects and exact account-level payout/legal terms still require verification.'
          )
        )
        when 'two-phase-classic' then jsonb_build_object(
          'account_size_prices', '[
            {"account_size":5000,"fee":59,"currency":"USD"},
            {"account_size":10000,"fee":89,"currency":"USD"},
            {"account_size":15000,"fee":119,"currency":"USD"},
            {"account_size":25000,"fee":199,"currency":"USD"},
            {"account_size":50000,"fee":379,"currency":"USD"},
            {"account_size":100000,"fee":549,"currency":"USD"}
          ]'::jsonb,
          'live_selector_recheck_2026_09_30', jsonb_build_object(
            'variant_available', true,
            'selector_account_sizes', '[5000,10000,15000,25000,50000,100000]'::jsonb,
            'verified_base_fee_rows', '[
              {"account_size":5000,"fee":59,"currency":"USD"},
              {"account_size":10000,"fee":89,"currency":"USD"},
              {"account_size":15000,"fee":119,"currency":"USD"},
              {"account_size":25000,"fee":199,"currency":"USD"},
              {"account_size":50000,"fee":379,"currency":"USD"},
              {"account_size":100000,"fee":549,"currency":"USD"}
            ]'::jsonb,
            'price_matrix_status', 'Base fees directly captured at every currently listed size. Configuration effects and unresolved account-level terms remain under review.',
            'platforms_observed', '["MetaTrader 5","DXtrade","TradingView"]'::jsonb,
            'promotion_observation', 'The selector showed CHART30 at 30% off. A separate page header displayed other overlapping offers; do not treat promotional amounts as base fees.'
          )
        )
        else '{}'::jsonb
      end,
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug in ('two-phase-classic','two-phase-standard','two-phase-pro');

-- The current Two Phase selector names MT5, DXtrade, and TradingView. Its
-- product-level evidence does not list MT4, so remove the shared-page-only
-- association from these three Two Phase variants.
delete from bullish_banana.program_platforms pp
using bullish_banana.programs p,
      bullish_banana.firms f,
      bullish_banana.platforms pl
where pp.program_id = p.id
  and pp.platform_id = pl.id
  and p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug in ('two-phase-classic','two-phase-standard','two-phase-pro')
  and pl.slug = 'metatrader-4';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'two_phase_selector_variants_2026_09_30',
      'The live Two Phase selector exposes Classic, Standard, and Pro as separate account options. All three variants are currently purchasable selector options; displayed base-fee matrices are captured for Classic, Standard and Pro. Account-specific configuration, legal and payout terms remain under review.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'fxify';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes, captured_at)
select f.id,
       'https://fxify.com/programs/two-phase/',
       'Live Two Phase selector variant and price recheck — 2026-09-30',
       'Interactive selector currently exposes Classic, Standard, and Pro. Classic base fees directly captured at all six sizes ($5K/$59, $10K/$89, $15K/$119, $25K/$199, $50K/$379, $100K/$549); Standard at all eight sizes through $400K/$2,950; and Pro at all seven sizes through $250K/$1,350. CHART30 promo amounts were separate from base fees; overlapping header promotions were also visible. The page-wide payout copy and Classic selector payout fields conflict; preserve those variants separately and leave unresolved terms in_review.',
       '2026-09-29 21:53:19+00'::timestamptz
from bullish_banana.firms f
where f.slug = 'fxify'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://fxify.com/programs/two-phase/'
      and s.source_label = 'Live Two Phase selector variant and price recheck — 2026-09-30'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/programs/two-phase/',
       'Live Two Phase selector variant and price recheck — 2026-09-30',
       case p.slug
         when 'two-phase-standard' then 'Selector confirms Standard is available. Captured current base fees at every listed size: $5K/$59, $10K/$89, $15K/$119, $25K/$199, $50K/$379, $100K/$549, $200K/$1,049, and $400K/$2,950. Payout cadence/configuration and customized pricing effects remain open.'
         when 'two-phase-pro' then 'Selector confirms Pro availability and the complete current base-fee matrix: $10K/$129, $25K/$225, $50K/$375, $100K/$599, $150K/$849, $200K/$1,099 and $250K/$1,350. It displays 4% first-phase target, 4% daily loss, 8% static max loss, three minimum days, 80% split, 10 day payout, $4,000 max gains/day, and up to 30:1 leverage. Configuration-specific pricing and remaining account terms remain open.'
         else 'Selector confirms Classic availability and full current base-fee matrix: $5K/$59, $10K/$89, $15K/$119, $25K/$199, $50K/$379, and $100K/$549. Product page lists MT5, DXtrade and TradingView. The selector’s payout fields differ from shared page payout copy; do not collapse them into one claim.'
       end,
       '2026-09-29 21:53:19+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug in ('two-phase-classic','two-phase-standard','two-phase-pro')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://fxify.com/programs/two-phase/'
      and s.source_label = 'Live Two Phase selector variant and price recheck — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id,
       '2026-09-29 21:53:19+00'::timestamptz,
       'Rechecked the interactive Two Phase selector 2026-09-30: Classic, Standard, and Pro are all currently offered. Classic, Standard and Pro base fees were directly captured at every listed size. Active promo codes remain separate. Keep all program records in_review pending other product-family matrices, payout/legal reconciliation, and per-account configuration evidence.'
from bullish_banana.firms f
where f.slug = 'fxify'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.firm_id = f.id
      and v.verified_at = '2026-09-29 21:53:19+00'::timestamptz
      and v.notes like 'Rechecked the interactive Two Phase selector 2026-09-30:%'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-29 21:53:19+00'::timestamptz,
       case p.slug
         when 'two-phase-standard' then 'Current interactive selector rechecked 2026-09-30. Confirms Standard variant availability, all eight listed size choices and base fees ($5K/$59, $10K/$89, $15K/$119, $25K/$199, $50K/$379, $100K/$549, $200K/$1,049, $400K/$2,950), first-phase rules, platforms, and payout display. The page-level payout cadence and configuration-specific price effects remain unresolved; keep in_review.'
         when 'two-phase-pro' then 'Current interactive selector rechecked 2026-09-30. Confirms Pro availability and full current base-fee matrix ($10K/$129, $25K/$225, $50K/$375, $100K/$599, $150K/$849, $200K/$1,099, $250K/$1,350); 4% first-phase target, 4% daily loss, 8% static max loss, 3 minimum days, 80% split, 10-day payout frequency, $4,000 max gains/day, up to 30:1 leverage, and MT5/DXtrade/TradingView. Configuration effects and contract terms remain open; keep in_review.'
         else 'Current interactive selector rechecked 2026-09-30. Confirms Classic availability and all six listed base fees ($5K/$59, $10K/$89, $15K/$119, $25K/$199, $50K/$379, $100K/$549), plus MT5/DXtrade/TradingView. Selector payout rules differ from shared page copy; keep in_review until account-level payout and legal terms are reconciled.'
       end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug in ('two-phase-classic','two-phase-standard','two-phase-pro')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-29 21:53:19+00'::timestamptz
      and v.notes like 'Current interactive selector rechecked 2026-09-30.%'
  );
