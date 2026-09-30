-- Capture both live Instant Funding selector variants and preserve source conflicts.
-- Fees, sizes, payout copy, and account rules differ by variant; keep both in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set account_sizes = '[1000,2500,5000,10000,25000,50000,75000,100000]'::jsonb,
    news_allowed = false,
    weekend_holding_allowed = false,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', '[
        {"account_size":1000,"fee":69,"currency":"USD"},
        {"account_size":2500,"fee":119,"currency":"USD"},
        {"account_size":5000,"fee":229,"currency":"USD"},
        {"account_size":10000,"fee":449,"currency":"USD"},
        {"account_size":25000,"fee":899,"currency":"USD"},
        {"account_size":50000,"fee":1749,"currency":"USD"},
        {"account_size":75000,"fee":2499,"currency":"USD"},
        {"account_size":100000,"fee":4249,"currency":"USD"}
      ]'::jsonb,
      'price_capture', 'Live Instant Funding Standard selector base fees directly captured at all eight listed sizes on 2026-09-30. CHART30 discounted amounts were shown separately; they are not base prices.',
      'live_selector_recheck_2026_09_30', jsonb_build_object(
        'variant_available', true,
        'account_sizes', '[1000,2500,5000,10000,25000,50000,75000,100000]'::jsonb,
        'verified_base_fee_rows', '[
          {"account_size":1000,"fee":69,"currency":"USD"},
          {"account_size":2500,"fee":119,"currency":"USD"},
          {"account_size":5000,"fee":229,"currency":"USD"},
          {"account_size":10000,"fee":449,"currency":"USD"},
          {"account_size":25000,"fee":899,"currency":"USD"},
          {"account_size":50000,"fee":1749,"currency":"USD"},
          {"account_size":75000,"fee":2499,"currency":"USD"},
          {"account_size":100000,"fee":4249,"currency":"USD"}
        ]'::jsonb,
        'promo_rows', '[
          {"account_size":1000,"code":"CHART30","displayed_fee":48.30,"currency":"USD"},
          {"account_size":2500,"code":"CHART30","displayed_fee":83.30,"currency":"USD"},
          {"account_size":5000,"code":"CHART30","displayed_fee":160.30,"currency":"USD"},
          {"account_size":10000,"code":"CHART30","displayed_fee":314.30,"currency":"USD"},
          {"account_size":25000,"code":"CHART30","displayed_fee":629.30,"currency":"USD"},
          {"account_size":50000,"code":"CHART30","displayed_fee":1224.30,"currency":"USD"},
          {"account_size":75000,"code":"CHART30","displayed_fee":1749.30,"currency":"USD"},
          {"account_size":100000,"code":"CHART30","displayed_fee":2974.30,"currency":"USD"}
        ]'::jsonb,
        'promo_scope', 'CHART30 displayed as 30% off during selector capture. Keep the date-scoped values separate from base fees.',
        'phase_summary', 'No evaluation target. Standard selector displays an 8% daily loss limit based on previous-day closing balance at 5PM EST and an 8% trailing maximum drawdown that locks at initial balance after 8% closed profit or a payout. Consistency rule, minimum days and maximum days display N/A.',
        'funded_rules', 'Selector displays up to 90% split. Official FAQ says first payout after 14 days with a $50 minimum; the page footer says Instant Funding payouts every 14 days. The page hero also markets day-one / instant payouts, creating a payout-timing conflict to preserve.',
        'trading_conditions', 'Live Standard selector displays up to 50:1 leverage; EAs, weekend holding and news trading are not allowed; platforms shown are MT5, DXtrade and TradingView. RAW/All-In feed availability and account-level platform mapping remain unverified.',
        'fee_refund_policy', 'Live selector says no refund. Verify purchase contract wording.',
        'remaining_open_items', '["Resolve payout day-one marketing vs 14-day FAQ/footer wording","Verify daily-loss rule and max-drawdown wording against account contract","Platform/feed by account size and region","Forex instrument and commission mapping","Purchase/refund contract terms"]'::jsonb
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'instant-funding-standard';

