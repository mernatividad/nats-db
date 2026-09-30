begin;

-- Publish every Fintokei Forex family represented in current public materials.
-- The official source disagreement about Crypto and the Slim price matrix
-- remain explicitly disclosed; no unsupported facts are inferred.
update bullish_banana.firms
set status = 'published',
    published_at = coalesce(published_at, now()),
    archived_at = null,
    updated_at = now()
where slug = 'fintokei';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'asset_scope_recheck', 'The current Programs catalog says customers can trade FX pairs and CFD metals, energies, and indices, and says Crypto and stocks are not offered. The separate official Instruments FAQ says Crypto CFDs are supported by the four standard program families. This official-source conflict is unresolved; Crypto is therefore not represented as a confirmed asset in the catalog.',
      'supported_instruments', 'Current Programs catalog confirms FX pairs and CFD metals, energies, and indices; it says stocks and crypto are not offered. A separate official Instruments FAQ conflicts on crypto support. Per-symbol specifications, leverage, spreads, commissions, order-size limits and trading hours vary; use the official symbols page for instrument-specific conditions.',
      'programs', jsonb_build_array('StartTrader', 'SwiftTrader', 'ProTrader', 'ProTrader Swing', 'ProTrader Slim'),
      'protrader_slim', 'Official Help Center documents ProTrader Slim as a Japan/Japanese-language, JPY-only ProTrader variant with six plan labels (Quartz, Crystal, Pearl, Ruby, Sapphire, Topaz), MT5-only access, z-suffixed FX symbols and a 500 JPY round-turn commission. The reviewed official FAQ does not publish its account-size or fee matrix; both remain unstated.',
      'platform_scope_note', 'The current Programs catalog lists TradingView, MetaTrader 5 and cTrader for the firm. ProTrader Slim is specifically MT5-only. Track-specific platform availability for the four standard families is not mapped in the reviewed catalog; confirm the platform selected for a specific checkout.',
      'legal_operator_update', 'The current official site identifies Fintokei a.s. as the owner/operator and AXSE Brokerage Ltd. as provider of platform and technical infrastructure. Fintokei states that customer accounts are simulated virtual accounts and it does not accept customer deposits or execute customer trades in the live market.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'fintokei';

update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'asset_scope_recheck', case when p.slug = 'fintokei-protrader-slim'
        then 'The offer is a documented JPY Japan/Japanese-language ProTrader variant, and the official FAQ lists its supported z-suffixed FX symbols. For the four standard families, the current Programs catalog excludes crypto while the separate Instruments FAQ says it is supported; this official-source conflict remains unresolved.'
        else 'Current official Programs catalog confirms FX pairs and CFD metals, energies and indices and says crypto is not offered. The separate official Instruments FAQ says crypto CFDs are supported by these standard families. This source conflict is unresolved; crypto support is not assumed.'
      end,
      'platforms_note', case when p.slug = 'fintokei-protrader-slim'
        then 'The official Slim FAQ specifies MetaTrader 5 only.'
        else 'Fintokei lists TradingView, MetaTrader 5 and cTrader at firm level. The reviewed official sources do not map standard-family platform access by plan or account size; confirm in the current checkout.'
      end,
      'challenge_rules', case when p.slug = 'fintokei-protrader-slim'
        then 'Japan/Japanese-language JPY variant of standard ProTrader: two phases with 8% then 6% targets, three profitable trading days required per phase, 5% daily and 10% maximum loss. Its FAQ says it follows standard ProTrader rules; account-specific timing and other exceptions should be confirmed in current terms.'
        else p.commercial_details ->> 'challenge_rules'
      end,
      'account_size_note', case when p.slug = 'fintokei-protrader-slim'
        then 'The official ProTrader Slim FAQ lists six JPY plan labels but does not state account capital sizes.'
        else p.commercial_details ->> 'account_size_note'
      end,
      'price_configuration', case when p.slug = 'fintokei-protrader-slim'
        then 'The reviewed official ProTrader Slim FAQ does not publish a fee schedule. No JPY price or account-size fee has been inferred; confirm current amount at checkout.'
        else p.commercial_details ->> 'price_configuration'
      end,
      'legal_entity_disclosure', 'The official site identifies Fintokei a.s. as owner/operator and AXSE Brokerage Ltd. as technical/platform infrastructure provider. Accounts are simulated; Fintokei says it does not accept customer deposits or execute customer trades in the live market.',
      'eligibility_note', 'Country access differs by service eligibility, temporary restrictions and whether new purchases are enabled. Check the dated firm profile and current official eligibility FAQ before purchase; payout-method eligibility has a separate country scope.',
      'source_conflict_note', case when p.slug = 'fintokei-protrader-slim'
        then 'Slim is documented in the Help Center as a current regional/Japanese-language variant; the public USD Programs catalog does not list it, and the reviewed FAQ does not state its account sizes or fees. Its JPY plan labels must not be presented as account sizes.'
        else null
      end
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing', 'fintokei-protrader-slim');

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_time_limit', true,
      'time_limit', 'No maximum assessment duration; the firm still requires the stated minimum profitable days per phase.',
      'time_limit_source_reviewed', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fintokei'
  and p.slug = 'fintokei-protrader-slim';

