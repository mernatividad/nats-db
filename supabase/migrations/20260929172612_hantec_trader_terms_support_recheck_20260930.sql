-- Hantec Trader legal and Help Center recheck, 2026-09-30.
-- Prices remain from the selector snapshot captured 2026-09-28.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "refund_policy_note":"Current Terms clause 6.4 provides a refund only within 14 days of purchase and only if no trading has occurred on the simulated account. The captured Terms do not state a post-pass fee refund. Do not present the 14-day no-trade cancellation right as a passed-account refund; check any separate refund policy and account-specific checkout terms before publication.",
  "instant_program_restrictions":"Current Terms clause 3.2 separately identify United Kingdom, Mauritius, Hong Kong, and Singapore as potentially unavailable for Instant Programs. Keep these restrictions attached to Instant Funding, Instant Lite, and Instant24; do not apply them to the evaluation challenges without first-party evidence."
}'::jsonb,
updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'hantec-trader';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://htrader.hmarkets.com/terms-conditions/', 'Terms and refund recheck — 2026-09-30',
       'Reopened current Terms. Clause 6.4 allows a refund within 14 days of purchase only when no trading has occurred. Clauses 3.2 and 5 impose service/jurisdiction limits, including Instant Program exclusions for UK, Mauritius, Hong Kong and Singapore. No passed-account refund promise was confirmed in this Terms text.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id and s.source_url = 'https://htrader.hmarkets.com/terms-conditions/'
      and s.source_label = 'Terms and refund recheck — 2026-09-30'
  );

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://help.htrader.hmarkets.com/en/support/solutions/', 'English Help Center rules recheck — 2026-09-30',
       'English rules pages for Express, Enhanced, EnhancedX and Endurance were re-opened. Core targets and loss limits match the staged September 28 snapshot. EnhancedX still describes a +2% max-loss add-on as an increase from 6% to 8% while the base rules page already states 8%; retain the add-on ambiguity. Full selector price matrices were not refreshed.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id and s.source_url = 'https://help.htrader.hmarkets.com/en/support/solutions/'
      and s.source_label = 'English Help Center rules recheck — 2026-09-30'
  );

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://htrader.hmarkets.com/', 'Live product selector lineup recheck — 2026-09-30',
       'Rechecked live selector family grouping: Express (1 Step), Enhanced and EnhancedX (2 Step), Endurance (3 Step), and Instant Funding, Instant Lite, Instant24 (Instant). Default selected base fees observed: Express $2K/$39; Enhanced and EnhancedX $5K/$59; Endurance $5K/$29; Instant Funding $1K/$43; Instant Lite $1K/$19; Instant24 $2K/$13. A 50% promotion banner was visible and excluded Instant24. No checkout was completed; these default observations do not refresh the full size/fee matrices, add-on prices, or platform mapping. Full fee matrices remain based on the 2026-09-28 selector capture.'
from bullish_banana.firms f
where f.slug = 'hantec-trader'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id and s.source_url = 'https://htrader.hmarkets.com/'
      and s.source_label = 'Live product selector lineup recheck — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(),
       'Terms, English Help Center rules and live selector lineup rechecked 2026-09-30. Terms clause 6.4 confirms a 14-day refund only if no trading occurred; it does not establish a post-pass refund. Current evaluation rule pages remain aligned with the 2026-09-28 snapshot. The selector confirms four families/seven offers and six default base-price observations, but full official selector fee matrices remain dated 2026-09-28; all seven programs stay in_review pending current configuration prices, add-on/platform mapping and remaining legal checks.'
from bullish_banana.firms f
where f.slug = 'hantec-trader';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(),
       'Current first-party rules/Terms rechecked 2026-09-30. No challenge rule correction was identified in the checked English pages. Selector prices and configuration matrices remain the 2026-09-28 capture; program remains in_review pending updated selector price/add-on, platform and any program-specific account agreement checks.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'hantec-trader'
  and p.slug in ('express','enhanced','enhancedx','endurance','instant-funding','instant-lite','instant24');