update bullish_banana.programs p
set account_sizes = '[2500,5000,10000,25000,50000]'::jsonb,
    minimum_trading_days = 5,
    profit_split_percent = 90,
    payout_frequency = '10 days shown in Lite selector; shared product page says Instant Funding pays every 14 days (scope conflict)',
    news_allowed = false,
    weekend_holding_allowed = false,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', '[
        {"account_size":2500,"fee":19,"currency":"USD"},
        {"account_size":5000,"fee":44,"currency":"USD"},
        {"account_size":10000,"fee":89,"currency":"USD"},
        {"account_size":25000,"fee":169,"currency":"USD"},
        {"account_size":50000,"fee":289,"currency":"USD"}
      ]'::jsonb,
      'account_size_prices_note', 'Live Lite selector captures five current base fees through $50K. This replaces selector availability/fees from the launch article for the current offer; retain the article matrix below as dated conflicting source evidence.',
      'launch_article_prices_2026_09_30', '[
        {"account_size":2500,"fee":19,"currency":"USD"},
        {"account_size":5000,"fee":39,"currency":"USD"},
        {"account_size":10000,"fee":79,"currency":"USD"},
        {"account_size":25000,"fee":149,"currency":"USD"},
        {"account_size":50000,"fee":249,"currency":"USD"},
        {"account_size":100000,"fee":399,"currency":"USD"}
      ]'::jsonb,
      'live_selector_recheck_2026_09_30', jsonb_build_object(
        'variant_available', true,
        'account_sizes', '[2500,5000,10000,25000,50000]'::jsonb,
        'verified_base_fee_rows', '[
          {"account_size":2500,"fee":19,"currency":"USD"},
          {"account_size":5000,"fee":44,"currency":"USD"},
          {"account_size":10000,"fee":89,"currency":"USD"},
          {"account_size":25000,"fee":169,"currency":"USD"},
          {"account_size":50000,"fee":289,"currency":"USD"}
        ]'::jsonb,
        'promo_scope', 'No promotion price or coupon was displayed for Lite; the current page banner excludes Instant Lite.',
        'phase_summary', 'No profit target. Live Lite selector displays 3% daily loss based on previous-day closing balance at 5PM EST; 4% trailing maximum drawdown that locks at initial balance after 4% closed profit or payout; 20% consistency rule; five minimum trading days; no maximum days stated.',
        'funded_rules', 'Selector displays up to 90% split, payout frequency every 10 days and $50 withdrawal policy. Shared product page footer says Instant Funding payouts every 14 days; applicability to Lite conflicts with the specific selector. Preserve both statements pending contract/account confirmation.',
        'trading_conditions', 'Live Lite selector displays up to 50:1 leverage; EAs, weekend holding and news trading are not allowed; platforms shown are MT5, DXtrade and TradingView. RAW/All-In feed availability and account-level platform mapping remain unverified.',
        'fee_refund_policy', 'Live selector says no refund. Verify purchase contract wording.',
        'size_fee_conflict', 'Live selector lists only $2.5K, $5K, $10K, $25K and $50K at $19, $44, $89, $169 and $289. The official Lite launch article lists $2.5K/$19, $5K/$39, $10K/$79, $25K/$149, $50K/$249, and $100K/$399. Treat selector values as current checkout evidence while retaining the article mismatch.',
        'remaining_open_items', '["Resolve the $100K launch-article offer and live selector size cap","Resolve Lite 10-day selector payout vs 14-day shared footer","Verify daily/max drawdown and consistency rules against account contract","Platform/feed by account size and region","Forex instrument and commission mapping","Purchase/refund contract terms"]'::jsonb
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'instant-funding-lite';

-- Instant-specific selector pages name only MT5, DXtrade and TradingView.
delete from bullish_banana.program_platforms pp
using bullish_banana.programs p,
      bullish_banana.firms f,
      bullish_banana.platforms pl
where pp.program_id = p.id
  and pp.platform_id = pl.id
  and p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug in ('instant-funding-standard','instant-funding-lite')
  and pl.slug = 'metatrader-4';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/programs/instant-funding/',
       case p.slug
         when 'instant-funding-standard' then 'Live Instant Funding Standard selector matrix and rules — 2026-09-30'
         else 'Live Instant Funding Lite selector matrix and rules — 2026-09-30'
       end,
       case p.slug
         when 'instant-funding-standard' then 'The current Standard selector lists $1K/$69, $2.5K/$119, $5K/$229, $10K/$449, $25K/$899, $50K/$1,749, $75K/$2,499 and $100K/$4,249 base prices; CHART30 discounts displayed separately. It shows no target, 8% daily loss and 8% trailing max drawdown, N/A consistency and day limits, up to 90% split, up to 50:1 leverage, no EAs/weekend/news, no refund, and MT5/DXtrade/TradingView. A footer says payouts every 14 days, while hero marketing says day-one/instant payouts. Keep payout wording and account terms under review.'
         else 'The current Lite selector lists five sizes only: $2.5K/$19, $5K/$44, $10K/$89, $25K/$169, and $50K/$289, with no Lite promotion displayed. The launch article lists different fees and an additional $100K size; preserve that conflict. Selector shows no target, 3% daily loss, 4% trailing max drawdown, 20% consistency, five minimum days, up to 90% split, 10-day payout cadence, $50 withdrawal policy, up to 50:1, no EAs/weekend/news, no refund, and MT5/DXtrade/TradingView. The page-wide Instant payout footer says every 14 days, conflicting with the specific Lite selector.'
       end,
       '2026-09-30 02:24:59+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug in ('instant-funding-standard','instant-funding-lite')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://fxify.com/programs/instant-funding/'
      and s.source_label = case p.slug
        when 'instant-funding-standard' then 'Live Instant Funding Standard selector matrix and rules — 2026-09-30'
        else 'Live Instant Funding Lite selector matrix and rules — 2026-09-30'
      end
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 02:24:59+00'::timestamptz,
       case p.slug
         when 'instant-funding-standard' then 'Rechecked current Instant Funding Standard selector on 2026-09-30, selecting all eight sizes and capturing base fees and separate CHART30 displays. Selector rules/payout marketing conflicts are preserved; program stays in_review.'
         else 'Rechecked current Instant Funding Lite selector on 2026-09-30, selecting all five currently listed sizes. Current base fees/size availability conflict with Lite launch article; specific selector payout frequency also conflicts with the product-wide 14-day footer. Preserved both; program stays in_review.'
       end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug in ('instant-funding-standard','instant-funding-lite')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30 02:24:59+00'::timestamptz
      and v.notes like case p.slug
        when 'instant-funding-standard' then 'Rechecked current Instant Funding Standard selector on 2026-09-30%'
        else 'Rechecked current Instant Funding Lite selector on 2026-09-30%'
      end
  );
