-- Hantec Trader Forex evaluation base-price matrix recheck, 2026-09-30.
-- Official program-page price selections were re-read through agent-reach Exa
-- page results and match the prior selector capture. No checkout was completed;
-- promotions/add-ons remain separate and all programs stay in_review.
set search_path = bullish_banana, extensions, public;

with price_matrices(program_slug, page_url, display_name, price_rows) as (
  values
    (
      'express',
      'https://htrader.hmarkets.com/programs/express-challenge/',
      'Express',
      '[{"account_size":2000,"fee":39,"currency":"USD"},{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":319,"currency":"USD"},{"account_size":100000,"fee":529,"currency":"USD"},{"account_size":200000,"fee":999,"currency":"USD"}]'::jsonb
    ),
    (
      'enhanced',
      'https://htrader.hmarkets.com/programs/enhanced-challenge/',
      'Enhanced',
      '[{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":359,"currency":"USD"},{"account_size":100000,"fee":599,"currency":"USD"},{"account_size":200000,"fee":1169,"currency":"USD"}]'::jsonb
    ),
    (
      'enhancedx',
      'https://htrader.hmarkets.com/programs/enhancedx/',
      'EnhancedX',
      '[{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":359,"currency":"USD"},{"account_size":100000,"fee":599,"currency":"USD"},{"account_size":200000,"fee":1169,"currency":"USD"}]'::jsonb
    ),
    (
      'endurance',
      'https://htrader.hmarkets.com/programs/endurance/',
      'Endurance',
      '[{"account_size":5000,"fee":29,"currency":"USD"},{"account_size":10000,"fee":59,"currency":"USD"},{"account_size":25000,"fee":109,"currency":"USD"},{"account_size":50000,"fee":189,"currency":"USD"},{"account_size":100000,"fee":299,"currency":"USD"},{"account_size":200000,"fee":499,"currency":"USD"}]'::jsonb
    )
)
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb)
      || jsonb_build_object(
        'account_size_prices', m.price_rows,
        'pricing_capture', 'Official Hantec Trader program-page price values rechecked 2026-09-30; values match the previous selector capture. Coupon banners were visible separately. No checkout completed; verify selected options and any add-ons at checkout.',
        'price_matrix_status', 'Every currently listed evaluation size has a source-backed USD list-price row, rechecked from the official program page on 2026-09-30.'
      ),
    updated_at = now()
from price_matrices m
join bullish_banana.firms f on f.slug = 'hantec-trader'
where p.firm_id = f.id
  and p.slug = m.program_slug;

with price_matrices(program_slug, page_url, display_name, price_rows) as (
  values
    ('express', 'https://htrader.hmarkets.com/programs/express-challenge/', 'Express', '[{"account_size":2000,"fee":39,"currency":"USD"},{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":319,"currency":"USD"},{"account_size":100000,"fee":529,"currency":"USD"},{"account_size":200000,"fee":999,"currency":"USD"}]'::jsonb),
    ('enhanced', 'https://htrader.hmarkets.com/programs/enhanced-challenge/', 'Enhanced', '[{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":359,"currency":"USD"},{"account_size":100000,"fee":599,"currency":"USD"},{"account_size":200000,"fee":1169,"currency":"USD"}]'::jsonb),
    ('enhancedx', 'https://htrader.hmarkets.com/programs/enhancedx/', 'EnhancedX', '[{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":359,"currency":"USD"},{"account_size":100000,"fee":599,"currency":"USD"},{"account_size":200000,"fee":1169,"currency":"USD"}]'::jsonb),
    ('endurance', 'https://htrader.hmarkets.com/programs/endurance/', 'Endurance', '[{"account_size":5000,"fee":29,"currency":"USD"},{"account_size":10000,"fee":59,"currency":"USD"},{"account_size":25000,"fee":109,"currency":"USD"},{"account_size":50000,"fee":189,"currency":"USD"},{"account_size":100000,"fee":299,"currency":"USD"},{"account_size":200000,"fee":499,"currency":"USD"}]'::jsonb)
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       m.page_url,
       m.display_name || ' official price matrix recheck — 2026-09-30',
       'Official program page price values rechecked 2026-09-30. USD list-price matrix by account size: ' || m.price_rows::text || '. Values match the previous official selector capture. Coupons and optional add-ons are separate; no checkout was completed, so selected configuration totals must be rechecked at checkout.'
from price_matrices m
join bullish_banana.firms f on f.slug = 'hantec-trader'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = m.program_slug
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id
    and s.source_url = m.page_url
    and s.source_label = m.display_name || ' official price matrix recheck — 2026-09-30'
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30'::timestamptz,
       'Official product-page USD base-fee matrix rechecked 2026-09-30 for every currently listed evaluation size; values match the prior selector capture. Coupons/add-ons and selected checkout totals remain unverified. Program stays in_review for separate platform, agreement and eligibility mapping questions.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30'::timestamptz
      and v.notes like 'Official product-page USD base-fee matrix rechecked 2026-09-30%'
  );
