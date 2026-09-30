-- CTI's current Terms PDF gives a per-side FX commission rate for the
-- simulated skill-assessment service. Preserve that unit and distinguish it
-- from the 1-Step payout guide's $5/lot wording, which does not define a side.
-- This resolves the missing commission amount for CTI's four staged offers;
-- it does not change their review status or resolve other open terms.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'commission_details', 'Current CTI Terms & Conditions of Service §8.19 (August 2026 authoritative PDF linked from CTI''s Terms page) states $2.50 per lot per side for FX. The Terms describe the simulated skill-assessment programs provided by City Traders Imperium Limited. The 1-Step payout guide separately says $5 per lot on standard FX pairs for funded 1-Step accounts; that amount is numerically consistent with $2.50 on entry and exit, but the guide does not define its commission unit. Use the explicit Terms unit when displaying commissions.',
      'commission_value', 2.50,
      'commission_currency', 'USD',
      'commission_unit', 'per lot per side',
      'commission_market', 'FX',
      'commission_scope', 'General Terms §8.19; applies to the CTI simulated skill-assessment service and does not state a different rate by offer or phase.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'city-traders-imperium'
  and p.slug in ('1-step-challenge', '2-step-challenge', 'instant-funding', 'direct-funding');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
       'https://citytradersimperium.com/wp-content/uploads/2026/08/City-Traders-Imperium-Terms-Conditions.pdf',
       'Current Terms & Conditions of Service — FX commissions',
       'Reviewed 2026-09-30. Current August 2026 PDF is linked as the authoritative Terms from CTI''s Terms page. Section 8.19 states $2.50 per lot per side for FX. Sections 2.3 and 2.5 identify City Traders Imperium Limited''s simulated skill-assessment services as the platform/program service; Academy services are separate.'
from bullish_banana.firms f
where f.slug = 'city-traders-imperium'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = 'https://citytradersimperium.com/wp-content/uploads/2026/08/City-Traders-Imperium-Terms-Conditions.pdf'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       evidence.source_url,
       evidence.source_label,
       evidence.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('1-step-challenge', 'https://citytradersimperium.com/wp-content/uploads/2026/08/City-Traders-Imperium-Terms-Conditions.pdf', 'Current Terms §8.19 — FX commission unit', 'Reviewed 2026-09-30. Current August 2026 Terms state $2.50 per lot per side for FX under the general Terms governing CTI skill-assessment programs. The older 1-Step funded payout guide states $5 per lot on standard FX pairs but does not define its unit; preserve both exact source wordings, which are numerically consistent for an entry-and-exit round trip.'),
  ('2-step-challenge', 'https://citytradersimperium.com/wp-content/uploads/2026/08/City-Traders-Imperium-Terms-Conditions.pdf', 'Current Terms §8.19 — FX commission', 'Reviewed 2026-09-30. Current August 2026 Terms state $2.50 per lot per side for FX under the general Terms governing CTI skill-assessment programs; no distinct rate by evaluation/funded phase is stated.'),
  ('instant-funding', 'https://citytradersimperium.com/wp-content/uploads/2026/08/City-Traders-Imperium-Terms-Conditions.pdf', 'Current Terms §8.19 — FX commission', 'Reviewed 2026-09-30. Current August 2026 Terms state $2.50 per lot per side for FX under the general Terms governing CTI skill-assessment programs; no distinct rate for Instant Funding is stated.'),
  ('direct-funding', 'https://citytradersimperium.com/wp-content/uploads/2026/08/City-Traders-Imperium-Terms-Conditions.pdf', 'Current Terms §8.19 — FX commission', 'Reviewed 2026-09-30. Current August 2026 Terms state $2.50 per lot per side for FX under the general Terms governing CTI skill-assessment programs; no distinct rate for Direct Funding is stated.'),
  ('1-step-challenge', 'https://citytradersimperium.com/optimising-payouts-scaliing/', '1-Step funded payout guide — commission wording', 'Reviewed 2026-09-30. The guide says all 1-Step funded accounts use $5 per lot on standard FX pairs without defining whether the amount is per side or round trip. The current Terms separately state $2.50 per lot per side; the values are numerically consistent for an entry-and-exit round trip, but the guide itself does not specify that convention.')
) as evidence(program_slug, source_url, source_label, notes) on evidence.program_slug = p.slug
where f.slug = 'city-traders-imperium'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = evidence.source_url
  );

update bullish_banana.sources s
set notes = concat_ws(' ', nullif(s.notes, ''), 'Rechecked 2026-09-30 against the current August 2026 Terms PDF, §8.19: $2.50 per lot per side for FX. This is numerically consistent with $5 per lot across entry and exit, but the guide does not define its unit; retain the two source wordings with their distinct scope.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'city-traders-imperium'
  and p.slug = '1-step-challenge'
  and s.source_url = 'https://citytradersimperium.com/optimising-payouts-scaliing/';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       timestamptz '2026-09-30 00:00:00+00',
       'Unified FX commission Terms reviewed 2026-09-30: current August 2026 CTI Terms §8.19 states $2.50 per lot per side for FX. The 1-Step payout guide''s $5/lot standard-FX wording is recorded with its undefined unit. This resolves the commission amount for the staged CTI program records; the program remains in_review for other open item(s).'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'city-traders-imperium'
  and p.slug in ('1-step-challenge', '2-step-challenge', 'instant-funding', 'direct-funding')
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like '%Unified FX commission Terms reviewed 2026-09-30%'
  );
