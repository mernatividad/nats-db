-- Complete Hantec Trader Forex instrument schedule, 2026-09-30.
-- All five pages of the official live specification were inspected. The spread
-- values are a point-in-time snapshot. Keep the schedule firm-wide: applicability
-- to an individual challenge, account, or platform is not established here.
set search_path = bullish_banana, extensions, public;

with instrument_schedule(schedule) as (
  values ('[
    {"symbol":"EURUSD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00002,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"GBPUSD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00002,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDJPY.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.002,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"AUDUSD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00002,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"NZDUSD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00005,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDCAD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00003,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDCHF.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00001,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"AUDCAD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00011,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"AUDCHF.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00007,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"AUDJPY.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.021,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"AUDNZD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00011,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"CADCHF.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00009,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"CADJPY.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.009,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"CHFJPY.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.013,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURAUD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00012,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURCAD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00029,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURCHF.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00006,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURGBP.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00002,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURHUF.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.8526,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURJPY.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.012,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURNOK.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.01284,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURNZD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00065,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"EURPLN.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.0033,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"GBPAUD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00013,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"GBPCAD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00038,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"GBPCHF.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00008,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"GBPJPY.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.018,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"GBPNZD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00036,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"NZDCAD.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.00007,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"NZDCHF.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00009,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"NZDJPY.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.009,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDCZK.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.02836,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDHUF.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.7394,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDILS.h","contract_size":100000,"leverage":"1:20","commission_usd_per_lot":5,"spread":0.01971,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDMXN.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.0061,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDNOK.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.0121,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDPLN.h","contract_size":100000,"leverage":"1:50","commission_usd_per_lot":5,"spread":0.01,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDSEK.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.00777,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDTRY.h","contract_size":100000,"leverage":"1:5","commission_usd_per_lot":5,"spread":0.02852,"trading_hours_cet":"00:03-23:58"},
    {"symbol":"USDZAR.h","contract_size":100000,"leverage":"1:33","commission_usd_per_lot":5,"spread":0.01494,"trading_hours_cet":"00:03-23:58"}
  ]'::jsonb)
)
update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb)
      || jsonb_build_object(
        'forex_leverage', 'The current firm-wide instrument schedule lists leverage of 1:50 on most FX pairs, with pair-specific exceptions from 1:5 to 1:33. Do not present 1:50 as universal across all symbols.',
        'forex_instrument_specification', 'The full 40-symbol, five-page Forex instrument schedule was captured from the current official product-specifications page on 2026-09-30. Each row shows a 100,000 contract size, $5 USD/lot commission and 00:03-23:58 CET trading hours; leverage and point-in-time spread vary by symbol. The schedule is firm-wide and does not establish account, challenge or platform applicability.',
        'forex_instrument_schedule_verified_on', '2026-09-30',
        'forex_instrument_schedule', instrument_schedule.schedule
      ),
    updated_at = now()
from bullish_banana.firms f
cross join instrument_schedule
where fp.firm_id = f.id
  and f.slug = 'hantec-trader';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb)
      || jsonb_build_object(
        'instrument_leverage_note', 'The official firm-wide Forex instrument schedule was rechecked across all five pages on 2026-09-30 and includes 40 FX symbols with pair-specific leverage, commission, spread and trading hours. The schedule does not identify applicability to this specific program, account size or platform; see the Hantec Trader firm profile and verify the selected account terms.',
        'instrument_schedule_source_scope', 'Firm-wide product specifications; program/account/platform mapping not established.'
      ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance', 'instant-funding', 'instant-lite', 'instant24');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
       'https://htrader.hmarkets.com/jp/product-specifications/',
       'Complete Forex instrument schedule — 2026-09-30',
       'All five pages of the official Forex instrument table were inspected on 2026-09-30. Forty symbols are listed, each with a 100,000 contract size, $5 USD/lot commission and 00:03-23:58 CET trading hours; leverage ranges by symbol from 1:5 to 1:50 and displayed spreads were captured as a dated snapshot. Source is firm-wide and does not establish challenge/account/platform applicability.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://htrader.hmarkets.com/jp/product-specifications/'
      and s.source_label = 'Complete Forex instrument schedule — 2026-09-30'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://htrader.hmarkets.com/jp/product-specifications/',
       'Firm-wide Forex specification reference — 2026-09-30',
       'This source is the firm-wide 40-symbol Forex instrument schedule, not an account-specific or program-specific rule schedule. Its pair-level leverage, $5 USD/lot commission, contract size, point-in-time spreads and trading hours are recorded on the firm profile. Applicability to this program, account and platform remains unconfirmed.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance', 'instant-funding', 'instant-lite', 'instant24')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://htrader.hmarkets.com/jp/product-specifications/'
      and s.source_label = 'Firm-wide Forex specification reference — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id,
       '2026-09-30'::timestamptz,
       'All five pages of the current official Forex instrument schedule were checked 2026-09-30. Forty symbols have been captured with contract size, pair-specific leverage, commission, point-in-time spread and market hours. This is firm-wide data; program/account/platform applicability remains unconfirmed.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.firm_id = f.id
      and v.verified_at = '2026-09-30'::timestamptz
      and v.notes like 'All five pages of the current official Forex instrument schedule were checked 2026-09-30%'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30'::timestamptz,
       'The firm-wide current official Forex instrument schedule was checked across all five pages on 2026-09-30. It contains 40 pair rows. Its terms are not mapped to this specific program, selected size or platform, so retain this program-level reference as a source with explicit scope caveat and keep the program in_review pending account-specific mapping.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance', 'instant-funding', 'instant-lite', 'instant24')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30'::timestamptz
      and v.notes like 'The firm-wide current official Forex instrument schedule was checked across all five pages%'
  );
