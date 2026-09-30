set search_path = bullish_banana, extensions, public;

update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
      'account_limitations', 'Official High Stakes guidance distinguishes account limits by configuration. Classic: up to four active accounts—one $2.5K, one $5K, one of $10K or $25K, and one of $50K or $100K. New: up to three each at $2.5K, $5K, and $10K, one $25K, and one of $50K or $100K. New and Classic may be held together while each configuration stays within its own limit. Across both configurations, $50K and $100K tiers cannot be duplicated; $2.5K, $5K, $10K, and $25K can be duplicated. These are account-capacity rules; New and Classic are not confirmed as separate challenge rule sets.',
      'account_limit_verification_date', '2026-09-30',
      'account_limit_source', 'https://the5ers.com/faqs/how-many-high-stakes-accounts-can-i-have/'
    ),
    updated_at = now()
where slug = 'high-stakes'
  and firm_id = (select id from bullish_banana.firms where slug = 'the5ers');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official High Stakes account-limit FAQ rechecked 2026-09-30. Classic allows one each at $2.5K and $5K, one of $10K/$25K, and one of $50K/$100K; New allows three each at $2.5K/$5K/$10K, one $25K and one of $50K/$100K. Cross-configuration rules allow duplicate smaller tiers but only one $50K or $100K across both. This confirms capacity rules, not separate challenge products.'
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers')
  and source_url = 'https://the5ers.com/faqs/how-many-high-stakes-accounts-can-i-have/';

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Official High Stakes account-limit FAQ rechecked 2026-09-30. Current New and Classic caps and cross-configuration duplication rules are recorded. The full size/fee selector matrix, variant-to-checkout mapping, fee-refund scope, and contracting entity remain unresolved; program stays in review.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'the5ers' and p.slug = 'high-stakes'
);
