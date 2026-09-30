-- FundingPips guide corrections verified against the current first-party pages on 2026-09-30.
-- Programs remain in_review: other selector variants and payout conditions still need reconciliation.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set payout_frequency = case p.slug
      when '1-step-flex' then 'Biweekly (80%); official guide also mentions a Monthly cycle without stating its share in the overview.'
      when '2-step-flex' then 'Biweekly; choose 80% or 95% at purchase (same price).'
      when 'fundingpips-zero' then 'Biweekly (95%).'
      else p.payout_frequency
    end,
    commercial_details = p.commercial_details || case p.slug
      when '1-step-flex' then '{
        "evaluation_rules":"One phase; 12% target; 12% static maximum loss; no minimum trading days and no time limit per the current official guide.",
        "funded_rules":"The current plan guide specifies an 80% biweekly reward. It says overnight and weekend holding are allowed during evaluation and on Master only with the Swing Add-on. The guide references a Monthly cycle in its FAQ but does not state the share in the overview; monthly terms remain unverified.",
        "verification_note":"Current plan-specific guide reviewed 2026-09-30. Do not treat the older shared-comparison 100% monthly value as confirmed for this plan."
      }'::jsonb
      when '2-step-flex' then '{
        "evaluation_rules":"Current official homepage and plan-specific guide both show Phase 1 target 10%, Phase 2 target 8%, 4% daily loss and 12% maximum loss. The 80% reward option requires one minimum trading day per phase; the 95% option requires three profitable days of at least 0.5% per phase. Current/reset accounts use one minimum day for the 80% option; existing accounts purchased before 2026-08-26 retain zero minimum days.",
        "funded_rules":"The plan-specific guide describes biweekly rewards. The 80% and 95% options are selected at purchase, locked for the account lifetime, and cost the same. Weekend holding is allowed during evaluation; Master accounts require the Swing Add-on.",
        "verification_note":"Homepage and dedicated 2 Step Flex guide both display 10%/8% targets as of 2026-09-30. A prior review captured a conflicting 10%/6% value; retain this dated current-source observation and recheck before publication."
      }'::jsonb
      when 'fundingpips-zero' then '{
        "funded_rules":"No evaluation. 3% daily loss, 5% trailing maximum loss that locks at breakeven after reaching 5% profit, and a 1% maximum open floating-loss limit measured against starting account size. Requires at least seven profitable days of 0.25% or more in each rolling 30-day period; 30 consecutive days without a completed trade breaches inactivity. Reward share is 95% biweekly. FX leverage is 1:50.",
        "trading_conditions":"The current official guide says opening or holding trades within the restricted news/speeches window or holding positions over a weekend causes immediate account closure, regardless of instrument. Exact event window details remain to be captured from the linked policy.",
        "verification_note":"Current FundingPips Zero guide reviewed 2026-09-30. The earlier research note''s phrase ''1% risk per trade idea'' is incorrect for this field; the guide labels it a maximum open risk limit and defines it as floating loss against starting account size."
      }'::jsonb
      else '{}'::jsonb
    end,
    status = 'in_review', published_at = null, updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fundingpips'
  and p.slug in ('1-step-flex','2-step-flex','fundingpips-zero');

update bullish_banana.program_phases ph
set raw_rules = ph.raw_rules || '{
  "official_guide_verified_on":"2026-09-30",
  "source_conflict_resolution":"Current homepage and model-specific guide agree on 10% Phase 1 and 8% Phase 2 targets for 2 Step Flex."
}'::jsonb,
updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fundingpips'
  and p.slug = '2-step-flex';

