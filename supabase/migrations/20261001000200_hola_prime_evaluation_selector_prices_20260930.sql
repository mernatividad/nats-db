-- Refresh current Prime evaluation selector fee schedules from official product-page controls.
-- Captured 2026-09-30 with MT5, Bi-Weekly @80%, no add-ons; order/checkout was not submitted.
-- Coupon/current display values remain distinct from struck-through list prices.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs
set commercial_details = jsonb_set(
  jsonb_set(
    coalesce(commercial_details, '{}'::jsonb),
    '{account_size_prices}',
    '[
      {"account_size":2000,"fee":17,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown."},
      {"account_size":5000,"fee":47.2,"list_fee":59,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":10000,"fee":87.2,"list_fee":109,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":25000,"fee":183.2,"list_fee":229,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":50000,"fee":307.2,"list_fee":384,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":100000,"fee":544.8,"list_fee":681,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":200000,"fee":1199,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown."}
    ]'::jsonb,
    true
  ),
  '{account_size_price_note}',
  to_jsonb('Seven prices were read from the official 2-Step Pro selector on 2026-09-30 with MT5 and Bi-Weekly @80%; no add-ons were selected and no checkout/order was submitted. WELCOME20 and struck-through list prices were visible at $5K-$100K. The $2K and $200K cards showed one price only; do not infer a discount or undisplayed list fee. Other payout/platform/add-on or checkout settings may change price.'::text),
  true
),
updated_at = now()
from bullish_banana.firms
where firms.id = programs.firm_id
  and firms.slug = 'hola-prime'
  and programs.slug = '2-step-pro';

update bullish_banana.programs
set commercial_details = jsonb_set(
  jsonb_set(
    coalesce(commercial_details, '{}'::jsonb),
    '{account_size_prices}',
    '[
      {"account_size":2000,"fee":14,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown."},
      {"account_size":5000,"fee":39.2,"list_fee":49,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":10000,"fee":71.2,"list_fee":89,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":25000,"fee":172,"list_fee":215,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":50000,"fee":263.2,"list_fee":329,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":100000,"fee":463.2,"list_fee":579,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":200000,"fee":1049,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown."}
    ]'::jsonb,
    true
  ),
  '{account_size_price_note}',
  to_jsonb('Seven prices were read from the official Prime Challenge selector on 2026-09-30 with 1-Step Prime selected, MT5, Bi-Weekly @80%, and no add-ons; no checkout/order was submitted. WELCOME20 and struck-through list prices were visible at $5K-$100K. The $2K and $200K cards showed one price only; do not infer a discount or undisplayed list fee. Other payout/platform/add-on or checkout settings may change price.'::text),
  true
),
updated_at = now()
from bullish_banana.firms
where firms.id = programs.firm_id
  and firms.slug = 'hola-prime'
  and programs.slug = '1-step-prime';

update bullish_banana.programs
set commercial_details = jsonb_set(
  jsonb_set(
    coalesce(commercial_details, '{}'::jsonb),
    '{account_size_prices}',
    '[
      {"account_size":2000,"fee":9,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown."},
      {"account_size":5000,"fee":31.2,"list_fee":39,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":10000,"fee":55.2,"list_fee":69,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":25000,"fee":143.2,"list_fee":179,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":50000,"fee":255.2,"list_fee":319,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":100000,"fee":455.2,"list_fee":569,"currency":"USD","price_context":"Displayed with WELCOME20; Bi-Weekly @80%, MT5, no add-ons."},
      {"account_size":200000,"fee":1079,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown."}
    ]'::jsonb,
    true
  ),
  '{account_size_price_note}',
  to_jsonb('Seven prices were read from the official Prime Challenge selector on 2026-09-30 with 2-Step Prime selected, MT5, Bi-Weekly @80%, and no add-ons; no checkout/order was submitted. WELCOME20 and struck-through list prices were visible at $5K-$100K. The $2K and $200K cards showed one price only; do not infer a discount or undisplayed list fee. Other payout/platform/add-on or checkout settings may change price.'::text),
  true
),
updated_at = now()
from bullish_banana.firms
where firms.id = programs.firm_id
  and firms.slug = 'hola-prime'
  and programs.slug = '2-step-prime';

update bullish_banana.programs
set account_sizes = '[2000,5000,10000,25000,50000,100000]'::jsonb,
commercial_details = jsonb_set(
  jsonb_set(
    coalesce(commercial_details, '{}'::jsonb),
    '{account_size_prices}',
    '[
      {"account_size":2000,"fee":49,"currency":"USD","price_context":"Displayed selector price; no struck-through comparison price shown. Same displayed amount under Bi-Weekly @80% and Bi-Weekly @90%."},
      {"account_size":5000,"fee":87.2,"list_fee":109,"currency":"USD","price_context":"Displayed with WELCOME20; MT5, no add-ons. Same displayed amount under Bi-Weekly @80% and Bi-Weekly @90%."},
      {"account_size":10000,"fee":159.2,"list_fee":199,"currency":"USD","price_context":"Displayed with WELCOME20; MT5, no add-ons. Same displayed amount under Bi-Weekly @80% and Bi-Weekly @90%."},
      {"account_size":25000,"fee":351.2,"list_fee":439,"currency":"USD","price_context":"Displayed with WELCOME20; MT5, no add-ons. Same displayed amount under Bi-Weekly @80% and Bi-Weekly @90%."},
      {"account_size":50000,"fee":663.2,"list_fee":829,"currency":"USD","price_context":"Displayed with WELCOME20; MT5, no add-ons. Same displayed amount under Bi-Weekly @80% and Bi-Weekly @90%."},
      {"account_size":100000,"fee":1007.2,"list_fee":1259,"currency":"USD","price_context":"Displayed with WELCOME20; MT5, no add-ons. Same displayed amount under Bi-Weekly @80% and Bi-Weekly @90%."}
    ]'::jsonb,
    true
  ),
  '{account_size_price_note}',
  to_jsonb('Six Direct selector sizes and prices were read on 2026-09-30 with MT5 and no add-ons; no checkout/order was submitted. The same displayed matrix was observed with both Bi-Weekly @80% and Bi-Weekly @90% selected. WELCOME20 and struck-through list prices were visible at $5K-$100K; the $2K card showed one amount only. The purchase selector includes $2K, a size omitted in the prior staged account_sizes value. Other platform/add-on or checkout settings may change price.'::text),
  true
),
updated_at = now()
from bullish_banana.firms
where firms.id = programs.firm_id
  and firms.slug = 'hola-prime'
  and programs.slug = 'direct-forex';

