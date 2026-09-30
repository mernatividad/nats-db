-- Full Three Phase size/base-fee schedule captured from the live official selector.
-- Preserve the active CHART30 offer separately from base prices; leave in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set account_sizes = '[5000,10000,15000,25000,50000,100000,200000,400000]'::jsonb,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', '[
        {"account_size":5000,"fee":39,"currency":"USD"},
        {"account_size":10000,"fee":59,"currency":"USD"},
        {"account_size":15000,"fee":79,"currency":"USD"},
        {"account_size":25000,"fee":149,"currency":"USD"},
        {"account_size":50000,"fee":249,"currency":"USD"},
        {"account_size":100000,"fee":399,"currency":"USD"},
        {"account_size":200000,"fee":799,"currency":"USD"},
        {"account_size":400000,"fee":1599,"currency":"USD"}
      ]'::jsonb,
      'price_capture', 'Full current selector base-fee schedule directly captured at all eight listed sizes on 2026-09-30. CHART30 discounted prices were displayed separately and are not base prices.',
      'live_selector_recheck_2026_09_30', jsonb_build_object(
        'variant_available', true,
        'account_sizes', '[5000,10000,15000,25000,50000,100000,200000,400000]'::jsonb,
        'verified_base_fee_rows', '[
          {"account_size":5000,"fee":39,"currency":"USD"},
          {"account_size":10000,"fee":59,"currency":"USD"},
          {"account_size":15000,"fee":79,"currency":"USD"},
          {"account_size":25000,"fee":149,"currency":"USD"},
          {"account_size":50000,"fee":249,"currency":"USD"},
          {"account_size":100000,"fee":399,"currency":"USD"},
          {"account_size":200000,"fee":799,"currency":"USD"},
          {"account_size":400000,"fee":1599,"currency":"USD"}
        ]'::jsonb,
        'promo_rows', '[
          {"account_size":5000,"code":"CHART30","displayed_fee":27.30,"currency":"USD"},
          {"account_size":10000,"code":"CHART30","displayed_fee":41.30,"currency":"USD"},
          {"account_size":15000,"code":"CHART30","displayed_fee":55.30,"currency":"USD"},
          {"account_size":25000,"code":"CHART30","displayed_fee":104.30,"currency":"USD"},
          {"account_size":50000,"code":"CHART30","displayed_fee":174.30,"currency":"USD"},
          {"account_size":100000,"code":"CHART30","displayed_fee":279.30,"currency":"USD"},
          {"account_size":200000,"code":"CHART30","displayed_fee":559.30,"currency":"USD"},
          {"account_size":400000,"code":"CHART30","displayed_fee":1119.30,"currency":"USD"}
        ]'::jsonb,
        'promo_scope', 'The selector displayed CHART30 / 30% off during capture. Keep this dated promotional schedule separate from base fees; do not imply continued availability.',
        'phase_observations', '[
          {"phase":1,"target_percent":5,"daily_loss_percent":5,"daily_loss_reference":"Previous-day closing balance at 5PM EST","maximum_drawdown_percent":5,"drawdown_type":"static","fee_refund_display":"100%"},
          {"phase":2,"target_percent":5,"daily_loss_percent":5,"daily_loss_reference":"Previous-day closing balance at 5PM EST","maximum_drawdown_percent":5,"drawdown_type":"static","fee_refund_display":"Not displayed"},
          {"phase":3,"target_percent":5,"daily_loss_percent":5,"daily_loss_reference":"Previous-day closing balance at 5PM EST","maximum_drawdown_percent":5,"drawdown_type":"static","fee_refund_display":"Not displayed"}
        ]'::jsonb,
        'funded_and_trading_observation', 'Page displayed five minimum trading days, unlimited maximum days, up to 90% performance split, up to 50:1 leverage, EAs/weekend/news allowed, 100% refundable fee, and MT5/DXtrade/TradingView. First payout on demand after the first funded trade closes; page says five minimum funded days, $50 minimum, monthly default or biweekly add-on.',
        'remaining_open_items', '["RAW/All-In selection effects and account-level platform mapping","Contract/refund eligibility and timing","Verify payout terms against account contract","Confirm the selector rules apply across all optional checkout configurations"]'::jsonb
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'three-phase';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/programs/three-phase-challenge/',
       'Live Three Phase selector full size and fee matrix — 2026-09-30',
       'Captured all eight current selector sizes and base fees: $5K/$39, $10K/$59, $15K/$79, $25K/$149, $50K/$249, $100K/$399, $200K/$799, and $400K/$1,599. CHART30 displayed discounted prices separately. Phase tabs showed 5% target in each of three phases, 5% daily loss based on previous-day balance at 5PM EST, and 5% static maximum loss. Page showed five minimum days, unlimited duration, up to 90% split, up to 50:1 leverage, EAs/weekend/news allowed, 100% refundable fee, MT5/DXtrade/TradingView, and on-demand first payout with $50 minimum after five minimum funded days; monthly default or biweekly add-on. Account-level feed/configuration, payout contract and refund terms remain open; keep in_review.',
       '2026-09-30 02:16:17+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'three-phase'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://fxify.com/programs/three-phase-challenge/' and s.source_label = 'Live Three Phase selector full size and fee matrix — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 02:16:17+00'::timestamptz,
       'Rechecked live official Three Phase selector 2026-09-30 and captured all eight current base-fee rows and the separate displayed CHART30 promo. Inspected all phase tabs: each shows 5% target, 5% daily loss and 5% static maximum drawdown. Funded/payout and general trading terms recorded from the page; account-level configuration and contract details remain open. Keep in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'three-phase'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30 02:16:17+00'::timestamptz and v.notes like 'Rechecked live official Three Phase selector 2026-09-30%');
