set search_path = bullish_banana, extensions, public;

-- The current High Stakes page independently confirms its published scaling
-- ratios and fixed amounts. Its footer's restrictions differ from the current
-- Terms page, so retain both scopes pending checkout eligibility confirmation.
update bullish_banana.programs
set commercial_details = coalesce(commercial_details, '{}'::jsonb) || jsonb_build_object(
      'high_stakes_scaling_page_rechecked_at', '2026-09-30',
      'high_stakes_scaling_scope_note', 'Current official High Stakes page rechecked 2026-09-30. It explicitly lists 80%/20% through $150K, 85%/15% at $175K and $200K, 90%/10% at $250K and $300K, then 100%/0% plus $4,000 fixed payout at $350K/$400K/$450K and $10,000 at $500K. The page does not define timing/conditions for the fixed amounts; this is not an entry fee or a guaranteed payout.',
      'public_checkout_visibility_note', 'The linked official Hub was rechecked anonymously on 2026-09-30. It presents a sign-in/sign-up email gate and does not expose the offer selector or the remaining size fees before authentication. Do not infer or fill missing prices from promotions or examples.',
      'current_page_restriction_scope', 'The current High Stakes page footer lists restricted territories but omits Bosnia and Herzegovina, which appears in the current Terms. The Terms call their list non-exhaustive. Preserve both source scopes and confirm actual checkout eligibility before publication.'
    ),
    updated_at = now()
where slug = 'high-stakes'
  and firm_id = (select id from bullish_banana.firms where slug = 'the5ers');

update bullish_banana.firm_profiles
set profile_details = profile_details || jsonb_build_object(
      'current_page_footer_restrictions_verified_at', '2026-09-30',
      'current_page_footer_forbidden_territories', jsonb_build_array(
        'Afghanistan','Belarus','Burundi','Central African Republic','Cuba','Congo Republic','Crimea','Democratic Republic of Congo','Eritrea','Guinea','Guinea-Bissau','Iraq','Iran','Israel','Laos','Lebanon','Liberia','Libya','Myanmar','North Korea','Palestinian Territory','Papua New Guinea','Russia','South Sudan','Sudan','Somalia','Syria','Vanuatu','Venezuela','Yemen'
      ),
      'restriction_source_conflict', 'The current page footer omits Bosnia and Herzegovina from the current Terms list. Terms describe their list as non-exhaustive. Checkout eligibility and contracting entity remain unconfirmed.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official High Stakes page reopened 2026-09-30. It lists 10%/5% targets, 5% daily loss, 10% max loss, three profitable days, unlimited time, 1:100, MT5 Hedge, and explicit scaling ratios plus fixed amounts at top balance levels. Footer restriction list omits Bosnia and Herzegovina, which appears in current Terms; preserve source-scope difference and verify checkout eligibility.'
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers')
  and source_url = 'https://the5ers.com/high-stakes/';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://hub.the5ers.com/en/', 'The5ers public Hub access check', 'Checked anonymously 2026-09-30. The public landing view requires sign-in/sign-up and does not show a challenge selector or complete size/fee matrix. This is a public-access limitation, not evidence that a selector does not exist.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'high-stakes'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = 'https://hub.the5ers.com/en/'
  );

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'High Stakes official product page rechecked 2026-09-30. Page explicitly states the top-level 100%/0% ratios and fixed payout amounts; payout timing/conditions remain unstated. The page footer restriction list omits Bosnia and Herzegovina, which appears in current Terms. Program remains in review for complete size/fee schedule, New/Classic checkout mapping, refund-scope reconciliation and checkout entity.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'the5ers' and p.slug = 'high-stakes'
);
