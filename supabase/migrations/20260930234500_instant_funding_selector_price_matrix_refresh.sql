-- Capture current visible Instant Funding USD price matrices from the official
-- homepage selector variation data checked on 2026-09-30.
-- Prices are listed by size once because each visible selector configuration
-- returned the same fee across platforms and account types. ZAR prices and
-- selector-hidden product variants remain unverified; programs stay in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "current_promotion":"Official homepage displayed 30% off Clarity and Original with code IF30, no minimum spend, not valid on Evolve (captured 2026-09-30). No expiry was displayed. Keep this separate from selector list prices and confirm eligibility at checkout.",
  "pricing_capture":"Official homepage selector current variation data checked 2026-09-30. Visible USD size/fee pairs are recorded per program. Each size fee matched across the listed platform and account-type variations for the five captured models. ZAR is selectable but its price matrix was not captured; do not infer USD parity.",
  "price_configuration":"Selector options include MT5, cTrader and Match-Trader, and Commission-free / RAW Spreads account types. Captured USD variation data showed the same price for each visible size across these configurations. ZAR accounts are MT5-only per the selector; no ZAR fees were captured. Product-card size claims and hidden variation sizes can differ; only sizes exposed by the active selector are included.",
  "pricing_open_items":"Current live selector exposes other currency, product-mode, and add-on controls. This capture covers visible USD base variation fees only. ZAR matrix, full add-on fee semantics, account-agreement reconciliation, and current eligibility/restrictions still require verification."
}'::jsonb,
updated_at=now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='instant-funding';

update bullish_banana.programs p
set account_sizes = case p.slug
      when 'one-phase-pro' then '[10000,25000,50000,100000]'::jsonb
      when 'if-micro-pro' then '[5000,10000,25000,50000,100000]'::jsonb
      when 'one-phase-lite' then '[5000,10000,25000,50000,100000]'::jsonb
      else p.account_sizes
    end,
    commercial_details = p.commercial_details || jsonb_build_object(
      'account_size_prices', case p.slug
        when 'instant-funding-pro' then '[
          {"account_size":625,"fee":44,"currency":"USD"},
          {"account_size":1250,"fee":84,"currency":"USD"},
          {"account_size":2500,"fee":129,"currency":"USD"},
          {"account_size":5000,"fee":239,"currency":"USD"},
          {"account_size":10000,"fee":459,"currency":"USD"},
          {"account_size":20000,"fee":899,"currency":"USD"},
          {"account_size":40000,"fee":1849,"currency":"USD"},
          {"account_size":80000,"fee":3699,"currency":"USD"},
          {"account_size":120000,"fee":5499,"currency":"USD"}
        ]'::jsonb
        when 'if-micro-pro' then '[
          {"account_size":5000,"fee":53,"currency":"USD"},
          {"account_size":10000,"fee":99,"currency":"USD"},
          {"account_size":25000,"fee":213,"currency":"USD"},
          {"account_size":50000,"fee":399,"currency":"USD"},
          {"account_size":100000,"fee":739,"currency":"USD"}
        ]'::jsonb
        when 'one-phase-pro' then '[
          {"account_size":10000,"fee":127,"currency":"USD"},
          {"account_size":25000,"fee":205,"currency":"USD"},
          {"account_size":50000,"fee":424,"currency":"USD"},
          {"account_size":100000,"fee":746,"currency":"USD"}
        ]'::jsonb
        when 'instant-funding-lite' then '[
          {"account_size":1250,"fee":67,"currency":"USD"},
          {"account_size":2500,"fee":103,"currency":"USD"},
          {"account_size":5000,"fee":191,"currency":"USD"},
          {"account_size":10000,"fee":367,"currency":"USD"},
          {"account_size":20000,"fee":719,"currency":"USD"},
          {"account_size":40000,"fee":1479,"currency":"USD"},
          {"account_size":80000,"fee":2959,"currency":"USD"}
        ]'::jsonb
        when 'one-phase-lite' then '[
          {"account_size":5000,"fee":57,"currency":"USD"},
          {"account_size":10000,"fee":100,"currency":"USD"},
          {"account_size":25000,"fee":185,"currency":"USD"},
          {"account_size":50000,"fee":284,"currency":"USD"},
          {"account_size":100000,"fee":500,"currency":"USD"}
        ]'::jsonb
      end,
      'pricing_capture','Official selector product-variation data checked 2026-09-30. Visible USD size/fee pairs were captured for this model. For each visible size, the variation data returned the same list fee across MT5, cTrader, Match-Trader and Commission-free / RAW Spreads combinations. The IF30 offer displayed separately and is not deducted from these fees.',
      'price_configuration','The current selector exposes multiple platform and account-type options. Captured visible USD variation prices did not change across those options. ZAR is offered in the selector (MT5 only), but its fee matrix is not included because no ZAR prices were captured. Selector-hidden variation sizes are excluded.',
      'promotion_note','Official homepage displayed code IF30 for 30% off Clarity and Original, no minimum spend, not valid on Evolve on 2026-09-30. No expiry shown. Promotion is separate from the recorded USD list fees; confirm the model qualifies at checkout.',
      'source_capture_date','2026-09-30'
    ),
    updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='instant-funding'
  and p.slug in ('instant-funding-pro','if-micro-pro','one-phase-pro','instant-funding-lite','one-phase-lite');

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,'https://instantfunding.com/','Homepage selector USD price-matrix recheck — 2026-09-30',
       'Current product variation data exposed USD size/fee pairs for five Forex models. Visible selector matrix entries were compared across platform and account-type options; those fees were identical at each visible size. ZAR fees, add-on fee semantics, and selector-hidden sizes were not treated as verified. Homepage displayed code IF30 for 30% off Clarity and Original, no minimum spend, not valid on Evolve.'
from bullish_banana.firms f
where f.slug='instant-funding'
  and not exists (
    select 1 from bullish_banana.sources s where s.firm_id=f.id
      and s.source_url='https://instantfunding.com/'
      and s.source_label='Homepage selector USD price-matrix recheck — 2026-09-30'
  );

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,'https://instantfunding.com/','Visible selector USD price matrix — 2026-09-30',
       'Official homepage selector variation data captured 2026-09-30. Visible USD size/fee pairs recorded in commercial_details. Same fee was returned across active platform/account-type combinations at each captured size. IF30 promotion displayed separately; ZAR, add-ons and hidden variants are not included.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='instant-funding'
  and p.slug in ('instant-funding-pro','if-micro-pro','one-phase-pro','instant-funding-lite','one-phase-lite')
  and not exists (
    select 1 from bullish_banana.sources s where s.program_id=p.id
      and s.source_url='https://instantfunding.com/'
      and s.source_label='Visible selector USD price matrix — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),
       'Official homepage selector variation data rechecked 2026-09-30. Five model USD base-price matrices are captured for visible selector sizes, with identical values across listed platforms/account types. ZAR prices, add-on semantics, selector-hidden sizes, contracting-party reconciliation and current country eligibility remain open. Programs stay in_review.'
from bullish_banana.firms f where f.slug='instant-funding';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),
       'Visible USD size/fee matrix captured from official homepage selector product-variation data on 2026-09-30. Same list fee across active platform/account-type variants for each visible size. ZAR matrix and add-on fee semantics not captured. Program remains in_review pending full terms and eligibility verification.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='instant-funding'
  and p.slug in ('instant-funding-pro','if-micro-pro','one-phase-pro','instant-funding-lite','one-phase-lite');
