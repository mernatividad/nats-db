-- Hantec Trader current Forex instrument-level product specification review.
-- Captured 2026-09-30; do not publish a firm-wide single leverage figure as
-- applying uniformly to every FX instrument. This migration is staged only.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'forex_leverage',
      'The asset-class FAQ says Forex leverage is 1:50, but the current instrument specification lists USDCHF.h at 1:33 while seven other page-1 Forex pairs are 1:50. Use the instrument schedule for pair-level limits; do not treat 1:50 as uniform across every Forex symbol.',
      'forex_instrument_specification',
      'The official instrument table reviewed 2026-09-30 shows pair-level limits rather than one uniform Forex leverage: page 1 lists EURUSD.h, GBPUSD.h, USDJPY.h, AUDUSD.h, NZDUSD.h, USDCAD.h, and AUDCAD.h at 1:50, while USDCHF.h is 1:33. The same listed pairs show $5 USD/lot commission. These are observed rows from page 1 of 5; do not infer the limits or commissions for unreviewed instruments or assume this page establishes each program/platform mapping.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'hantec-trader';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'instrument_leverage_note',
      'The firm-level instrument specification reviewed 2026-09-30 lists USDCHF.h at 1:33, while the other listed FX pairs on page 1 of 5 show 1:50. Its listed pairs show $5 USD/lot commission. Pair coverage and applicability to this specific program/account remain to be confirmed; top-level max_leverage is not an instrument-by-instrument schedule.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'hantec-trader'
  and p.slug in ('express','enhanced','enhancedx','endurance','instant-funding','instant-lite','instant24');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes, captured_at)
select f.id,
       'https://htrader.hmarkets.com/product-specifications/',
       'Forex instrument leverage and commission recheck — 2026-09-30',
       'Current first-party instrument specification lists page 1 of 5: EURUSD.h, GBPUSD.h, USDJPY.h, AUDUSD.h, NZDUSD.h, USDCAD.h, AUDCAD.h at 1:50, and USDCHF.h at 1:33; listed pairs show $5 USD/lot commission. This source does not establish the remaining pages or exact program/platform applicability.',
       '2026-09-29 21:19:41+00'::timestamptz
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://htrader.hmarkets.com/product-specifications/'
      and s.source_label = 'Forex instrument leverage and commission recheck — 2026-09-30'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://htrader.hmarkets.com/product-specifications/',
       'Forex instrument leverage and commission recheck — 2026-09-30',
       'Firm-level instrument specification reviewed 2026-09-30: page 1 of 5 shows USDCHF.h at 1:33, other listed FX pairs at 1:50, and $5 USD/lot commission for the listed pairs. Exact applicability to this program/account is not established; do not present this as a complete instrument schedule.',
       '2026-09-29 21:19:41+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express','enhanced','enhancedx','endurance','instant-funding','instant-lite','instant24')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://htrader.hmarkets.com/product-specifications/'
      and s.source_label = 'Forex instrument leverage and commission recheck — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id,
       '2026-09-29 21:19:41+00'::timestamptz,
       'Reviewed current official instrument specifications 2026-09-30. Pair-level Forex limits differ: USDCHF.h is 1:33 while the other listed page-1 pairs are 1:50; displayed listed-pair commission is $5 USD/lot. Only page 1 of 5 is represented and program/account applicability remains unresolved, so keep profile in_review.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.firm_id = f.id
      and v.verified_at = '2026-09-29 21:19:41+00'::timestamptz
      and v.notes like 'Reviewed current official instrument specifications 2026-09-30.%'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-29 21:19:41+00'::timestamptz,
       'Reviewed current official instrument specifications 2026-09-30. USDCHF.h is 1:33 while other listed page-1 Forex pairs are 1:50; displayed listed-pair commission is $5 USD/lot. Only page 1 of 5 is represented and applicability to this exact program/account is unconfirmed; keep program in_review pending a complete instrument and platform map.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express','enhanced','enhancedx','endurance','instant-funding','instant-lite','instant24')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-29 21:19:41+00'::timestamptz
      and v.notes like 'Reviewed current official instrument specifications 2026-09-30.%'
  );
