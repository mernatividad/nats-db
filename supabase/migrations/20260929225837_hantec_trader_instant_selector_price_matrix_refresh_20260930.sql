-- Hantec Trader Instant USD selector matrices, captured 2026-09-30.
-- The live official selector was interacted with in Playwright; each visible
-- account size was selected and its list price recorded. DROP50 was visible as
-- a 50% offer for Instant Funding and Instant Lite, excluding Instant24; no
-- expiry date was displayed. The offer is not folded into the base-price rows.
set search_path = bullish_banana, extensions, public;

with price_matrices(program_slug, display_name, price_rows) as (
  values
    (
      'instant24',
      'Instant24',
      '[{"account_size":2000,"fee":13,"currency":"USD"},{"account_size":5000,"fee":17,"currency":"USD"},{"account_size":10000,"fee":38,"currency":"USD"},{"account_size":25000,"fee":89,"currency":"USD"},{"account_size":50000,"fee":190,"currency":"USD"},{"account_size":100000,"fee":299,"currency":"USD"}]'::jsonb
    ),
    (
      'instant-lite',
      'Instant Lite',
      '[{"account_size":1000,"fee":19,"currency":"USD"},{"account_size":2000,"fee":39,"currency":"USD"},{"account_size":5000,"fee":79,"currency":"USD"},{"account_size":10000,"fee":129,"currency":"USD"},{"account_size":25000,"fee":239,"currency":"USD"},{"account_size":50000,"fee":369,"currency":"USD"},{"account_size":100000,"fee":699,"currency":"USD"}]'::jsonb
    ),
    (
      'instant-funding',
      'Instant Funding',
      '[{"account_size":1000,"fee":43,"currency":"USD"},{"account_size":2000,"fee":86,"currency":"USD"},{"account_size":5000,"fee":214,"currency":"USD"},{"account_size":10000,"fee":428,"currency":"USD"},{"account_size":25000,"fee":1069,"currency":"USD"},{"account_size":50000,"fee":2139,"currency":"USD"}]'::jsonb
    )
)
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb)
      || jsonb_build_object(
        'account_size_prices', m.price_rows,
        'pricing_capture', 'Official Hantec Trader homepage selector in USD; each currently displayed size was selected and its list fee recorded on 2026-09-30. DROP50 showed 50% off Instant Funding and Instant Lite but excluded Instant24; no expiry date was shown. Base-fee matrix excludes this temporary promotion. No purchase/checkout was completed; verify final selected checkout price and promotion validity before release.',
        'price_matrix_status', 'Every currently displayed Instant account size has a selector-captured USD list-price row, rechecked 2026-09-30.'
      ),
    updated_at = now()
from price_matrices m
join bullish_banana.firms f on f.slug = 'hantec-trader'
where p.firm_id = f.id
  and p.slug = m.program_slug;

with price_matrices(program_slug, display_name, price_rows) as (
  values
    ('instant24', 'Instant24', '[{"account_size":2000,"fee":13,"currency":"USD"},{"account_size":5000,"fee":17,"currency":"USD"},{"account_size":10000,"fee":38,"currency":"USD"},{"account_size":25000,"fee":89,"currency":"USD"},{"account_size":50000,"fee":190,"currency":"USD"},{"account_size":100000,"fee":299,"currency":"USD"}]'::jsonb),
    ('instant-lite', 'Instant Lite', '[{"account_size":1000,"fee":19,"currency":"USD"},{"account_size":2000,"fee":39,"currency":"USD"},{"account_size":5000,"fee":79,"currency":"USD"},{"account_size":10000,"fee":129,"currency":"USD"},{"account_size":25000,"fee":239,"currency":"USD"},{"account_size":50000,"fee":369,"currency":"USD"},{"account_size":100000,"fee":699,"currency":"USD"}]'::jsonb),
    ('instant-funding', 'Instant Funding', '[{"account_size":1000,"fee":43,"currency":"USD"},{"account_size":2000,"fee":86,"currency":"USD"},{"account_size":5000,"fee":214,"currency":"USD"},{"account_size":10000,"fee":428,"currency":"USD"},{"account_size":25000,"fee":1069,"currency":"USD"},{"account_size":50000,"fee":2139,"currency":"USD"}]'::jsonb)
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://htrader.hmarkets.com/jp/',
       m.display_name || ' live selector matrix — 2026-09-30',
       'Official Hantec Trader homepage selector was interacted with on 2026-09-30. All listed USD account sizes and base prices: ' || m.price_rows::text || '. DROP50 was shown as a separate 50% promotion for Instant Funding and Instant Lite, excluding Instant24; no expiry was displayed. Discount excluded from base prices; final checkout and promotion validity require release-time confirmation.'
from price_matrices m
join bullish_banana.firms f on f.slug = 'hantec-trader'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = m.program_slug
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id
    and s.source_url = 'https://htrader.hmarkets.com/jp/'
    and s.source_label = m.display_name || ' live selector matrix — 2026-09-30'
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30'::timestamptz,
       'Every currently displayed USD size and base fee was captured by selecting the offer in the official Hantec Trader live selector on 2026-09-30. DROP50 was a separate 50% promotion for Instant Funding and Instant Lite, not Instant24; its expiration was not visible. Base prices remain separate from the promotion. Program stays in_review pending the remaining rule, platform, account agreement and eligibility checks.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('instant24', 'instant-lite', 'instant-funding')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30'::timestamptz
      and v.notes like 'Every currently displayed USD size and base fee was captured by selecting the offer%'
  );
