-- CTI payout and refund-source refresh captured 2026-09-30.
-- The separate Refund Policy could not be accessed; keep all programs in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = p.commercial_details || case p.slug
  when '1-step-challenge' then '{
    "first_payout_guide":"Official 1-Step guide updated 2026-09-02 states first payout requires 7 profitable trading days and 2% net profit (or $100, whichever is higher); subsequent payouts are monthly, with weekly/anytime access tied to VIP tiers. Product page short copy only says after 7 days; use the detailed guide wording with attribution.",
    "fee_refund_policy":"Current homepage/Terms say fees are non-refundable except as outlined in the Refund Policy. That policy could not be accessed during the 2026-09-30 review. An official editorial article says a fee refund may apply with the first payout, but does not establish universal eligibility. Do not represent a refund as guaranteed."
  }'::jsonb
  when '2-step-challenge' then '{
    "first_payout_guide":"Current official CTI program-comparison guidance says challenge models require 7 profitable trading days and at least 2% profit for the first payout; later cadence varies by VIP tier. Confirm the applicable 2-Step contract terms before publication.",
    "fee_refund_policy":"Current homepage/Terms say fees are non-refundable except as outlined in the Refund Policy. That policy could not be accessed during the 2026-09-30 review. No plan-specific refund eligibility was verified; do not represent a refund as guaranteed."
  }'::jsonb
  else '{
    "fee_refund_policy":"Current homepage/Terms say fees are non-refundable except as outlined in the Refund Policy. That policy could not be accessed during the 2026-09-30 review. No plan-specific refund eligibility was verified; do not represent a refund as guaranteed."
  }'::jsonb
end,
updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='city-traders-imperium'
  and p.slug in ('1-step-challenge','2-step-challenge','instant-funding','direct-funding');

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes
from bullish_banana.firms f
join (values
 ('https://citytradersimperium.com/','Current homepage legal disclosure','Reviewed 2026-09-30. Identifies City Traders Imperium Limited simulated skill-assessment operator; says all fees are non-refundable except as outlined in the Refund Policy; lists restricted jurisdictions.'),
 ('https://citytradersimperium.com/optimising-payouts-scaliing/','1-Step payout guide','Official editorial guide updated 2026-09-02 states first payout requires 7 profitable trading days and 2% profit; subsequent payouts monthly, with weekly/anytime access through eligible VIP tiers.'),
 ('https://citytradersimperium.com/choosing-your-funding-program/','Challenge payout comparison guide','Official CTI program comparison states both challenge types require 7 profitable trading days and at least 2%/$100 for first payout, followed by monthly payouts.'),
 ('https://citytradersimperium.com/eas-on-cti-1-step-challenge-whats-allowed/','1-Step rules and payout editorial','Official editorial article reviewed 2026-09-30; mentions fee refund with first payout if applicable but does not establish general eligibility. Retained as secondary evidence only.')
) as x(url,label,notes) on true
where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('1-step-challenge','https://citytradersimperium.com/optimising-payouts-scaliing/','1-Step payout guide','Official editorial guide updated 2026-09-02 states first payout threshold and cadence; confirm contract terms.'),
 ('1-step-challenge','https://citytradersimperium.com/eas-on-cti-1-step-challenge-whats-allowed/','1-Step fee refund editorial reference','Fee refund described as applicable in some cases; not sufficient to establish universal eligibility.'),
 ('1-step-challenge','https://citytradersimperium.com/choosing-your-funding-program/','Challenge payout comparison guide','Official CTI comparison guidance for first payout threshold and cadence.'),
 ('2-step-challenge','https://citytradersimperium.com/choosing-your-funding-program/','Challenge payout comparison guide','Official CTI comparison guidance for first payout threshold and cadence; confirm applicable contract terms.'),
 ('1-step-challenge','https://citytradersimperium.com/','Current legal fee disclosure','Homepage says fees are non-refundable except as outlined in the separate Refund Policy; policy was inaccessible during review.'),
 ('2-step-challenge','https://citytradersimperium.com/','Current legal fee disclosure','Homepage says fees are non-refundable except as outlined in the separate Refund Policy; policy was inaccessible during review.'),
 ('instant-funding','https://citytradersimperium.com/','Current legal fee disclosure','Homepage says fees are non-refundable except as outlined in the separate Refund Policy; policy was inaccessible during review.'),
 ('direct-funding','https://citytradersimperium.com/','Current legal fee disclosure','Homepage says fees are non-refundable except as outlined in the separate Refund Policy; policy was inaccessible during review.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'Official homepage legal disclosure and updated 1-Step payout guide reviewed 2026-09-30. Fee refund policy URL remains inaccessible; all four CTI programs remain in_review pending policy and program-level contract confirmation.'
from bullish_banana.firms f
where f.slug='city-traders-imperium';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Official CTI homepage and current payout guidance reviewed 2026-09-30. Refund Policy could not be accessed; no universal fee refund eligibility verified. Program remains in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='city-traders-imperium'
and p.slug in ('1-step-challenge','2-step-challenge','instant-funding','direct-funding');