update bullish_banana.sources
set notes = 'Official Pro page identifies 2-Step Pro and $5K-$200K size choices. Selector reviewed 2026-09-30 with MT5 and Bi-Weekly @80%, no add-ons: displayed USD prices $17/$47.20/$87.20/$183.20/$307.20/$544.80/$1,199 at $2K/$5K/$10K/$25K/$50K/$100K/$200K. WELCOME20 and list prices $59/$109/$229/$384/$681 were shown for $5K-$100K; the $2K/$200K cards showed no comparison price. No checkout submitted; other configurations may change price.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where programs.id = sources.program_id
  and firms.slug = 'hola-prime'
  and programs.slug = '2-step-pro'
  and sources.source_url = 'https://holaprime.com/forex/pro-challenge/';

update bullish_banana.sources
set notes = case programs.slug
  when '1-step-prime' then 'Official Prime Challenge page lists 1-Step Prime. Selector reviewed 2026-09-30 with 1-Step Prime selected, MT5 and Bi-Weekly @80%, no add-ons: displayed USD prices $14/$39.20/$71.20/$172/$263.20/$463.20/$1,049 at $2K/$5K/$10K/$25K/$50K/$100K/$200K. WELCOME20 and list prices $49/$89/$215/$329/$579 were shown for $5K-$100K; the $2K/$200K cards showed no comparison price. No checkout submitted; other configurations may change price.'
  when '2-step-prime' then 'Official Prime Challenge page lists 2-Step Prime. Selector reviewed 2026-09-30 with 2-Step Prime selected, MT5 and Bi-Weekly @80%, no add-ons: displayed USD prices $9/$31.20/$55.20/$143.20/$255.20/$455.20/$1,079 at $2K/$5K/$10K/$25K/$50K/$100K/$200K. WELCOME20 and list prices $39/$69/$179/$319/$569 were shown for $5K-$100K; the $2K/$200K cards showed no comparison price. No checkout submitted; other configurations may change price.'
end
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where programs.id = sources.program_id
  and firms.slug = 'hola-prime'
  and programs.slug in ('1-step-prime', '2-step-prime')
  and sources.source_url = 'https://holaprime.com/forex/prime-challenge/';

update bullish_banana.sources
set notes = 'Official Direct page reviewed 2026-09-30. The purchase selector offers $2K/$5K/$10K/$25K/$50K/$100K (correcting the older staged size list that omitted $2K). With MT5 and no add-ons, prices displayed as $49/$87.20/$159.20/$351.20/$663.20/$1,007.20; WELCOME20 and list prices $109/$199/$439/$829/$1,259 were visible at $5K-$100K, while $2K showed no comparison price. The same amounts appeared after selecting Bi-Weekly @80% and Bi-Weekly @90%. No checkout submitted; other configurations may change price.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where programs.id = sources.program_id
  and firms.slug = 'hola-prime'
  and programs.slug = 'direct-forex'
  and sources.source_url = 'https://holaprime.com/forex/direct-account/';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Read-only official 2-Step Pro selector check on 2026-09-30: seven-size displayed fee ladder captured for MT5 and Bi-Weekly @80%, no add-ons; WELCOME20/list-price pairs are retained separately where visibly shown. $2K and $200K showed one amount only. No order was submitted; see commercial_details for context.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'hola-prime'
  and programs.slug = '2-step-pro';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), case programs.slug
  when '1-step-prime' then 'Read-only official 1-Step Prime selector check on 2026-09-30: seven-size displayed fee ladder captured for MT5 and Bi-Weekly @80%, no add-ons; WELCOME20/list-price pairs are retained separately where visibly shown. $2K and $200K showed one amount only. No order was submitted; see commercial_details for context.'
  when '2-step-prime' then 'Read-only official 2-Step Prime selector check on 2026-09-30: seven-size displayed fee ladder captured for MT5 and Bi-Weekly @80%, no add-ons; WELCOME20/list-price pairs are retained separately where visibly shown. $2K and $200K showed one amount only. No order was submitted; see commercial_details for context.'
end
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'hola-prime'
  and programs.slug in ('1-step-prime', '2-step-prime');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Read-only official Direct Account selector check on 2026-09-30: six account sizes including $2K and displayed fee matrix captured with MT5/no add-ons. The same prices were observed with Bi-Weekly @80% and Bi-Weekly @90% selected. WELCOME20/list-price pairs were visible at $5K-$100K; $2K showed one amount. No order was submitted; see commercial_details for context.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'hola-prime'
  and programs.slug = 'direct-forex';
