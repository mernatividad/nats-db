-- Full One Phase size/base-fee schedule captured from the live official selector.
-- Preserve the active CHART30 offer separately from base prices; leave in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set account_sizes = '[5000,10000,15000,25000,50000,100000,200000,400000]'::jsonb,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
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
      'price_capture', 'Full current selector base-fee schedule directly captured at all eight listed sizes on 2026-09-30. CHART30 discounted prices were displayed separately and are not base prices.',
      'live_selector_recheck_2026_09_30', jsonb_build_object(
        'variant_available', true,
        'account_sizes', '[5000,10000,15000,25000,50000,100000,200000,400000]'::jsonb,
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
        'promo_rows', '[
          {"account_size":5000,"code":"CHART30","displayed_fee":41.30,"currency":"USD"},
          {"account_size":10000,"code":"CHART30","displayed_fee":62.30,"currency":"USD"},
          {"account_size":15000,"code":"CHART30","displayed_fee":83.30,"currency":"USD"},
          {"account_size":25000,"code":"CHART30","displayed_fee":139.30,"currency":"USD"},
          {"account_size":50000,"code":"CHART30","displayed_fee":265.30,"currency":"USD"},
          {"account_size":100000,"code":"CHART30","displayed_fee":384.30,"currency":"USD"},
          {"account_size":200000,"code":"CHART30","displayed_fee":734.30,"currency":"USD"},
          {"account_size":400000,"code":"CHART30","displayed_fee":2065.00,"currency":"USD"}
        ]'::jsonb,
        'promo_scope', 'The selector displayed CHART30 / 30% off during capture. Keep this dated promotional schedule separate from base fees; do not imply continued availability.',
        'phase_observation', 'At the selected $5K, $10K, $15K, $25K, $50K, $100K, $200K and $400K configurations, the page displayed 10% target, 3% daily loss based on prior-day end balance at 5PM EST, 6% trailing max loss that locks at starting balance after 6% profit or a processed payout, five minimum trading days and unlimited duration.',
        'trading_conditions_observation', 'The selector displayed up to 90% split, up to 50:1 leverage, EAs/weekend/news allowed, 100% refundable fee, and MT5/DXtrade/TradingView. Account-specific feed/platform and refund eligibility/timing remain open.',
        'remaining_open_items', '["RAW/All-In selection effects and account-level platform mapping","Contract/refund eligibility and timing","Verify payout terms against account contract","Confirm the selector rules apply across all optional checkout configurations"]'::jsonb
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'one-phase';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/programs/one-phase/',
       'Live One Phase selector full size and fee matrix — 2026-09-30',
       'Captured all eight current selector sizes and base fees: $5K/$59, $10K/$89, $15K/$119, $25K/$199, $50K/$379, $100K/$549, $200K/$1,049, and $400K/$2,950. CHART30 displayed discounted prices separately. Selected-size rules showed 10% target, 3% daily loss, 6% trailing maximum loss locking at starting balance after 6% profit or processed payout, five minimum days and unlimited duration. Selector showed up to 90% split, up to 50:1 leverage, EAs/weekend/news allowed, 100% refundable fee, and MT5/DXtrade/TradingView. Feed, account-level configuration, payout/legal refund terms remain open; keep in_review.',
       '2026-09-30 02:09:25+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'one-phase'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://fxify.com/programs/one-phase/' and s.source_label = 'Live One Phase selector full size and fee matrix — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 02:09:25+00'::timestamptz,
       'Rechecked live official One Phase selector 2026-09-30 and captured all eight currently listed size/base-fee pairs. Captured selected-size phase rules and current promo as separate dated evidence. Complete account-level feed/platform, configuration, payout contract, refund eligibility and timing remain open. Keep in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'one-phase'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30 02:09:25+00'::timestamptz and v.notes like 'Rechecked live official One Phase selector 2026-09-30%');
