-- CTI refund, commission, and regional platform evidence captured 2026-09-30.
-- Keep programs in_review: the 1-Step price discrepancy and commissions for
-- the other three products remain unresolved.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "platform_availability_note":"Official CTI platform pages reviewed 2026-09-30 say MetaTrader 5 is available in most countries but not to U.S. clients; Match-Trader is available worldwide, including the U.S. Both are presented as CTI platforms. Platform availability may still depend on local eligibility and the selected product; confirm at checkout.",
  "platform_capabilities_note":"Official Match-Trader page says MT5 Expert Advisors do not run on Match-Trader. Traders relying on MT5 EAs should confirm platform eligibility before purchase.",
  "refund_policy":"Current Fee & Refund Policy reviewed 2026-09-30: assessment-account refunds are unavailable after at least one simulated demo transaction. A refund may be requested within 7 calendar days of purchase if the assessment account remains completely inactive (no transactions opened and no account activity). Refunds must be requested from support and are processed to the original payment method if eligible. The separate course lesson allowance is not applied to assessment programs.",
  "refund_policy_url":"https://citytradersimperium.com/fee-refund-policy/"
}'::jsonb,
updated_at=now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='city-traders-imperium';

update bullish_banana.programs p
set commercial_details = p.commercial_details || case p.slug
  when '1-step-challenge' then '{
    "commission_details":"Official CTI 1-Step payout guide says all 1-Step funded accounts use a $5 per lot commission on standard forex pairs. This source does not establish evaluation-phase commissions or terms for non-standard forex symbols.",
    "fee_refund_policy":"Current official Fee & Refund Policy reviewed 2026-09-30: refunds are unavailable after at least one simulated demo transaction. A request may be made within 7 calendar days of purchase only if the assessment account remains completely inactive. Follow the support request process; eligibility must be confirmed by CTI.",
    "platform_availability":"CTI states MT5 is available in most countries except the U.S.; Match-Trader is available worldwide including the U.S. Confirm eligible platform at checkout. MT5 EAs do not run on Match-Trader."
  }'::jsonb
  else '{
    "fee_refund_policy":"Current official Fee & Refund Policy reviewed 2026-09-30: refunds are unavailable after at least one simulated demo transaction. A request may be made within 7 calendar days of purchase only if the assessment account remains completely inactive. Follow the support request process; eligibility must be confirmed by CTI.",
    "platform_availability":"CTI states MT5 is available in most countries except the U.S.; Match-Trader is available worldwide including the U.S. Confirm eligible platform at checkout. MT5 EAs do not run on Match-Trader.",
    "commission_details":"No commission amount for this program was established from the reviewed official product-specific sources; confirm standard and non-standard symbol costs before publication."
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
 ('https://citytradersimperium.com/fee-refund-policy/','Fee & Refund Policy','Reviewed 2026-09-30. Assessment account refund request is limited to 7 calendar days while completely inactive; no refund after a simulated demo transaction. Includes the support request process.'),
 ('https://citytradersimperium.com/metatrader5-mt5-prop-firm/','MetaTrader 5 platform availability','Reviewed 2026-09-30. Official CTI page says MT5 is available in most countries except the United States; Match-Trader is available worldwide, including the United States.'),
 ('https://citytradersimperium.com/match-trader-platform/','Match-Trader platform details','Reviewed 2026-09-30. Official page states worldwide availability including the United States and that MT5 Expert Advisors do not run on Match-Trader.'),
 ('https://citytradersimperium.com/optimising-payouts-scaliing/','1-Step commission and payout guide','Reviewed 2026-09-30. States all 1-Step funded accounts use $5 per lot commission on standard forex pairs; does not establish evaluation-phase or other program commissions.')
) as x(url,label,notes) on true
where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('1-step-challenge','https://citytradersimperium.com/fee-refund-policy/','Fee & Refund Policy','Assessment refunds are limited to 7 calendar days while completely inactive; no refund after a simulated demo transaction.'),
 ('2-step-challenge','https://citytradersimperium.com/fee-refund-policy/','Fee & Refund Policy','Assessment refunds are limited to 7 calendar days while completely inactive; no refund after a simulated demo transaction.'),
 ('instant-funding','https://citytradersimperium.com/fee-refund-policy/','Fee & Refund Policy','Assessment refunds are limited to 7 calendar days while completely inactive; no refund after a simulated demo transaction.'),
 ('direct-funding','https://citytradersimperium.com/fee-refund-policy/','Fee & Refund Policy','Assessment refunds are limited to 7 calendar days while completely inactive; no refund after a simulated demo transaction.'),
 ('1-step-challenge','https://citytradersimperium.com/optimising-payouts-scaliing/','1-Step commission evidence','Official guide states all 1-Step funded accounts have a $5 per lot commission on standard forex pairs; evaluation commissions and other symbols are not established.'),
 ('1-step-challenge','https://citytradersimperium.com/metatrader5-mt5-prop-firm/','Regional platform availability','MT5 unavailable to U.S. clients; Match-Trader available worldwide including U.S. Confirm at checkout.'),
 ('2-step-challenge','https://citytradersimperium.com/metatrader5-mt5-prop-firm/','Regional platform availability','MT5 unavailable to U.S. clients; Match-Trader available worldwide including U.S. Confirm at checkout.'),
 ('instant-funding','https://citytradersimperium.com/metatrader5-mt5-prop-firm/','Regional platform availability','MT5 unavailable to U.S. clients; Match-Trader available worldwide including U.S. Confirm at checkout.'),
 ('direct-funding','https://citytradersimperium.com/metatrader5-mt5-prop-firm/','Regional platform availability','MT5 unavailable to U.S. clients; Match-Trader available worldwide including U.S. Confirm at checkout.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'Official Fee & Refund Policy and platform pages reviewed 2026-09-30. Refund eligibility and regional platform limitations recorded. CTI 1-Step funded-account standard Forex commission source found; commissions for the other programs remain unverified. All four programs remain in_review pending remaining terms and price reconciliation.'
from bullish_banana.firms f where f.slug='city-traders-imperium';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),case p.slug
  when '1-step-challenge' then 'Official Fee & Refund Policy, regional platform availability, and 1-Step funded-account commission guidance reviewed 2026-09-30. Evaluation commission and the product/editorial fee mismatch remain unresolved; program remains in_review.'
  else 'Official Fee & Refund Policy and regional platform availability reviewed 2026-09-30. Program-specific commission evidence remains unresolved; program remains in_review.'
end
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='city-traders-imperium'
  and p.slug in ('1-step-challenge','2-step-challenge','instant-funding','direct-funding');
