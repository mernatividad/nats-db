-- Tradeify FX pricing/help-center refresh, captured 2026-09-30.
-- The Direct list-fee matrix changed at four sizes; apply only the current
-- official list fees and current instrument commission schedule.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
      'commissions', 'Official pricing guide updated 2026-09-30: $3 per lot per side on Forex, metals and energies; crypto (BTC and ETH) carries a 0.04% commission per side based on notional volume; indices are commission-free. Swap rates are displayed in the MT5 terminal.',
      'pricing_verification_date', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'tradeify-fx'
  and p.slug in ('daily-1-step', 'classic-2-step', 'direct-instant-funding');

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
      'account_size_prices', jsonb_build_array(
        jsonb_build_object('account_size', 5000, 'fee', 85, 'currency', 'USD'),
        jsonb_build_object('account_size', 10000, 'fee', 120, 'currency', 'USD'),
        jsonb_build_object('account_size', 25000, 'fee', 204, 'currency', 'USD'),
        jsonb_build_object('account_size', 50000, 'fee', 580, 'currency', 'USD'),
        jsonb_build_object('account_size', 100000, 'fee', 1000, 'currency', 'USD')
      ),
      'pricing_capture', 'Official Account sizes and pricing Help Center article, updated today and reviewed 2026-09-30. Current Direct list prices are $85/$120/$204/$580/$1,000 by ascending account size; temporary discounts are excluded from base fees.',
      'pricing_verification_date', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'tradeify-fx'
  and p.slug = 'direct-instant-funding';

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || jsonb_build_object(
      'commission_details', 'Official pricing guide updated 2026-09-30: $3 per lot per side on Forex, metals and energies; crypto (BTC and ETH) carries a 0.04% commission per side based on notional volume; indices are commission-free. Swap rates are displayed in the MT5 terminal.',
      'catalog_verified_at', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id
  and f.slug = 'tradeify-fx';

update bullish_banana.sources s
set notes = 'Official price matrices and instrument commissions rechecked 2026-09-30; article says updated today. Current Direct list fees are $85/$120/$204/$580/$1,000. Current commission schedule: $3/lot/side Forex, metals and energies; crypto BTC/ETH 0.04% per side by notional; indices commission-free. Swap rates are shown in MT5.'
from bullish_banana.firms f
where s.firm_id = f.id
  and s.source_url = 'https://help.tradeifyfx.co/en/articles/16975771-account-sizes-and-pricing'
  and f.slug = 'tradeify-fx';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://help.tradeifyfx.co/en/articles/16975771-account-sizes-and-pricing',
       'Tradeify FX account sizes, current list fees and commissions',
       case when p.slug = 'direct-instant-funding'
         then 'Official pricing article, marked updated today and reviewed 2026-09-30. Current Direct list fees are $85/$120/$204/$580/$1,000 for $5K/$10K/$25K/$50K/$100K; article also gives current Forex/metals/energies, crypto and index commissions.'
         else 'Official pricing article, marked updated today and reviewed 2026-09-30. Confirms this plan’s current list-fee matrix and the full current Forex/metals/energies, crypto and index commission schedule.'
       end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'tradeify-fx'
  and p.slug in ('daily-1-step', 'classic-2-step', 'direct-instant-funding')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://help.tradeifyfx.co/en/articles/16975771-account-sizes-and-pricing'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Rechecked official price matrices and instrument commissions 2026-09-30. The pricing article is marked updated today and supplies Direct list fees by size plus Forex/metals/energies, crypto and indices commissions.'
from bullish_banana.firms f
where f.slug = 'tradeify-fx';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), case when p.slug = 'direct-instant-funding'
  then 'Current official Direct pricing article, updated today and reviewed 2026-09-30, lists fees of $85/$120/$204/$580/$1,000 for $5K/$10K/$25K/$50K/$100K. Updated the staged base-fee matrix and commission detail.'
  else 'Current official pricing article, updated today and reviewed 2026-09-30. Confirmed existing base-fee matrix and refreshed full instrument commission scope.'
end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'tradeify-fx'
  and p.slug in ('daily-1-step', 'classic-2-step', 'direct-instant-funding');
