-- FXIFY's Lite-specific support articles qualify the category-wide Instant
-- payout copy. Record the direct Lite first-payout conditions and preserve the
-- selector's separately stated 10-day recurring cycle.
update bullish_banana.programs p
set payout_frequency = 'First payout request: 10 calendar days after the first trade, with at least 5 trading days, the 20% consistency rule, and a $50 minimum withdrawal. The current Lite selector shows a 10-day payout cycle; the dedicated FAQ/blog only specifies first request timing. The generic 14-day Instant Funding footer is not Lite-specific.',
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'payout_window_resolution_2026_09_30', 'Dedicated Instant Funding Lite payout FAQ: first payout request after 5 trading days and 10 total calendar days from first trade, minimum $50, no profit target. Dedicated 20% consistency FAQ: the biggest profit day must be no more than 20% of total profit; the 10-day clock runs from first trade and payout becomes available once both time and consistency requirements are met. The official September 9, 2026 payout guide separately lists Lite first request at 10 calendar days, 5 trading days, 20% consistency and $50 minimum, while later requests are “check current programme rules.” Live Lite selector shows a 10-day payout cycle. The general 14-day Instant Funding footer does not specify Lite and does not override the dedicated Lite rules.',
      'payout_cycle_scope_note_2026_09_30', 'Represent first-request eligibility as verified after 10 calendar days plus the listed trading-day, consistency and withdrawal thresholds. The 10-day recurring cycle is selector evidence; dedicated FAQ/blog specify first-request conditions but do not independently repeat subsequent cadence.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'instant-funding-lite';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       src.source_url,
       src.source_label,
       src.notes,
       '2026-09-30 02:34:06+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  (
    'https://fxify.com/faqs/all-faqs/instant-funding-lite-faq/instant-funding-lite-after-purchasing-what-criteria-must-i-achieve-to-request-a-payout/',
    'Instant Funding Lite FAQ — first payout eligibility — 2026-09-30',
    'Dedicated Lite FAQ states payout requests require compliance with program rules, 5 trading days, 10 days total from first trade, and a $50 minimum; no profit target is required.'
  ),
  (
    'https://fxify.com/faqs/all-faqs/instant-funding-lite-how-does-the-20-consistency-rule-work/',
    'Instant Funding Lite FAQ — consistency and 10-day clock — 2026-09-30',
    'Dedicated Lite FAQ defines 20% consistency as the largest profit day being no more than one fifth of total profit. It explains that after consistency is met, the trader may wait/trade as desired until 10 days from first trade are complete; payout is then enabled. No trade for 60 consecutive calendar days is an inactivity breach.'
  ),
  (
    'https://fxify.com/blog/prop-firm-payout-process/',
    'FXIFY payout process guide — published 2026-09-09 — Instant Funding Lite — 2026-09-30 capture',
    'Official dated guide lists Lite first payout request 10 calendar days after first trade, subsequent requests as “check current programme rules,” 5 trading days, 20% consistency and $50 minimum. It distinguishes request eligibility from processing and fund arrival.'
  )
) as src(source_url, source_label, notes)
where f.slug = 'fxify'
  and p.slug = 'instant-funding-lite'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = src.source_url
      and s.source_label = src.source_label
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 02:34:06+00'::timestamptz,
       'Reviewed FXIFY Instant Funding Lite payout FAQ, consistency FAQ and official payout process guide on 2026-09-30. First payout eligibility is confirmed after 10 calendar days from first trade plus 5 trading days, 20% consistency and $50 minimum. Selector supplies a 10-day payout cycle; the dated payout guide says later timing depends on current selected-program rules. Generic 14-day footer is not Lite-specific. Program remains in_review for other unresolved terms.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug = 'instant-funding-lite'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30 02:34:06+00'::timestamptz
      and v.notes like 'Reviewed FXIFY Instant Funding Lite payout FAQ, consistency FAQ and official payout process guide on 2026-09-30%'
  );
