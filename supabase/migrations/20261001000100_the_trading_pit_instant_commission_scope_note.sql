-- Clarify the unresolved source scopes for The Trading Pit's Instant Forex commissions.
-- The dedicated Instant Help Center gives a plan-specific $6/lot value. The CFD page's
-- generic instrument table gives $5/lot without labeling the account tier or platform.
-- Preserve both values and leave the program in_review until applicability is confirmed.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'commission_details', 'The dedicated CFDs Instant commission article states $6 per Forex lot. The current CFD page also shows $5 per lot in a general instrument table, but does not scope that table by account type or platform. Keep the two source claims attributed; do not assume a firm-wide rate or that the general table applies to Instant.',
      'commission_scope_conflict', 'The Instant-specific Help Center states $6/lot; the generic CFD instrument table states $5/lot and does not identify whether it applies to Prime, Instant, or a platform. Applicability remains unresolved.',
      'open_items', jsonb_build_array(
        'Confirm whether the general CFD instrument table applies to Prime, Instant, or specific platforms; retain both source-backed commission values until scoped.',
        'Confirm whether the 6% maximum-loss method is static or otherwise defined in current Instant rules.'
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'the-trading-pit'
  and p.slug = 'instant-cfd-earning-account';

update bullish_banana.sources s
set notes = 'Dedicated Instant-specific commission article states $6 per Forex lot. The main CFD page separately shows $5 in a generic instrument table that is not labeled by account type or platform; applicability remains unresolved.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'the-trading-pit'
  and p.slug = 'instant-cfd-earning-account'
  and s.source_url = 'https://support.thetradingpit.com/what-are-the-commissions-for-cfds-instant';

update bullish_banana.sources s
set notes = 'Current main CFD page has Prime and Instant selector modes and a generic Forex instrument list showing $5 per lot, but the table does not identify account-type or platform scope. The dedicated Instant commission article separately states $6 per Forex lot.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'the-trading-pit'
  and p.slug = 'instant-cfd-earning-account'
  and s.source_url = 'https://www.thetradingpit.com/cfds-prop-trading';

update bullish_banana.data_verifications v
set notes = concat_ws(' ', nullif(v.notes, ''), 'Rechecked 2026-09-30: dedicated Instant FAQ says $6/lot; main CFD instrument table says $5/lot without account-type/platform scope. Program remains in_review pending applicability clarification.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where v.program_id = p.id
  and f.slug = 'the-trading-pit'
  and p.slug = 'instant-cfd-earning-account'
  and v.notes like '%commission sources conflict%';
