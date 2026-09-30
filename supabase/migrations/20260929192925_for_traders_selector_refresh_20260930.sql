set search_path = bullish_banana, extensions, public;

-- Recheck live For Traders public offer/pricing pages and current Forex Help Center links on 2026-09-30.
-- Do not publish: checkout variants, platform-by-program mapping, and promotions remain dynamic.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
    jsonb_build_object(
      'selector_rechecked_on', '2026-09-30',
      'selector_recheck_note', 'Official challenge pricing page was rechecked 2026-09-30. Displayed regular/current promo fee pairs remain as previously captured; discounts are time-sensitive. Help Center currently publishes a $9 PAY AFTER PASS entry promotion, but does not identify a complete size-to-activation matrix in that announcement. Keep the program in review until exact current checkout configurations are verified.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'for-traders'
  and p.slug in ('fast-1-step','fast-static-1-step','classic-2-step','pay-after-pass-1-step','instant-forex','instant-pro-forex');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://fortraders.com/challenges', 'For Traders current Forex challenge catalog', 'First-party offer and price matrix rechecked 2026-09-30. Displayed prices include regular and promotional values; promotions are temporary and not permanent list prices.'),
  ('https://help.fortraders.com/en/articles/15360683-fast-account-forex', 'FAST Forex rules, current article', 'Current official Help Center article found 2026-09-30. Describes order-dependent 9%/11% target and corresponding account rules.'),
  ('https://help.fortraders.com/en/articles/15653608-pay-after-pass-for-only-9', 'PAY AFTER PASS temporary $9 entry promotion', 'Official Help Center article dated 2026-07-24 advertises a temporary $9 entry fee. The article does not provide a complete account-size/activation-fee matrix; do not replace the size-specific standard schedule without checkout confirmation.'),
  ('https://help.fortraders.com/en/articles/15379390-instant-pro-account-forex', 'INSTANT PRO Forex rules', 'Current official Help Center rules page rechecked 2026-09-30.'),
  ('https://help.fortraders.com/en/articles/15208251-account-types-comparison', 'For Traders account type comparison', 'Official comparison page lists product families and availability; STRIKE is not confirmed for purchase in the current Forex offer set.')
) as x(url, label, notes) on true
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('fast-1-step', 'https://help.fortraders.com/en/articles/15360683-fast-account-forex', 'FAST Forex rules, current article', 'Current official Forex rule article found 2026-09-30; selected order controls target variant.'),
  ('pay-after-pass-1-step', 'https://help.fortraders.com/en/articles/15653608-pay-after-pass-for-only-9', 'PAY AFTER PASS $9 promotion', 'Temporary promotion article dated 2026-07-24. Size/activation mapping and present checkout availability remain unverified.'),
  ('instant-pro-forex', 'https://help.fortraders.com/en/articles/15379390-instant-pro-account-forex', 'INSTANT PRO Forex rules, current article', 'Current rules page rechecked 2026-09-30.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Rechecked current official challenge catalog prices and Forex offer comparison on 2026-09-30; identified newer $9 Pay After Pass promotion article and current FAST rule article. Promotions and checkout variant mapping remain unresolved; all program rows retained in review.'
from bullish_banana.firms where slug = 'for-traders';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Official offer/pricing page and current Forex Help Center evidence rechecked 2026-09-30. Preserve dated fees and promotion caveats; keep in_review pending live account-size/cadence/platform selector confirmation.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'for-traders'
  and p.slug in ('fast-1-step','fast-static-1-step','classic-2-step','pay-after-pass-1-step','instant-forex','instant-pro-forex');

-- Capture the current offer-specific selector matrices and configurable rules without treating
-- the separate marketing-page promotion table as an identical checkout price source.
update bullish_banana.programs p
set commercial_details = (
      coalesce(p.commercial_details, '{}'::jsonb)
      || jsonb_build_object(
        'marketing_page_account_size_prices', p.commercial_details -> 'account_size_prices',
        'account_size_prices', (selector.details::jsonb) -> 'selector_account_size_prices'
      )
    ) || selector.details::jsonb,
    updated_at = now()
from bullish_banana.firms f
join (values
  ('fast-1-step', '{"selector_capture":"2026-09-30","selector_account_size_prices":[{"account_size":6000,"fee":49,"currency":"USD"},{"account_size":15000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":179,"currency":"USD"},{"account_size":50000,"fee":249,"currency":"USD"},{"account_size":100000,"fee":469,"currency":"USD"}],"selector_default_configuration":{"target_percent":9,"profit_split_percent":80},"selector_variants_observed_at_25000":{"target_percent":[9,{"value":11,"fee_delta":-21}],"profit_split_percent":[{"value":70,"fee_delta":-10},80,{"value":90,"fee_delta":52}],"currency":"USD"},"platforms_observed_at_25000":["MetaTrader 5","TradeLocker","cTrader"],"selector_note":"Current order form list prices match the first price shown on the challenge marketing page. Configurable target and split adjustments observed at $25K only; platform choices can vary with size."}'),
  ('fast-static-1-step', '{"selector_capture":"2026-09-30","selector_account_size_prices":[{"account_size":6000,"fee":69,"currency":"USD"},{"account_size":15000,"fee":139,"currency":"USD"},{"account_size":25000,"fee":229,"currency":"USD"},{"account_size":50000,"fee":389,"currency":"USD"},{"account_size":100000,"fee":639,"currency":"USD"}],"selector_default_configuration":{"target_percent":10,"maximum_drawdown_percent":6,"daily_drawdown_percent":3,"profit_split_percent":80},"selector_configuration_options":{"profit_split_percent":[70,80,90],"rewards":"Bi-weekly"},"platform_note":"Platform choices are visible in the selector, but product- and size-specific availability was not fully enumerated.","selector_page_conflicts":[{"account_size":50000,"selector_fee":389,"marketing_page_list_fee":379},{"account_size":100000,"selector_fee":639,"marketing_page_list_fee":599}],"selector_note":"Current order form differs from the official challenge price table at $50K and $100K; keep the record in review until the provider reconciles the $10/$40 differences."}'),
  ('classic-2-step', '{"selector_capture":"2026-09-30","selector_account_size_prices":[{"account_size":6000,"fee":67,"currency":"USD"},{"account_size":15000,"fee":117,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":359,"currency":"USD"},{"account_size":100000,"fee":599,"currency":"USD"}],"selector_default_configuration":{"phase_targets_percent":[8,5],"maximum_drawdown_percent":8,"daily_drawdown_percent":4,"profit_split_percent":80},"selector_configuration_options_observed_at_25000":{"phase1_target_percent":[{"value":8,"fee_delta":0},{"value":10,"fee_delta":-21}],"maximum_drawdown_percent":[{"value":8,"fee_delta":0},{"value":10,"fee_delta":52}],"daily_drawdown_percent":[{"value":3,"fee_delta":-25},{"value":4,"fee_delta":0}],"profit_split_percent":[{"value":70,"fee_delta":-10},{"value":80,"fee_delta":0},{"value":90,"fee_delta":52}],"currency":"USD"},"selector_page_conflicts":[{"account_size":50000,"selector_fee":359,"marketing_page_list_fee":349},{"account_size":100000,"selector_fee":599,"marketing_page_list_fee":579}],"selector_note":"Official order form differs from the marketing-page list fee by $10 at $50K and $20 at $100K. The selector exposes a configurable phase target, max loss, daily loss and performance split; captured option deltas are specific to $25K and the selected 80% configuration."}'),
  ('pay-after-pass-1-step', '{"selector_capture":"2026-09-30","selector_account_size_prices":[{"account_size":25000,"fee":9,"activation_fee":189,"currency":"USD"},{"account_size":50000,"fee":9,"activation_fee":329,"currency":"USD"},{"account_size":100000,"fee":9,"activation_fee":499,"currency":"USD"},{"account_size":200000,"fee":9,"activation_fee":999,"currency":"USD"}],"selector_default_configuration":{"target_percent":2,"maximum_drawdown_percent":6,"daily_drawdown_percent":3,"profit_split_percent":80,"payout_frequency":"On-demand"},"selector_page_conflicts":[{"account_size":100000,"selector_activation_fee":499,"help_center_activation_fee":489}],"platforms_observed_at_25000":["MetaTrader 5","TradeLocker","cTrader"],"selector_note":"Current official order form offers $9 entry at each of four sizes. $100K selector activation is $499 versus $489 in the Forex Help Center table. $200K selector confirms $9 entry/$999 activation. Do not obscure the discrepancy."}'),
  ('instant-forex', '{"selector_capture":"2026-09-30","selector_account_size_prices":[{"account_size":6000,"fee":138,"currency":"USD"},{"account_size":15000,"fee":218,"currency":"USD"},{"account_size":25000,"fee":338,"currency":"USD"},{"account_size":50000,"fee":558,"currency":"USD"},{"account_size":100000,"fee":878,"currency":"USD"}],"selector_note":"Current order form base prices match the regular/list prices shown beside promotional prices on the official Instant pricing page."}'),
  ('instant-pro-forex', '{"selector_capture":"2026-09-30","selector_account_size_prices":[{"account_size":3000,"fee":109,"currency":"USD"},{"account_size":6000,"fee":219,"currency":"USD"},{"account_size":15000,"fee":439,"currency":"USD"},{"account_size":25000,"fee":839,"currency":"USD"}],"selector_note":"Current order form base prices match the regular/list prices shown beside promotional prices on the official Instant pricing page."}')
) as selector(program_slug, details) on true
where f.slug = 'for-traders' and p.firm_id = f.id and p.slug = selector.program_slug;

-- Use the same human-readable fields consumed by the challenge detail, comparison, and admin views.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
    jsonb_build_object('price_configuration', detail.price_configuration, 'review_note', detail.review_note),
    updated_at = now()
from bullish_banana.firms f
join (values
  ('fast-1-step', 'The live selector defaults to a 9% target and 80% split. At $25K it also offers an 11% target for $21 less, or a 70% split for $10 less / 90% for $52 more. The selector base-price matrix matches the marketing page list prices. Fees for the 11% and alternate split options are only captured at $25K.', 'Confirm full size-specific pricing for the 11% target and 70%/90% split variants, and verify platform availability by account size and residence.'),
  ('fast-static-1-step', 'The live selector defaults to 10% target, 6% static max loss, 3% daily loss, 80% split, and bi-weekly rewards. It offers 70%/80%/90% split choices. Selector base prices at $50K/$100K are $389/$639, versus the challenge page list prices $379/$599.', 'Provider price discrepancy remains open: current selector is $10 higher at $50K and $40 higher at $100K than the published challenge page. Confirm which price a buyer pays and map platforms by size/residence.'),
  ('classic-2-step', 'The live selector defaults to 8%/5% phase targets, 8% max loss, 4% daily loss, and 80% split. It offers Phase 1 target 8% or 10%, max loss 8% or 10%, daily loss 3% or 4%, and 70%/80%/90% split. At $25K the 10% target costs $21 less, 10% max loss adds $52, 3% daily loss saves $25, and 70%/90% splits save/add $10/$52. Selector base fees at $50K/$100K are $359/$599 vs marketing list fees $349/$579.', 'Provider price discrepancy remains open: current selector is $10 higher at $50K and $20 higher at $100K than the published challenge page. Option fee deltas were captured at $25K only. Confirm prices, full variant fees, and platform availability by size/residence.'),
  ('pay-after-pass-1-step', 'The live selector currently offers $9 entry at $25K/$50K/$100K/$200K with respective activation fees $189/$329/$499/$999. It defaults to a 2% target, 6% max loss, 3% daily loss, 80% split, and on-demand rewards. At $100K the selector activation is $499, while the Forex rules article lists $489. The selector displays MT5, TradeLocker, and cTrader at $25K.', 'Verify the $100K activation fee discrepancy ($499 selector vs $489 Help Center), campaign expiry, and platform availability for each size and residence. The Help Center page still omits the $200K configuration.'),
  ('instant-forex', 'Current selector base prices match the regular/list values on the Instant pricing page: $138/$218/$338/$558/$878 for $6K/$15K/$25K/$50K/$100K. Promoted amounts are listed separately in marketing material. The product starts at 70% reward split with increases to 90% under the published policy.', 'Confirm current promotion eligibility, complete platform-by-size availability, and any undisclosed Forex execution fees before publication.'),
  ('instant-pro-forex', 'Current selector base prices match the regular/list values on the Instant Pro pricing page: $109/$219/$439/$839 for $3K/$6K/$15K/$25K. Promoted amounts are listed separately in marketing material. The product starts at 60% reward split with increases to 90% under the published policy.', 'Confirm current promotion eligibility, complete platform-by-size availability, and any undisclosed Forex execution fees before publication.')
) as detail(program_slug, price_configuration, review_note) on true
where f.slug = 'for-traders' and p.firm_id = f.id and p.slug = detail.program_slug;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://app.fortraders.com/trading/new-challenge', 'For Traders live order selector, Forex', 'Interactive first-party selector checked 2026-09-30 across six currently visible Forex offer types. Captures base/list fees, selected rule options, Pay After Pass activation prices and visible platform options. No sign-in, payment or account creation was attempted. Several price differences with official marketing/Help Center tables are recorded without choosing a silent winner.'
from bullish_banana.firms f
where f.slug = 'for-traders'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://app.fortraders.com/trading/new-challenge');

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object('promotion_note', promo.note),
    updated_at = now()
from bullish_banana.firms f
join (values
  ('fast-1-step', 'The challenge page shows a TRADE15 promotion alongside lower-than-list prices: $6K $41 (list $49), $15K $84 ($99), $25K $152 ($179), $50K $211 ($249), $100K $398 ($469). The interactive selector shows list prices; the promo is not auto-applied there. Capture date 2026-09-30.'),
  ('fast-static-1-step', 'The challenge page shows a TRADE15 promotion: $6K $58 (list $69), $15K $118 ($139), $25K $194 ($229), $50K $322 (page list $379), $100K $509 (page list $599). The selector currently lists $389/$639 at $50K/$100K, so promo applicability at those sizes is unresolved. Capture date 2026-09-30.'),
  ('classic-2-step', 'The challenge page shows a TRADE15 promotion: $6K $56 (list $67), $15K $99 ($117), $25K $186 ($219), $50K $296 (page list $349), $100K $492 (page list $579). The selector currently lists $359/$599 at $50K/$100K, so promo applicability at those sizes is unresolved. Capture date 2026-09-30.'),
  ('pay-after-pass-1-step', 'Current selector displays a temporary $9 entry fee at each shown size; the promotion post gives no expiry date. Separate activation fees apply after passing.'),
  ('instant-forex', 'Pricing page shows current promo fees $69/$109/$169/$279/$439 for $6K/$15K/$25K/$50K/$100K, versus selector/list fees $138/$218/$338/$558/$878. Confirm the discount and its duration at checkout.'),
  ('instant-pro-forex', 'Pricing page shows current promo fees $92/$186/$373/$713 for $3K/$6K/$15K/$25K, versus selector/list fees $109/$219/$439/$839. Confirm the discount and its duration at checkout.')
) as promo(program_slug, note) on true
where f.slug = 'for-traders' and p.firm_id = f.id and p.slug = promo.program_slug;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object('platforms_note', platform.note),
    updated_at = now()
from bullish_banana.firms f
join (values
  ('fast-1-step', 'The live selector showed MetaTrader 5, TradeLocker, and cTrader at $25K; cTrader was absent at $6K and visible again at $25K. Availability changes by account size; a full matrix by size and residence is not yet captured.'),
  ('fast-static-1-step', 'The live selector exposes platform selection, but platform availability by account size and residence was not fully enumerated.'),
  ('classic-2-step', 'The live selector showed MetaTrader 5, TradeLocker, and cTrader for a $25K selection. A complete map by account size and residence is not yet captured.'),
  ('pay-after-pass-1-step', 'The live selector showed MetaTrader 5, TradeLocker, and cTrader for a $25K selection. Availability at other sizes and by residence is unverified.'),
  ('instant-forex', 'The live selector exposes platform selection, but its available platforms by Instant size and residence were not fully enumerated.'),
  ('instant-pro-forex', 'The live selector exposes platform selection, but its available platforms by Instant Pro size and residence were not fully enumerated.')
) as platform(program_slug, note) on true
where f.slug = 'for-traders' and p.firm_id = f.id and p.slug = platform.program_slug;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://app.fortraders.com/trading/new-challenge', 'For Traders live Forex order selector', 'Interactive configuration and size-specific fee evidence captured 2026-09-30. Selector prices are separated from promotional marketing-page figures; current records remain in review where sources conflict or configuration matrices are incomplete.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'for-traders'
  and p.slug in ('fast-1-step','fast-static-1-step','classic-2-step','pay-after-pass-1-step','instant-forex','instant-pro-forex')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://app.fortraders.com/trading/new-challenge');
