set search_path = bullish_banana, extensions, public;

-- The release verifier requires explicit platform fields in both firm and
-- program details. Preserve location-specific limits rather than treating
-- the supported list as universally available.
update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'platforms', jsonb_build_array('DXtrade', 'cTrader', 'MetaTrader 5'),
      'platforms_note', 'BrightFunded Help Center lists DXtrade, cTrader and MT5. MT5 is unavailable to U.S. or UAE residents/citizens and in restricted countries; cTrader is unavailable to U.S. residents/citizens and in restricted countries. The reviewed source does not state location-specific DXtrade restrictions. Platform availability depends on user location and the selected account; confirm at checkout.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id
  and f.slug = 'brightfunded';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platforms', jsonb_build_array('DXtrade', 'cTrader', 'MetaTrader 5'),
      'platforms_note', 'BrightFunded Help Center lists DXtrade, cTrader and MT5. MT5 is unavailable to U.S. or UAE residents/citizens and in restricted countries; cTrader is unavailable to U.S. residents/citizens and in restricted countries. The reviewed source does not state location-specific DXtrade restrictions. Platform availability depends on user location and the selected account; confirm at checkout.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'brightfunded'
  and p.slug in ('1-step', '2-step-bright', '2-step-classic');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official Help Center article rechecked 2026-09-30. Lists DXtrade, cTrader and MT5. MT5 is unavailable to U.S. or UAE residents/citizens and in restricted countries; cTrader is unavailable to U.S. residents/citizens and in restricted countries. The article does not state location-specific DXtrade restrictions and says platform availability must be assessed for the selected account and user location.'
where firm_id = (select id from bullish_banana.firms where slug = 'brightfunded')
  and source_url = 'https://help.brightfunded.com/en/articles/10855521-what-trading-platform-does-brightfunded-offer';

update bullish_banana.sources s
set captured_at = now(),
    notes = 'Official Help Center article rechecked 2026-09-30. Lists DXtrade, cTrader and MT5. MT5 is unavailable to U.S. or UAE residents/citizens and in restricted countries; cTrader is unavailable to U.S. residents/citizens and in restricted countries. The article does not state location-specific DXtrade restrictions and says platform availability must be assessed for the selected account and user location.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'brightfunded'
  and p.slug in ('1-step', '2-step-bright', '2-step-classic')
  and s.source_url = 'https://help.brightfunded.com/en/articles/10855521-what-trading-platform-does-brightfunded-offer';

update bullish_banana.data_verifications v
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = concat_ws(E'\n', nullif(v.notes, ''), 'Platform disclosure rechecked 2026-09-30 against the current Help Center article: three supported platforms, with MT5 and cTrader restricted by residence/citizenship; DXtrade-specific location restrictions are unstated.')
where v.firm_id = (select id from bullish_banana.firms where slug = 'brightfunded');

update bullish_banana.data_verifications v
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = concat_ws(E'\n', nullif(v.notes, ''), 'Platform disclosure rechecked 2026-09-30 against the current Help Center article: three supported platforms, with MT5 and cTrader restricted by residence/citizenship; DXtrade-specific location restrictions are unstated.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where v.program_id = p.id
  and f.slug = 'brightfunded'
  and p.slug in ('1-step', '2-step-bright', '2-step-classic');