update bullish_banana.sources s
set notes = concat(s.notes, E'\nPublication recheck 2026-09-30: current Programs page lists four USD families and says FX pairs, CFD metals, energies and indices are supported but crypto is not. The separate official Instruments FAQ says crypto CFDs are supported by all four. The conflict remains disclosed instead of assuming crypto eligibility.')
from bullish_banana.firms f
where s.firm_id = f.id and f.slug = 'fintokei'
  and s.source_url = 'https://www.fintokei.com/programs'
  and s.notes not like '%Publication recheck 2026-09-30%';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://www.fintokei.com/programs',
       'Current Programs catalog — publication recheck 2026-09-30',
       'Current official Programs catalog lists StartTrader, SwiftTrader, ProTrader and ProTrader Swing, the USD account-size/base-fee rows, core targets, drawdowns and deadlines, and lists TradingView, MetaTrader 5 and cTrader. Its FAQ states customer accounts are simulated and excludes crypto and stock trading; the separate official Instruments FAQ conflicts on crypto availability.'
from bullish_banana.firms f
where f.slug = 'fintokei'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_label = 'Current Programs catalog — publication recheck 2026-09-30');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://support.fintokei.com/en/articles/6538848-what-instruments-can-i-trade',
       'Official Instruments FAQ — Crypto scope conflict',
       'Official FAQ states that Crypto CFDs are supported across all four standard families, in conflict with the current Programs catalog FAQ, which says Crypto is not offered. The discrepancy is preserved in the published firm and program records.'
from bullish_banana.firms f
where f.slug = 'fintokei'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://support.fintokei.com/en/articles/6538848-what-instruments-can-i-trade');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://www.fintokei.com/programs', 'Current official Fintokei Programs catalog',
       'Rechecked 2026-09-30. This USD family is currently listed with account sizes, one-time prices, evaluation rules, payout/reward terms, and trading conditions shown on the current Programs page. The page says no Crypto; Fintokei’s separate Instruments FAQ conflicts. Plan-specific platform assignment is not stated.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://www.fintokei.com/programs');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim',
       'Official ProTrader Slim regional offer FAQ',
       'Rechecked 2026-09-30. The Help Center documents a Japan/Japanese-language JPY offer, six plan labels, MT5-only access, eligible z-suffixed FX symbols and a 500 JPY round-turn commission; it says standard ProTrader rules apply. It does not publish account-size or fee values.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fintokei' and p.slug = 'fintokei-protrader-slim'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:52:00Z'::timestamptz,
  'Rechecked current Fintokei Programs page, instruments FAQ, ProTrader Slim FAQ, eligibility FAQ and official company disclosure on 2026-09-30. The four USD families and their published matrices remain current. Crypto scope conflicts between the Programs page and separate official Instruments FAQ. Slim remains a distinct regional JPY offer with no published size/fee matrix in the reviewed source. The conflict and unavailable Slim fees are disclosed.'
from bullish_banana.firms f
where f.slug = 'fintokei'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T13:52:00Z'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T13:52:00Z'::timestamptz,
  case when p.slug = 'fintokei-protrader-slim'
    then 'ProTrader Slim official FAQ rechecked 2026-09-30. It identifies a current Japan/Japanese-language JPY ProTrader variant and states plan labels, MT5, eligible z-suffixed FX symbols, 500 JPY round-turn commission and standard ProTrader rules. The reviewed source does not state its account capital sizes or fees; these remain explicitly unstated.'
    else 'Current official Programs page and program-specific Help Center records reviewed 2026-09-30. This program remains listed with a dated source for its account-size/base-fee matrix and current challenge/payout rules. The Programs-page crypto exclusion conflicts with the separate Instruments FAQ and is explicitly disclosed.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing', 'fintokei-protrader-slim')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T13:52:00Z'::timestamptz);

insert into bullish_banana.affiliate_destinations
  (firm_id, kind, label, destination_url, is_primary, status)
select f.id, 'official_site', 'Visit Fintokei', 'https://www.fintokei.com/programs', true, 'active'
from bullish_banana.firms f
where f.slug = 'fintokei'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.firm_id = f.id and d.program_id is null and d.kind = 'official_site');

insert into bullish_banana.affiliate_destinations
  (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View Fintokei ' || p.name,
       case when p.slug = 'fintokei-protrader-slim'
         then 'https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim'
         else 'https://www.fintokei.com/programs'
       end,
       true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing', 'fintokei-protrader-slim')
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');

commit;
