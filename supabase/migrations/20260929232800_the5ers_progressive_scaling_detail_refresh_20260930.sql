set search_path = bullish_banana, extensions, public;

update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
      'performance_rules', 'Official High Stakes scaling table, checked 2026-09-30, lists balance steps and 10% balance targets. Published payout ratios: $2,500 through $150,000 steps: 80%/20%; $175,000 and $200,000: 85%/15%; $250,000 and $300,000: 90%/10%; $350,000, $400,000, and $450,000: 100%/0% plus a stated $4,000 fixed payout; $500,000: 100%/0% plus a stated $10,000 fixed payout. The page does not define in this table how the fixed payout interacts with withdrawal timing; do not read this as an evaluation purchase fee or a guaranteed funded payout.',
      'scaling_schedule_source', 'https://the5ers.com/high-stakes/',
      'scaling_schedule_verified_at', '2026-09-30'
    ),
    updated_at = now()
where slug = 'high-stakes'
  and firm_id = (select id from bullish_banana.firms where slug = 'the5ers');

update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
      'performance_rules', 'Official Growth page scaling table, checked 2026-09-30, says the balance scales after each 10% target. It displays 75%/25% from $5,000 through $300,000 steps, 80%/20% at $350,000, then the literal range “80%-100%” at $400,000, $450,000, and $500,000. The page does not assign a specific split within those final ranges. This scaling table does not establish the available challenge purchase sizes, fees, or payout timing.',
      'scaling_schedule_source', 'https://the5ers.com/hyper-growth/',
      'scaling_schedule_verified_at', '2026-09-30'
    ),
    updated_at = now()
where slug = 'hyper-growth'
  and firm_id = (select id from bullish_banana.firms where slug = 'the5ers');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Current official High Stakes scaling table rechecked 2026-09-30. Lists balance steps, 10% targets and changing payout ratios; final steps state 100%/0% plus fixed payout amounts. These are scaling terms, not entry fees or a complete payout schedule.'
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers')
  and source_url = 'https://the5ers.com/high-stakes/';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Current official Growth/Hyper Growth page rechecked 2026-09-30. Displays balance steps, 10% scaling targets and payout ratios from 75%/25% to 80%/20%, with literal “80%-100%” ranges at $400K, $450K, and $500K; page does not assign an exact split within those ranges. This schedule does not establish entry-size pricing or payout timing.'
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers')
  and source_url = 'https://the5ers.com/hyper-growth/';

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'High Stakes current challenge page and scaling table rechecked 2026-09-30; progressive targets and displayed payout ratios are captured in performance rules. Program remains in review for complete entry fees, selector mapping, fee-refund scope and checkout entity.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'the5ers' and p.slug = 'high-stakes'
);

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Growth/Hyper Growth current page and scaling table rechecked 2026-09-30; the published 10% scaling target and displayed payout-ratio progression are captured with the page’s ambiguous 80%-100% range preserved. Program remains in review for current offer naming, fee/size matrix, and payout timing.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'the5ers' and p.slug = 'hyper-growth'
);
