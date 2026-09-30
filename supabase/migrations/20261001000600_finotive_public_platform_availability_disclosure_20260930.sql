-- The unauthenticated public checkout exposes both platform choices after
-- selecting each current Finotive offer family. Keep the offers in review for
-- their other unresolved terms; record only the platform fact confirmed here.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.platforms (name, slug)
values ('MetaTrader 5', 'metatrader-5'), ('Match-Trader', 'match-trader')
on conflict (slug) do update set name = excluded.name;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'platforms', jsonb_build_array('MetaTrader 5', 'Match-Trader'),
      'platform_mapping_note', 'The unauthenticated public checkout displayed MetaTrader 5 and Match-Trader as selectable options for each of the six current Forex offer families on 2026-09-30. Country or market eligibility remains to be confirmed at checkout.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id
  and f.slug = 'finotive-funding';

insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join bullish_banana.platforms pl
where f.slug = 'finotive-funding'
  and p.slug in ('one-step', 'two-step', 'instant-standard', 'instant-lite', 'pro-one-step', 'pro-two-step')
  and pl.slug in ('metatrader-5', 'match-trader')
on conflict (program_id, platform_id) do nothing;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platform_availability', 'The unauthenticated public checkout displays MetaTrader 5 and Match-Trader as selectable platforms for this offer family. Rechecked 2026-09-30. Confirm market eligibility and current availability at checkout.',
      'platforms_and_region', 'The unauthenticated public checkout displayed MetaTrader 5 and Match-Trader as selectable for this offer family on 2026-09-30. The checkout did not establish country or market eligibility; confirm the available option for your location.',
      'rule_source_capture', 'Selector, Trading Rules, current Terms, and unauthenticated public checkout reviewed 2026-09-30. The checkout showed MetaTrader 5 and Match-Trader for this offer family; confirm market eligibility. Current Terms govern.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'finotive-funding'
  and p.slug in ('one-step', 'two-step', 'instant-standard', 'instant-lite', 'pro-one-step', 'pro-two-step');

-- Correct earlier verification notes from the same review cycle so the latest
-- evidence set does not retain stale claims that offer-level platform mapping
-- is unknown.
update bullish_banana.data_verifications v
set notes = replace(
      v.notes,
      'Platform mapping remains unverified.',
      'Family-level platform choices were subsequently confirmed on the unauthenticated public checkout 2026-09-30; see the separate checkout evidence record. Other offer terms and market eligibility remain under review.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where v.program_id = p.id
  and f.slug = 'finotive-funding'
  and p.slug in ('one-step', 'two-step', 'instant-standard', 'instant-lite', 'pro-one-step', 'pro-two-step')
  and v.notes like '%Platform mapping remains unverified.%';

update bullish_banana.data_verifications v
set notes = replace(
      v.notes,
      'offer-specific platform choices remain unverified.',
      'offer-specific platform choices were subsequently confirmed at the family level on the unauthenticated public checkout 2026-09-30; market eligibility still requires confirmation.'
    )
from bullish_banana.firms f
where v.firm_id = f.id
  and f.slug = 'finotive-funding'
  and v.notes like '%offer-specific platform choices remain unverified.%';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://finotivefunding.com/next/checkout',
       'Public checkout — selectable platform options',
       'Reviewed 2026-09-30 without logging in, registering, or submitting an order. Selected this program family in the public checkout and observed MetaTrader 5 and Match-Trader as platform radio options. The public /accounts selector itself has no platform control. This confirms selectable options by family, not platform or country eligibility.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'finotive-funding'
  and p.slug in ('one-step', 'two-step', 'instant-standard', 'instant-lite', 'pro-one-step', 'pro-two-step')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = 'https://finotivefunding.com/next/checkout'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       timestamptz '2026-09-30 00:00:00+00',
       'Unauthenticated public checkout reviewed 2026-09-30. This offer family was selected and both MetaTrader 5 and Match-Trader were visible as platform options; no signup, login, or purchase was submitted. Platform mapping is confirmed at family level. Program remains in_review pending reconciliation of other offer terms and market eligibility.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'finotive-funding'
  and p.slug in ('one-step', 'two-step', 'instant-standard', 'instant-lite', 'pro-one-step', 'pro-two-step')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like '%Unauthenticated public checkout reviewed 2026-09-30. This offer family was selected%'
  );
