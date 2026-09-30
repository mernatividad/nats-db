set search_path = bullish_banana, extensions, public;

-- The current main-site Terms assign separate roles to the website operator,
-- payment/education provider, and simulation-platform provider. The older
-- checkout Evaluation Terms name another seller; keep the purchase party open.
update bullish_banana.firm_profiles
set country_code = 'AE',
    legal_entity_name = 'Iconic Exchange FZCO t/a Blue Guardian',
    profile_details = profile_details || jsonb_build_object(
      'profile_entity_scope', 'Country/jurisdiction and legal-entity summary refer to the current main-site Terms operator, Iconic Exchange FZCO in Dubai, UAE. Blue Guardian Limited in Saint Lucia is the disclosed simulated-platform provider; the dedicated checkout Evaluation Terms separately name Iconic Exchange Limited in the UK, so the current purchase seller remains unresolved.',
      'website_operator_current', 'Current blueguardian.com Terms identify Iconic Exchange FZCO t/a Blue Guardian as the website operator/company.',
      'simulation_platform_provider_current', 'The main-site footer identifies Blue Guardian Limited, Saint Lucia, as the provider of simulated trading platforms.',
      'educational_and_payment_provider_current', 'The main-site footer identifies Iconic Exchange FZCO, Dubai, as provider of educational products and payment processing.',
      'related_support_entity_current', 'Blue Guardian Marketing LLC is labeled in the footer as a related, non-operational support and administrative entity.',
      'evaluation_contracting_party_conflict', 'The current main-site Terms name Iconic Exchange FZCO t/a Blue Guardian; the dedicated checkout Evaluation Terms name Iconic Exchange Limited, England and Wales company 12087566. The current main-site Terms say purchase-specific terms may separately apply. The seller for a current Forex evaluation purchase is unresolved.',
      'blue_guardian_entity_roles_verified_at', '2026-09-30'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian');

update bullish_banana.programs
set commercial_details = coalesce(commercial_details, '{}'::jsonb) || jsonb_build_object(
      'leverage_conflict_rechecked_at', '2026-09-30',
      'leverage_source_conflict', 'Current official Forex selector, opened 2026-09-30 with 1-Step Standard selected at $100K, displays 1:100 maximum Forex leverage. Current official Platform Rules state 1:50 Forex leverage for 1-Step evaluation. The dedicated current 1-Step Standard rules article does not state leverage. Keep leverage marked as conflicting/unknown until the provider maps the selector and general platform matrix to this purchase configuration.'
    ),
    updated_at = now()
where slug = '1-step-standard'
  and firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Rechecked 2026-09-30. Current main-site Terms name Iconic Exchange FZCO t/a Blue Guardian as website operator/company. The page footer assigns simulated-platform provision to Blue Guardian Limited and educational products/payment processing to Iconic Exchange FZCO. The Terms state purchase-specific terms may separately apply.'
where firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian')
  and source_url = 'https://blueguardian.com/terms-and-conditions';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Rechecked 2026-09-30. Dedicated Evaluation Terms identify Iconic Exchange Limited, England and Wales company 12087566, as the Blue Guardian seller and say the purchase contract is formed upon acceptance of registration. This conflicts with the current main-site Terms naming Iconic Exchange FZCO t/a Blue Guardian; verify which terms govern current Forex checkout.'
where firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian')
  and source_url = 'https://checkout.blueguardian.com/terms-and-conditions/';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://checkout.blueguardian.com/terms-and-conditions/', 'Blue Guardian checkout Evaluation Terms', 'Rechecked 2026-09-30. Dedicated checkout Evaluation Terms identify Iconic Exchange Limited, England and Wales company 12087566, as seller. This conflicts with current main-site Terms naming Iconic Exchange FZCO t/a Blue Guardian; verify which terms govern current Forex checkout.'
from bullish_banana.firms f
where f.slug = 'blue-guardian'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://checkout.blueguardian.com/terms-and-conditions/'
  );

update bullish_banana.sources
set captured_at = now(),
    notes = 'Reopened 2026-09-30. General Platform Rules specify 1:50 Forex leverage for 1-Step and 3-Step evaluation; current Forex selector simultaneously displays 1:100 maximum on 1-Step Standard. Program-specific 1-Step Standard rules article omits a leverage statement. Preserve the conflict.'
where firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian')
  and source_url = 'https://help.blueguardian.com/en/articles/9661525-platform-rules';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Reopened 2026-09-30. General Platform Rules specify 1:50 Forex leverage for 1-Step and 3-Step evaluation; current Forex selector simultaneously displays 1:100 maximum on 1-Step Standard. Program-specific 1-Step Standard rules article omits a leverage statement. Preserve the conflict.'
where program_id = (
    select p.id from bullish_banana.programs p
    join bullish_banana.firms f on f.id = p.firm_id
    where f.slug = 'blue-guardian' and p.slug = '1-step-standard'
  )
  and source_url = 'https://help.blueguardian.com/en/articles/9661525-platform-rules';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.blueguardian.com/en/articles/14062186-1-step-standard-rules', 'Blue Guardian 1-Step Standard rules', 'Rechecked 2026-09-30. Current offer description, risk, payout and trading conditions are detailed; no leverage value is stated in the article. Current selector and general Platform Rules disagree on Forex leverage.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian' and p.slug = '1-step-standard'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://help.blueguardian.com/en/articles/14062186-1-step-standard-rules'
  );

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Current main-site Terms, footer, dedicated checkout Evaluation Terms, current 1-Step Standard rules, Forex selector and platform rules rechecked 2026-09-30. Legal entities have distinct roles; checkout contracting party remains unresolved. The selector and platform-rules page conflict on 1-Step Standard leverage; the program rules article omits it.'
where firm_id = (select id from bullish_banana.firms where slug = 'blue-guardian');

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Current 1-Step Standard product rules and interactive selector rechecked 2026-09-30. The selector shows 1:100 while general current platform rules state 1:50 for 1-Step evaluation; the model-specific rules article omits leverage. Program remains in_review pending resolution of this configuration scope and complete entity/checkout evidence.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'blue-guardian' and p.slug = '1-step-standard'
);
