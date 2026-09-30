-- Record the specific Lite minimum-days FAQ without resolving the separate
-- payout cadence conflict between the selector and shared product footer.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'minimum_days_faq_2026_09_30', 'FXIFY Lite FAQ says there is no maximum trading duration or profit target; to meet its consistency rule, a minimum of 5 trading days is required and total 10 days. The FAQ does not define whether “total 10 days” means calendar days or another period; retain the existing five minimum trading days field and do not infer more.',
      'payout_cadence_conflict_2026_09_30', 'The Lite selector says payouts every 10 days. The shared Instant Funding page footer says every 14 days, and the Standard payout FAQ describes the first payout after 14 days. Lite-specific cadence remains unresolved.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'instant-funding-lite';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/faqs/all-faqs/instant-funding-lite-faq/instant-funding-lite-whats-the-max-and-minimum-trading-days-is-there-a-specific-time-window-to-complete-the-profit-targets/',
       'Instant Funding Lite FAQ — minimum and total days — 2026-09-30',
       'FXIFY Lite FAQ says there is no maximum trading days or profit target. To meet the consistency rule, it requires at least 5 trading days and “total 10 days.” The FAQ does not define the meaning of total 10 days. It does not clarify payout cadence; selector says 10 days while shared page footer says 14 days.',
       '2026-09-30 00:00:00+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug = 'instant-funding-lite'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://fxify.com/faqs/all-faqs/instant-funding-lite-faq/instant-funding-lite-whats-the-max-and-minimum-trading-days-is-there-a-specific-time-window-to-complete-the-profit-targets/'
      and s.source_label = 'Instant Funding Lite FAQ — minimum and total days — 2026-09-30'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 00:00:00+00'::timestamptz,
       'Reviewed FXIFY Instant Funding Lite minimum-days FAQ on 2026-09-30: at least 5 trading days and total 10 days for consistency; FAQ does not define total-days meaning or payout cadence. Keep program in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify'
  and p.slug = 'instant-funding-lite'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30 00:00:00+00'::timestamptz
      and v.notes like 'Reviewed FXIFY Instant Funding Lite minimum-days FAQ on 2026-09-30%'
  );
