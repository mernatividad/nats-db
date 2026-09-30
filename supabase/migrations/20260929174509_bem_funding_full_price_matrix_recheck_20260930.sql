set search_path = bullish_banana, extensions, public;

-- Full public-selector base-fee matrices verified by selecting every listed size
-- and each visible platform (MT5 and cTrader) on 2026-09-30. No checkout completed.

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "selector_fee_matrix_recheck_2026_09_30": {
    "currency": "USD",
    "platforms_checked": ["MT5", "cTrader"],
    "platform_prices_matched_at_each_size": true,
    "one_step_sizes_usd": [5000, 10000, 25000, 50000, 100000, 200000],
    "two_step_sizes_usd": [5000, 10000, 25000, 50000, 100000],
    "limitations": "Selector-displayed base fees only; no checkout completed. Promotion discounts are time-limited and excluded from base-fee matrix. Keep offers in_review pending remaining legal, eligibility, and program-term checks."
  }
}'::jsonb,
updated_at = now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='bem-funding';

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
  'fees', x.fee_summary,
  'supported_platforms_by_selector', '["MT5","cTrader"]'::jsonb,
  'selector_fee_matrix_2026_09_30', x.matrix::jsonb
), updated_at = now()
from bullish_banana.firms f
join (values
  ('bem-one', 'USD base fee by account size; verified identical on MT5 and cTrader. Promo excluded.', '{"currency":"USD","platforms_checked":["MT5","cTrader"],"platform_prices_matched_at_each_size":true,"account_size_fee_usd":{"5000":47,"10000":89,"25000":194,"50000":285,"100000":520,"200000":790},"displayed_promotion_percent":30,"capture":"All six currently listed One-Step sizes selected on both platform options in the live homepage selector on 2026-09-30. No checkout completed."}'),
  ('bem-one-only', 'USD base fee by account size; verified identical on MT5 and cTrader. Promo excluded.', '{"currency":"USD","platforms_checked":["MT5","cTrader"],"platform_prices_matched_at_each_size":true,"account_size_fee_usd":{"5000":40,"10000":90,"25000":180,"50000":270,"100000":460,"200000":750},"displayed_promotion_percent":40,"capture":"All six currently listed One-Step sizes selected on both platform options in the live homepage selector on 2026-09-30. No checkout completed."}'),
  ('bem-classic-normal', 'USD base fee by account size; verified identical on MT5 and cTrader. Promo excluded.', '{"currency":"USD","platforms_checked":["MT5","cTrader"],"platform_prices_matched_at_each_size":true,"account_size_fee_usd":{"5000":39,"10000":99,"25000":211,"50000":321,"100000":519},"displayed_promotion_percent":20,"capture":"All five currently listed Two-Step sizes selected on both platform options in the live homepage selector on 2026-09-30. No checkout completed."}'),
  ('bem-classic-swing', 'USD base fee by account size; verified identical on MT5 and cTrader. Promo excluded.', '{"currency":"USD","platforms_checked":["MT5","cTrader"],"platform_prices_matched_at_each_size":true,"account_size_fee_usd":{"5000":69,"10000":155,"25000":296,"50000":447,"100000":890},"displayed_promotion_percent":5,"capture":"All five currently listed Two-Step sizes selected on both platform options in the live homepage selector on 2026-09-30. No checkout completed."}')
) as x(program_slug, fee_summary, matrix) on true
where p.firm_id=f.id and f.slug='bem-funding' and p.slug=x.program_slug;

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,'https://bemfunding.com/','Live size and platform fee matrix — 2026-09-30',
       'All current One-Step sizes ($5K, $10K, $25K, $50K, $100K, $200K) and Two-Step sizes ($5K, $10K, $25K, $50K, $100K) were selected for all four offers on both visible platform choices, MT5 and cTrader. Base fees matched across platforms at each size. The page showed separate limited-offer discounts (BEM One 30%, One Only 40%, Classic Normal 20%, Classic Swing 5%) and advertised code MT5LIVE; discounts are not included in base fees. No checkout completed. Offers remain in review pending other source, legal and eligibility checks.'
from bullish_banana.firms f where f.slug='bem-funding'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url='https://bemfunding.com/' and s.source_label='Live size and platform fee matrix — 2026-09-30');

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,'https://bemfunding.com/','Live selector fee matrix — 2026-09-30',x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('bem-one','Base USD fees by size: $5K $47; $10K $89; $25K $194; $50K $285; $100K $520; $200K $790. Verified on MT5 and cTrader; base prices matched. Current selector separately showed a 30% discount. No checkout completed.'),
 ('bem-one-only','Base USD fees by size: $5K $40; $10K $90; $25K $180; $50K $270; $100K $460; $200K $750. Verified on MT5 and cTrader; base prices matched. Current selector separately showed a 40% discount. No checkout completed.'),
 ('bem-classic-normal','Base USD fees by size: $5K $39; $10K $99; $25K $211; $50K $321; $100K $519. Verified on MT5 and cTrader; base prices matched. Current selector separately showed a 20% discount. No checkout completed.'),
 ('bem-classic-swing','Base USD fees by size: $5K $69; $10K $155; $25K $296; $50K $447; $100K $890. Verified on MT5 and cTrader; base prices matched. Current selector separately showed a 5% discount. No checkout completed.')
) as x(program_slug,notes) on x.program_slug=p.slug
where f.slug='bem-funding'
and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url='https://bemfunding.com/' and s.source_label='Live selector fee matrix — 2026-09-30');

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),
       'Full visible size/fee matrix rechecked on 2026-09-30 across both visible platform options for all four offers. Base fees matched across platforms. Complete fee matrices are staged. Firm and offers remain in_review pending program-term, legal, jurisdiction, eligibility, and remaining publication checks.'
from bullish_banana.firms f where f.slug='bem-funding';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),
       'All account sizes currently listed for this offer and both visible platforms were selected in the live selector on 2026-09-30; base fees matched across platforms. The complete USD base-fee matrix is staged separately from volatile discounts. Program remains in_review pending remaining terms, eligibility and source checks.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='bem-funding'
and p.slug in ('bem-one','bem-one-only','bem-classic-normal','bem-classic-swing');
