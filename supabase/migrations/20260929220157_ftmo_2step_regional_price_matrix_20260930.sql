-- Refresh FTMO 2-Step size pricing from its current Global and US offer pages.
-- Keep standard fees separate from the displayed 100K promotional prices.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set currency = 'USD',
    account_sizes = '[10000,25000,50000,100000,200000]'::jsonb,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', '[
        {"account_size":10000,"fee":89,"currency":"EUR","region":"Non-US FTMO Global"},
        {"account_size":25000,"fee":250,"currency":"EUR","region":"Non-US FTMO Global"},
        {"account_size":50000,"fee":345,"currency":"EUR","region":"Non-US FTMO Global"},
        {"account_size":100000,"fee":540,"currency":"EUR","region":"Non-US FTMO Global"},
        {"account_size":200000,"fee":1080,"currency":"EUR","region":"Non-US FTMO Global"},
        {"account_size":10000,"fee":99,"currency":"USD","region":"US FTMO affiliate"},
        {"account_size":25000,"fee":289,"currency":"USD","region":"US FTMO affiliate"},
        {"account_size":50000,"fee":399,"currency":"USD","region":"US FTMO affiliate"},
        {"account_size":100000,"fee":619,"currency":"USD","region":"US FTMO affiliate"},
        {"account_size":200000,"fee":1249,"currency":"USD","region":"US FTMO affiliate"}
      ]'::jsonb,
      'price_configuration', 'The displayed 2-Step standard fee schedule differs by program market: FTMO Global lists EUR fees and the US affiliate page lists USD fees. Account balances are denominated in USD. The applicable entity, fee currency, and final amount depend on the customer market and order flow.',
      'fee_refund_policy', 'The 2-Step fee is a one-time charge for both evaluation phases and is refunded with the first Reward under FTMO conditions. Standard schedule: Global €89/€250/€345/€540/€1,080 for $10K/$25K/$50K/$100K/$200K; US affiliate $99/$289/$399/$619/$1,249 for the same balances. The current $100K promotional prices are recorded separately from these standard fees.',
      'promotion_note', 'On 2026-09-30, FTMO Global displayed €439 against the €540 standard fee for $100K; the US affiliate page displayed $499 against the $619 standard fee for $100K. These are dated promotional observations; no expiration date was stated on the pages. Keep them separate from base fees.',
      'regional_fee_matrix_observation_2026_09_30', jsonb_build_object(
        'captured_on', '2026-09-30',
        'account_balance_currency', 'USD',
        'global_page_url', 'https://promo.ftmo.com/let-your-profits-run/',
        'global_standard_currency', 'EUR',
        'global_standard_fees', '[{"account_size":10000,"fee":89},{"account_size":25000,"fee":250},{"account_size":50000,"fee":345},{"account_size":100000,"fee":540},{"account_size":200000,"fee":1080}]'::jsonb,
        'us_page_url', 'https://promo.ftmo.com/let-your-profits-run/us/',
        'us_standard_currency', 'USD',
        'us_standard_fees', '[{"account_size":10000,"fee":99},{"account_size":25000,"fee":289},{"account_size":50000,"fee":399},{"account_size":100000,"fee":619},{"account_size":200000,"fee":1249}]'::jsonb,
        'current_promotional_prices', '[{"region":"Non-US FTMO Global","account_size":100000,"standard_fee":540,"promotional_fee":439,"currency":"EUR","expiry":"Not stated"},{"region":"US FTMO affiliate","account_size":100000,"standard_fee":619,"promotional_fee":499,"currency":"USD","expiry":"Not stated"}]'::jsonb,
        'publication_status', 'Keep the 2-Step record in_review until regional operator eligibility, checkout currency selection, and the remaining FTMO publication gaps are resolved.'
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'ftmo'
  and p.slug = 'ftmo-2-step';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       source.source_url,
       source.source_label,
       source.notes,
       '2026-09-29 22:01:57+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'ftmo'
join (values
  ('https://promo.ftmo.com/let-your-profits-run/', 'FTMO Global 2-Step size and standard fee schedule — 2026-09-30', 'The current official Global offer page lists 2-Step account balances of $10K/$25K/$50K/$100K/$200K and standard one-time EUR fees of €89/€250/€345/€540/€1,080. At $100K it also displays a current €439 price against €540; recorded separately as a promotion with no stated expiry.'),
  ('https://promo.ftmo.com/let-your-profits-run/us/', 'FTMO US 2-Step size and standard fee schedule — 2026-09-30', 'The current official US affiliate offer page lists the same five USD account balances and standard one-time USD fees of $99/$289/$399/$619/$1,249. At $100K it also displays a current $499 price against $619; recorded separately as a promotion with no stated expiry. This is the US affiliate offer, not the non-US Global operator.')
) as source(source_url, source_label, notes) on true
where p.slug = 'ftmo-2-step'
  and not exists (
    select 1 from bullish_banana.sources existing
    where existing.program_id = p.id and existing.source_url = source.source_url
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-29 22:01:57+00'::timestamptz,
       'Rechecked current FTMO Global and US affiliate 2-Step offer pages on 2026-09-30. Captured all five standard base fees in each page currency, distinguished the $100K promotional prices, and recorded the separate market/entity scopes. Keep in_review pending current country eligibility and account-type platform mapping.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'ftmo'
where p.slug = 'ftmo-2-step'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-29 22:01:57+00'::timestamptz
      and v.notes like 'Rechecked current FTMO Global and US affiliate 2-Step offer pages%'
  );