update bullish_banana.sources s
set source_label = x.label, notes = x.notes, captured_at = now()
from bullish_banana.firms f
join (values
  ('https://fundingpips.com/','Official FundingPips homepage','Current public pricing widget displays 2 Step Flex Phase 1/2 targets as 10%/8%; selector price and promotion observed 2026-09-30. No checkout action.'),
  ('https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex official guide — refreshed','Current guide confirms 10%/8%, 4% daily and 12% maximum loss, biweekly 80% or 95% options at the same price, and option-dependent profitable-day requirements; reviewed 2026-09-30.'),
  ('https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex official guide — refreshed','Current guide specifies 12% target, no minimum days, 80% biweekly reward, and Master weekend holding only with Swing Add-on; reviewed 2026-09-30.'),
  ('https://help.fundingpips.com/hc/en-us/articles/34502157694865-FundingPips-Zero','FundingPips Zero official guide — refreshed','Current guide specifies 3% daily loss, 5% trailing limit, 1% maximum open floating loss, 7/30 profitable days, 30-day inactivity, 95% biweekly reward, and hard-breach news/weekend restrictions; reviewed 2026-09-30.')
) as x(url,label,notes) on true
where f.slug = 'fundingpips' and s.firm_id = f.id and s.source_url = x.url;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://fundingpips.com/','Official FundingPips homepage','Current public pricing widget displays 2 Step Flex Phase 1/2 targets as 10%/8%; selector price and promotion observed 2026-09-30. No checkout action.'),
  ('https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex official guide — refreshed','Current guide confirms 10%/8%, 4% daily and 12% maximum loss, biweekly 80% or 95% options at the same price, and option-dependent profitable-day requirements; reviewed 2026-09-30.'),
  ('https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex official guide — refreshed','Current guide specifies 12% target, no minimum days, 80% biweekly reward, and Master weekend holding only with Swing Add-on; reviewed 2026-09-30.'),
  ('https://help.fundingpips.com/hc/en-us/articles/34502157694865-FundingPips-Zero','FundingPips Zero official guide — refreshed','Current guide specifies 3% daily loss, 5% trailing limit, 1% maximum open floating loss, 7/30 profitable days, 30-day inactivity, 95% biweekly reward, and hard-breach news/weekend restrictions; reviewed 2026-09-30.')
) as x(url,label,notes) on true
where f.slug = 'fundingpips'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

update bullish_banana.sources s
set source_label = x.label, notes = x.notes, captured_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('1-step-flex','https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex official guide — refreshed','Current overview specifies 80% biweekly reward and weekend holding on Master only with Swing Add-on; reviewed 2026-09-30.'),
  ('2-step-flex','https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex official guide — refreshed','Current targets 10%/8%; 80% or 95% biweekly choices cost the same; guide reviewed 2026-09-30.'),
  ('fundingpips-zero','https://help.fundingpips.com/hc/en-us/articles/34502157694865-FundingPips-Zero','FundingPips Zero official guide — refreshed','Current 1% rule is maximum open floating loss, not per-trade-idea risk; reviewed 2026-09-30.')
) as x(program_slug,url,label,notes) on x.program_slug = p.slug
where f.slug = 'fundingpips' and s.program_id = p.id and s.source_url = x.url;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('1-step-flex','https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex official guide — refreshed','Current overview specifies 80% biweekly reward and weekend holding on Master only with Swing Add-on; reviewed 2026-09-30.'),
  ('2-step-flex','https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex official guide — refreshed','Current targets 10%/8%; 80% or 95% biweekly choices cost the same; guide reviewed 2026-09-30.'),
  ('fundingpips-zero','https://help.fundingpips.com/hc/en-us/articles/34502157694865-FundingPips-Zero','FundingPips Zero official guide — refreshed','Current 1% rule is maximum open floating loss, not per-trade-idea risk; reviewed 2026-09-30.')
) as x(program_slug,url,label,notes) on x.program_slug = p.slug
where f.slug = 'fundingpips'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'FundingPips homepage, 1 Step Flex, 2 Step Flex, and FundingPips Zero official guides refreshed 2026-09-30. Corrections are staged; all programs remain in_review pending unresolved add-on, platform, pricing, and eligibility checks.'
from bullish_banana.firms where slug = 'fundingpips';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Official plan guide refreshed 2026-09-30. See updated commercial_details and first-party sources. Program remains in_review pending complete variant and eligibility reconciliation.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundingpips' and p.slug in ('1-step-flex','2-step-flex','fundingpips-zero');
