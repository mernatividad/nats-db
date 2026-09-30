-- Hantec Trader official Platform 5 product-page scope recheck, 2026-09-30.
-- Preserve the site's own product name; it does not establish equivalence to
-- MetaTrader 5 or a per-offer checkout configuration.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb)
      || jsonb_build_object(
        'platform', 'Hantec Trader identifies its platform as Platform 5. The official page describes trading Forex, indices, commodities, precious metals and crypto within one account, and directs users to pass a challenge then trade on Platform 5. The page does not state that Platform 5 is MetaTrader 5 or give an offer-by-offer checkout mapping. Preserve the official name; verify account-specific availability at checkout.',
        'platform_verified_on', '2026-09-30'
      ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id
  and f.slug = 'hantec-trader';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb)
      || jsonb_build_object(
        'platform_note', 'Hantec Trader’s official platform page brands the environment as Platform 5 and says users pass a challenge then trade on this platform. The page describes one account for multiple markets, but does not map this exact offer, size or checkout to a platform. Current catalog platform relationship is Platform 5; MetaTrader 5 equivalence is not confirmed.'
      ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance', 'instant-funding', 'instant-lite', 'instant24');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
       'https://htrader.hmarkets.com/jp/platforms/',
       'Platform 5 product page scope — 2026-09-30',
       'Current official Platform 5 page lists supported desktop, mobile and browser environments, describes a single account across Forex, indices, commodities, precious metals and crypto, and says to pass a challenge then trade on Platform 5. It does not equate Platform 5 with MetaTrader 5 or publish an exact program/size/checkout platform matrix.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://htrader.hmarkets.com/jp/platforms/'
      and s.source_label = 'Platform 5 product page scope — 2026-09-30'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://htrader.hmarkets.com/jp/platforms/',
       'Platform 5 official page reference — 2026-09-30',
       'The official page presents Platform 5 as the environment for trading after passing a challenge and describes one account across multiple markets. It does not identify this program, size or checkout configuration individually; do not convert the Platform 5 label to MetaTrader 5 without evidence.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance', 'instant-funding', 'instant-lite', 'instant24')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://htrader.hmarkets.com/jp/platforms/'
      and s.source_label = 'Platform 5 official page reference — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id,
       '2026-09-30'::timestamptz,
       'Current official platform page reviewed 2026-09-30. Hantec brands the platform as Platform 5 and describes its multi-market single-account offer and challenge-to-funded flow. It does not equate Platform 5 with MetaTrader 5 or map an account/checkout to a per-offer platform.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.firm_id = f.id
      and v.verified_at = '2026-09-30'::timestamptz
      and v.notes like 'Current official platform page reviewed 2026-09-30%'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30'::timestamptz,
       'Current official Hantec platform page reviewed 2026-09-30. It calls the product Platform 5 and describes challenge-to-funded trading; it does not name this exact program/size checkout or confirm Platform 5 is MetaTrader 5. Keep the program Platform 5 reference with this scope caveat and verify selected checkout before publishing.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express', 'enhanced', 'enhancedx', 'endurance', 'instant-funding', 'instant-lite', 'instant24')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30'::timestamptz
      and v.notes like 'Current official Hantec platform page reviewed 2026-09-30%'
  );
