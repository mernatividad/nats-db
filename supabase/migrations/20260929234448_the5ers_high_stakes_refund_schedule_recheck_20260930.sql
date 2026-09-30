set search_path = bullish_banana, extensions, public;

-- Preserve both current official High Stakes fee-reward schedules. The
-- September 14 payout policy says 70% may be withdrawn with the first
-- eligible payout; the August 11 evaluation-fee article says the remaining
-- 70% is paid with the third payout milestone. Do not publish until scoped.
update bullish_banana.programs
set commercial_details = coalesce(commercial_details, '{}'::jsonb) || jsonb_build_object(
      'fee_refund_policy', 'Official High Stakes payout policy updated 2026-09-14 says 10% of the initial fee is granted as Hub Credit after Step 1, 20% as Hub Credit after Step 2, and 70% is added to funded-account equity and withdrawable with the first payout after at least 14 active days and $150 P&L; only the externally paid portion qualifies. A separate official evaluation-fee refund article updated 2026-08-11 says the remaining 70% is paid as withdrawable cash with the third profit payout. Current Terms separately say evaluation fees are non-refundable after evaluation trading begins. These sources differ in reward timing and scope; keep unresolved pending direct program/checkout clarification.',
      'fee_refund_verification_date', '2026-09-30',
      'review_note', 'High Stakes remains in review: the size/fee matrix and New/Classic checkout mapping are incomplete, and official fee-reward materials conflict on whether the remaining 70% is available with first or third payout.'
    ),
    updated_at = now()
where slug = 'high-stakes'
  and firm_id = (select id from bullish_banana.firms where slug = 'the5ers');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official High Stakes overview rechecked 2026-09-30. Current page lists $2.5K, $5K, $10K, $25K, $50K, and $100K account sizes, but its displayed base-fee row gives only $2.5K at $19. The page also carries a separate limited-time $100K for $149 banner with no checkout conditions or expiry shown. Its Start CTA links to the official Hub; an anonymous public fetch redirects to the English portal and exposes no size/price selector. This retrieval result does not establish that no selector exists. Do not treat the promotion as a base price or infer other size fees; the New/Classic labels appear as account-capacity configurations, with no distinct rule or price matrix established.'
where firm_id = (select id from bullish_banana.firms where slug = 'the5ers')
  and source_url = 'https://the5ers.com/high-stakes/';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official High Stakes overview rechecked 2026-09-30. Current page lists $2.5K, $5K, $10K, $25K, $50K, and $100K account sizes, but its displayed base-fee row gives only $2.5K at $19. A separate limited-time $100K for $149 banner has no visible checkout conditions or expiry. The Start CTA links to the official Hub; an anonymous public fetch redirects to the English portal and exposes no size/price selector, which does not prove no selector exists. Do not treat the promotion as a base price or infer other size fees; New/Classic remain account-capacity configurations without a confirmed distinct rule or price matrix.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'the5ers' and p.slug = 'high-stakes'
)
  and source_url = 'https://the5ers.com/high-stakes/';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://the5ers.com/high-stakes/', 'Current High Stakes sizes and pricing disclosure (2026-09-30)', 'The current page lists $2.5K, $5K, $10K, $25K, $50K, and $100K account sizes but displays a $19 base fee only for $2.5K. A separate limited-time banner advertises $100K for $149 without visible checkout conditions/expiry. The Start CTA links to the official Hub, but the anonymously fetched Hub portal exposed no size/price selector; this does not prove a selector is unavailable. This does not establish the missing base fees or distinct New/Classic pricing.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers'
  and p.slug = 'high-stakes'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = 'https://the5ers.com/high-stakes/'
  );

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://the5ers.com/faqs/payout-policy-and-hub-credit-in-the-high-stakes-program/', 'High Stakes payout policy and Hub Credit (updated 2026-09-14)', 'Current official article: 10% fee value as Hub Credit after Step 1, 20% after Step 2, and 70% added to funded-account equity and withdrawable with the first payout after at least 14 active days and $150 P&L; applies only to the externally paid portion.'),
  ('https://the5ers.com/faqs/how-do-i-receive-my-evaluation-fee-refund-and-summer-boost-credits-2/', 'Evaluation fee refund and Summer Boost Credits (updated 2026-08-11)', 'Official article says 10% and 20% are issued as Hub Credits at Steps 1 and 2, while the remaining 70% is withdrawable cash alongside the third profit payout. This differs from the current High Stakes payout-policy article, which says the 70% is available with the first eligible payout; scope/timing remains unresolved.'),
  ('https://the5ers.com/terms-and-conditions/', 'Current Terms refund clause (rechecked 2026-09-30)', 'Current Terms say the evaluation fee becomes non-refundable once evaluation trading starts; before trading, a monetary refund may be requested within five days, or Hub Credit after five days, subject to no breach. Reconcile with program-specific fee-reward articles before publication.'),
  ('https://hub.the5ers.com/', 'The5ers public Hub entry point (rechecked 2026-09-30)', 'The High Stakes overview Start CTA links to this official Hub. The current anonymous fetch redirects to the English portal, whose publicly exposed page contains no size/price selector; this does not prove a selector is unavailable or that purchase prices cannot be fetched through another public flow.')
) as x(source_url, source_label, notes)
where f.slug = 'the5ers'
  and p.slug = 'high-stakes'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = x.source_url
  );

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'High Stakes sources rechecked 2026-09-30. Current payout policy says the 70% externally paid fee amount is withdrawable with the first eligible payout after 14 active days and $150 P&L; a separate evaluation-fee refund article updated 2026-08-11 says third payout; Terms separately say the fee becomes non-refundable after evaluation activity. Preserve this timing/scope conflict. Full size/fee matrix and New/Classic checkout mapping remain open; program stays in review.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'the5ers' and p.slug = 'high-stakes'
);
