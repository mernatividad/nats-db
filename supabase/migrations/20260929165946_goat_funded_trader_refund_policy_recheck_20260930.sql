-- Add the current official Refund Policy and refresh Goat Funded Trader verification.
-- Selector-visible offers remain published with refund marketing and legal wording
-- kept as a visible, unresolved conflict; help-only offers remain in review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles
set profile_details = profile_details || '{"fee_refund_conflict":"Rechecked 2026-09-30: public model selector labels the one-time fee 100% refundable, but the standalone Refund Policy and Terms both state that purchased services are non-refundable. Do not represent a guaranteed refund; record the legal/marketing contradiction and its conditions as unresolved."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'goat-funded-trader');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firm.id,
       'https://www.goatfundedtrader.com/legal/refund-policy',
       'Goat Funded Trader Refund Policy',
       'Current official standalone Refund Policy states that services are non-refundable and transactions are final. This conflicts with the live model selector''s “100% refundable fee” wording; no conditions reconciling the two were found. Rechecked 2026-09-30.'
from bullish_banana.firms firm
where firm.slug = 'goat-funded-trader'
  and not exists (
    select 1 from bullish_banana.sources existing
    where existing.firm_id = firm.id
      and existing.source_url = 'https://www.goatfundedtrader.com/legal/refund-policy'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select program.id,
       'https://www.goatfundedtrader.com/legal/refund-policy',
       'Official refund policy — fee wording conflict',
       'The selector describes a 100% refundable one-time fee, while the current standalone Refund Policy says purchased services are non-refundable and all transactions final. No reconciliation was found. Keep the claim qualified and the contradiction visible. Reviewed 2026-09-30.'
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
where firm.slug = 'goat-funded-trader'
  and program.slug in ('1-step-goat', '2-step-goat', '2-step-standard', 'instant-hero', 'instant-goat', 'instant-premium')
  and not exists (
    select 1 from bullish_banana.sources existing
    where existing.program_id = program.id
      and existing.source_url = 'https://www.goatfundedtrader.com/legal/refund-policy'
  );

update bullish_banana.data_verifications
set verified_at = now(),
    notes = 'Reviewed current official model selector, Terms, and standalone Refund Policy on 2026-09-30. Six selector-visible Forex programs remain current; selector refund labeling conflicts with the Refund Policy and Terms no-refund language. Preserve this contradiction. Help Center-only models remain in review pending live checkout confirmation.'
where firm_id = (select id from bullish_banana.firms where slug = 'goat-funded-trader');

update bullish_banana.data_verifications verification
set verified_at = now(),
    notes = 'Current selector availability and model-specific terms rechecked 2026-09-30. Selector refund wording conflicts with the official Refund Policy and Terms, which say paid services are non-refundable. Program remains published with that conflict explicit; promotional code eligibility/expiry and remaining model-specific country/platform coverage still require confirmation.'
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
where verification.program_id = program.id
  and firm.slug = 'goat-funded-trader'
  and program.slug in ('1-step-goat', '2-step-goat', '2-step-standard', 'instant-hero', 'instant-goat', 'instant-premium');
