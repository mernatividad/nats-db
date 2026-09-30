begin;

-- The official FX & CFDs page currently lists these five tracks, their complete
-- size/fee matrices, and the rules below. Publish known facts while retaining
-- the unfinished Terms and operator conflict as explicit user-facing caveats.
update bullish_banana.firms
set status = 'published',
    published_at = coalesce(published_at, now()),
    archived_at = null,
    updated_at = now()
where slug = 'nordic-funder';

update bullish_banana.firm_profiles fp
set profile_details = (coalesce(fp.profile_details, '{}'::jsonb) - 'publication_blockers') || jsonb_build_object(
      'contracting_entity', 'Current Nordic Terms and About body say Forest Park FX LTD provides and is paid for simulated assessments and signs the Trader Agreement. The same pages’ footer says Prop Account, LLC provides assessments and Prop Account LC signs the Trader Agreement. The Terms page is marked awaiting counsel sign-off and says the operative agreement remains incomplete. The offer-specific provider and counterparty are unresolved; confirm the contract shown at purchase.',
      'legal_entity_conflict', 'Nordic’s current official Terms and About body identify Forest Park FX LTD, while both page footers identify Prop Account, LLC for assessments and Prop Account LC for the Trader Agreement. Nordic’s Terms page says it is awaiting counsel sign-off and operative clauses remain incomplete. We do not infer which entity controls the individual offer.',
      'terms_status', 'The provider’s published Terms page is marked awaiting counsel sign-off. It says the Trader Agreement clauses, dispute resolution, governing law, account-closure grounds and full prohibited-practices schedule remain to be approved/migrated. Its present published terms state one-time non-refundable fees, simulated assessments, no assessment deadline, 30-day inactivity for FX staged accounts, an 80% standard split (90% with add-on), no-delay first withdrawal, and 14-day subsequent withdrawals.',
      'platforms_disclosed_at_firm_level', jsonb_build_array('DXtrade', 'Match-Trader', 'cTrader via GooeyTrade'),
      'platform_scope_note', 'The current About page names DXtrade, Match-Trader and cTrader via GooeyTrade at firm level. Nordic does not map platform availability to each FX track or account configuration; confirm the platform in the current order flow.',
      'restricted_jurisdictions', 'A complete current firm-wide and offer-specific restricted-country list is not stated in the reviewed public Nordic terms. Do not infer eligibility from platform access; confirm your country in the current order flow.',
      'account_age_note', 'A minimum customer age is not stated in the reviewed Nordic offer pages. Confirm eligibility in the current purchase terms.',
      'current_forex_tracks', jsonb_build_array('One-Step', 'Two-Step', 'Three-Step', 'One-Step Lite', 'Two-Step Lite'),
      'instant_funding_lite_scope', 'Instant Funding Lite is shown as a separate category from the FX & CFDs programme. The current Instant Funding Lite page does not explicitly confirm Forex instruments, so it is not represented as a Forex offer.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'nordic-funder';

update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    minimum_trading_days = case when p.slug in ('one-step-lite', 'two-step-lite') then 3 else null end,
    commercial_details = (coalesce(p.commercial_details, '{}'::jsonb) - 'review_note') || jsonb_build_object(
      'platforms', jsonb_build_array('DXtrade', 'Match-Trader', 'cTrader via GooeyTrade'),
      'platforms_note', 'These platforms are named by Nordic at firm level. The current official pages do not map a platform to this specific track or size; check the platform selected in the order flow.',
      'challenge_rules', case p.slug
        when 'one-step' then 'One evaluation phase; 10% target; 5% maximum daily loss using end-of-day balance; 6% trailing maximum drawdown. The official page does not state the trailing high-water-mark or lock mechanics. The official track table does not list a minimum trading-day requirement. No evaluation deadline; 30-day inactivity limit.'
        when 'two-step' then 'Two phases with 10% then 5% targets; 8% static maximum drawdown; 4% maximum daily loss using end-of-day balance. The official track table does not list a minimum trading-day requirement. No evaluation deadline; 30-day inactivity limit.'
        when 'three-step' then 'Three phases with a 5% target in each phase; 5% static maximum drawdown; 5% maximum daily loss using end-of-day balance. The official track table does not list a minimum trading-day requirement. No evaluation deadline; 30-day inactivity limit.'
        when 'one-step-lite' then 'One phase; 10% target; 5% static maximum drawdown; 2.5% intraday-trailing daily loss. The exact intraday reference/reset mechanics are not stated. Three profitable days of at least 1% are listed; there is no evaluation consistency rule and a 50% funded consistency rule. No evaluation deadline.'
        when 'two-step-lite' then 'Two phases with 12% then 6% targets; 6% static maximum drawdown; 3% intraday-trailing daily loss. The exact intraday reference/reset mechanics are not stated. Three profitable days of at least 1% are listed at track level; the official page does not say whether this is per phase or total. No evaluation consistency rule and a 50% funded consistency rule. No evaluation deadline.'
      end,
      'funded_rules', 'Standard profit split is 80%; an add-on raises it to 90%. The first withdrawal has no delay, followed by rolling 14-day payout cycles. Lite tracks list a 50% funded consistency rule. FX staged tracks have a 30-day inactivity limit. The public Terms page is awaiting counsel sign-off and states that the operative Trader Agreement is incomplete.',
      'trading_conditions', case when p.slug in ('one-step', 'two-step', 'three-step')
        then 'Raw spreads. Published round-turn commission is USD 7 per lot for Forex and metals and USD 0 for indices, oil and crypto. Own EAs/algorithms are allowed. Weekend holding is presented as an add-on; the site says only crypto trades at weekends. Forex-specific add-on implementation is not fully specified in the pending operative agreement.'
        else 'Raw spreads. Own EAs/algorithms are allowed. The FX & CFDs table does not state a commission for this Lite track. Weekend holding is presented as an add-on; the site says only crypto trades at weekends. Forex-specific add-on implementation is not fully specified in the pending operative agreement.'
      end,
      'legal_terms_disclosure', 'Current marketing and offer rules are published, but Nordic’s Terms page is marked awaiting counsel sign-off and says operative legal clauses remain incomplete. The Terms/About body names Forest Park FX LTD, while their footers name Prop Account, LLC and Prop Account LC. Confirm the assessment provider and funded-account counterparty shown in your purchase documents.',
      'eligibility_note', 'The reviewed public pages do not state a complete current restricted-country list. Confirm country eligibility and the current contracting entity in the order flow.',
      'pricing_capture', 'Current official FX & CFDs size/fee matrix rechecked 2026-09-30. The stored fees are listed one-time base fees; the Terms page says fees are non-refundable and add-ons are priced separately as a percentage of the assessment fee. No checkout add-on is included in these rows.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'nordic-funder'
  and p.slug in ('one-step', 'two-step', 'three-step', 'one-step-lite', 'two-step-lite');

update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = null::integer,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_time_limit', true,
      'time_limit', 'No deadline for hitting the target; FX staged accounts have a 30-day inactivity limit.',
      'time_limit_source_reviewed', '2026-09-30',
      'daily_limit_basis', case when p.slug in ('one-step-lite', 'two-step-lite')
        then 'Official page calls this intraday trailing; exact reference and reset mechanics are not stated.'
        else 'Official page specifies an end-of-day balance basis; exact reset time is not stated.'
      end,
      'maximum_drawdown_mechanic', case when p.slug = 'one-step'
        then 'Official page describes the limit as trailing; the high-water mark and lock mechanics are not stated.'
        else 'Official page identifies the limit as static.'
      end,
      'day_requirement_label', case
        when p.slug = 'one-step-lite' then 'Three profitable days of at least 1%.'
        when p.slug = 'two-step-lite' then 'Three profitable days of at least 1% are stated at track level; per-phase versus total application is not stated.'
        else 'The official track table does not list a minimum trading-day requirement.'
      end,
      'no_minimum_trading_days', case when p.slug in ('one-step-lite', 'two-step-lite') then false else true end
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'nordic-funder'
  and p.slug in ('one-step', 'two-step', 'three-step', 'one-step-lite', 'two-step-lite');

update bullish_banana.sources s
set notes = concat(s.notes, E'\nLive page rechecked 2026-09-30: the same five FX & CFDs tracks and listed account-size/base-fee matrices remain current. The page identifies target, drawdown type, daily loss, payout, inactivity, leverage, commissions where shown, and platform choices. It does not map platform availability by track or order configuration.')
from bullish_banana.firms f
where s.firm_id = f.id and f.slug = 'nordic-funder'
  and s.source_url = 'https://nordicfunder.com/programs/fx-cfd/'
  and s.notes not like '%Live page rechecked 2026-09-30%';

update bullish_banana.sources s
set notes = concat(s.notes, E'\nRechecked 2026-09-30: body identifies Forest Park FX LTD as assessment provider and funded Trader Agreement counterparty; page footer identifies Prop Account, LLC and Prop Account LC. Terms page still says awaiting counsel sign-off and operative clauses remain incomplete. The offer-specific provider/counterparty remains unresolved.')
from bullish_banana.firms f
where s.firm_id = f.id and f.slug = 'nordic-funder'
  and s.source_url = 'https://nordicfunder.com/legal/terms/'
  and s.notes not like '%Rechecked 2026-09-30%';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://nordicfunder.com/programs/fx-cfd/',
       'Current FX & CFDs track and fee matrix — verified 2026-09-30',
       'Current official offer page rechecked 2026-09-30. Confirms this track is currently offered, its published account-size/base-fee matrix, phase targets, drawdown type and maximum, daily loss, payout and trading conditions as shown. The same page says there is no deadline for reaching target, with a 30-day inactivity limit on staged FX accounts. Platform mapping by track and account configuration is not stated.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'nordic-funder'
  and p.slug in ('one-step', 'two-step', 'three-step', 'one-step-lite', 'two-step-lite')
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://nordicfunder.com/programs/fx-cfd/'
      and s.source_label = 'Current FX & CFDs track and fee matrix — verified 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:45:00Z'::timestamptz,
  'Current Nordic FX & CFDs page, About page, and Terms page rechecked 2026-09-30. The page continues to list five tracks and current matrices. About/Terms body identifies Forest Park FX LTD, while page footers identify Prop Account, LLC and Prop Account LC. Terms remain marked awaiting counsel sign-off and say operative clauses are incomplete. These facts are exposed as profile caveats; complete country eligibility and offer-specific contracting entity remain unstated.'
from bullish_banana.firms f
where f.slug = 'nordic-funder'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T13:45:00Z'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T13:45:00Z'::timestamptz,
  'Official FX & CFDs page rechecked 2026-09-30. This track is currently listed; its complete account-size/base-fee matrix and published target, drawdown, daily-loss, funded split/payout, platform family and trading conditions have an official source row. The page says there is no evaluation deadline and specifies a 30-day inactivity limit. Platform-by-track mapping and account-specific contractual/legal terms remain unprovided and are disclosed.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'nordic-funder'
  and p.slug in ('one-step', 'two-step', 'three-step', 'one-step-lite', 'two-step-lite')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T13:45:00Z'::timestamptz);

insert into bullish_banana.affiliate_destinations
  (firm_id, kind, label, destination_url, is_primary, status)
select f.id, 'official_site', 'Visit Nordic Funder', 'https://nordicfunder.com/', true, 'active'
from bullish_banana.firms f
where f.slug = 'nordic-funder'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.kind = 'official_site'
  );

insert into bullish_banana.affiliate_destinations
  (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View Nordic Funder ' || p.name,
       'https://nordicfunder.com/programs/fx-cfd/', true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'nordic-funder'
  and p.slug in ('one-step', 'two-step', 'three-step', 'one-step-lite', 'two-step-lite')
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.program_id = p.id and d.kind = 'official_site'
  );

commit;
