begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
  'platforms_disclosed_at_firm_level', jsonb_build_array('MetaTrader 4','MetaTrader 5','cTrader','TradingView'),
  'platform_scope_note', 'Current FTMO platform FAQ says the 1-Step and 2-Step challenges and FTMO Account can use MetaTrader 4, MetaTrader 5, cTrader or TradingView. Traders choose the platform in the challenge configurator; confirm the selected account configuration.'
), updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'ftmo';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
  'platforms_disclosed_at_firm_level', jsonb_build_array('MetaTrader 5','Match-Trader'),
  'platform_scope_note', 'Current homepage lists MetaTrader 5 and Match-Trader at firm level. The Lite-2 FAQ lists MetaTrader 5 and TradeLocker instead. These first-party platform lists differ; do not infer offer-specific availability beyond the Lite-2 FAQ without checking the current selector.'
), updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'fundedelite';

-- The Lite-2 FAQ names its choices; other offers get an explicit unknown scope,
-- not a firm-wide platform assignment.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
  case when p.slug = 'lite-2-step' then jsonb_build_object(
    'platforms', jsonb_build_array('MetaTrader 5','TradeLocker'),
    'platforms_note', 'The Lite-2 challenge FAQ explicitly offers MetaTrader 5 or TradeLocker; select the applicable platform in its configuration.'
  ) else jsonb_build_object(
    'platforms_note', 'The current homepage lists MetaTrader 5 and Match-Trader at firm level. The Lite-2 FAQ separately lists MetaTrader 5 and TradeLocker. This source conflict does not establish platform access for this specific offer; check its current selector.'
  ) end,
  updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fundedelite' and p.program_type <> 'other';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('ftmo','https://ftmo.com/en/faq/which-platforms-can-i-use-for-trading/','FTMO platform availability FAQ — rechecked 2026-09-30','Current official FAQ states the 1-Step and 2-Step challenges and FTMO Account support MetaTrader 4, MetaTrader 5, cTrader or TradingView, selected in the challenge configurator.'),
  ('fundedelite','https://fundedelite.com/','FundedElite homepage platform list — rechecked 2026-09-30','Current homepage lists MetaTrader 5 and Match-Trader at firm level. The Lite-2 FAQ instead documents MetaTrader 5 and TradeLocker; the difference is preserved, and no per-offer availability is inferred beyond that FAQ.')
) as x(slug,url,label,notes) on x.slug = f.slug
where not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_label = x.label);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  case when p.slug = 'lite-2-step' then 'https://faq.fundedelite.com/en/articles/12683646-lite-2-step-challenge' else 'https://fundedelite.com/' end,
  'FundedElite offer platform scope — rechecked 2026-09-30',
  case when p.slug = 'lite-2-step'
    then 'The official Lite-2 challenge FAQ explicitly says its selectable platforms are MetaTrader 5 and TradeLocker.'
    else 'The current homepage lists MetaTrader 5 and Match-Trader at firm level; the Lite-2 FAQ says MetaTrader 5 and TradeLocker. Offer-specific platform availability is not mapped for this program, so confirm in its selector.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite' and p.program_type <> 'other'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_label = 'FundedElite offer platform scope — rechecked 2026-09-30');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T14:30:00Z'::timestamptz,
  case when f.slug = 'ftmo'
    then 'Rechecked the FTMO platform FAQ: FTMO 1-Step, 2-Step and FTMO Accounts can use MT4, MT5, cTrader or TradingView, with a platform selected in the configurator.'
    else 'Rechecked the current FundedElite homepage and Lite-2 challenge FAQ. Homepage lists MT5 and Match-Trader; Lite-2 lists MT5 and TradeLocker. The first-party discrepancy and offer-level scope limit are disclosed.'
  end
from bullish_banana.firms f
where f.slug in ('ftmo','fundedelite')
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T14:30:00Z'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T14:30:00Z'::timestamptz,
  case when p.slug = 'lite-2-step'
    then 'Current official Lite-2 FAQ lists MetaTrader 5 and TradeLocker as selectable platforms; firm homepage also lists MetaTrader 5 and Match-Trader. Preserve the difference in source scope.'
    else 'Current firm homepage and Lite-2 challenge FAQ were rechecked. They do not map an available platform to this specific offer; this unknown is disclosed rather than inferred.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite' and p.program_type <> 'other'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T14:30:00Z'::timestamptz);

commit;
