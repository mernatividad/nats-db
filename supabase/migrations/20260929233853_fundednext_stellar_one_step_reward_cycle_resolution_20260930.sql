set search_path = bullish_banana, extensions, public;

-- Current U.S. product rules and current Help Center cycle guidance agree on a
-- five-business-day trading cycle. The account must be profitable at cycle-end
-- to request a reward; an unprofitable cycle extends in five-business-day steps.
update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    payout_frequency = 'Request after a profitable 5-business-day trading cycle; later cycles remain 5 business days',
    commercial_details = p.commercial_details || jsonb_build_object(
      'payout_rules', 'Current U.S. product page and Help Center cycle guidance state that Stellar 1-Step rewards follow 5-business-day trading cycles. The first request is available after the first 5-business-day cycle if account growth satisfies eligibility; subsequent cycles are also 5 business days. If the account is not profitable at cycle end, the cycle extends in 5-business-day increments until profitable. U.S. starting reward share is 80%, scaling to 90%; the optional Lifetime Reward 95% add-on is available. The challenge subscription fee is refundable with the third reward. The global 15% challenge-phase reward is not available to U.S. accounts.',
      'reward_cycle_days', 5,
      'reward_cycle_unit', 'business days',
      'reward_eligibility_note', 'An unprofitable account at cycle end does not become reward-eligible; the cycle extends by another five business days.',
      'review_note', 'The current U.S. product page and current trading-cycle Help Center articles agree on 5 business days. Older generic comparison wording of “within 7 days” is superseded; no unresolved reward-timing conflict remains for the U.S. offer.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fundednext'
  and p.slug = 'stellar-1-step';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://help.fundednext.com/en/articles/9428239-what-is-the-trading-cycle-count-in-my-stellar-1-step-fundednext-account', 'Stellar 1-Step trading-cycle duration', 'Official Help Center article updated the week of 2026-09-30. A cycle is exactly five business days, excluding weekends and public holidays; after the first cycle, a profitable account can request a reward.'),
  ('https://help.fundednext.com/en/articles/9929008-what-happens-when-the-trading-cycle-ends', 'Stellar 1-Step cycle-end behavior', 'Official Help Center article states Stellar 1-Step cycles remain five business days and extend by additional five-business-day increments when the account is not profitable at cycle end.'),
  ('https://help.fundednext.com/en/articles/10701585-how-often-will-i-receive-my-performance-reward', 'Stellar 1-Step reward schedule', 'Official reward-frequency article updated 2026-09-16 (approx. two weeks before check); says the funded Stellar 1-Step schedule begins with the first trading cycle and repeats every five business days, with the refundable subscription fee available at the third reward.')
) as x(source_url, source_label, notes)
where f.slug = 'fundednext'
  and p.slug = 'stellar-1-step'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = x.source_url
  );

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official U.S. Stellar 1-Step page rechecked 2026-09-30. It describes the first and subsequent reward cycle as five business days; the current comparison row now also shows five business days. The base U.S. fee matrix is retained separately from visible temporary discounts.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundednext' and p.slug = 'stellar-1-step'
)
  and source_url = 'https://fundednext.com/usa/cfds/stellar-1-step';

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'FundedNext Stellar 1-Step rules, U.S. base-price matrix and reward conditions rechecked 2026-09-30. Current U.S. product page and Help Center cycle articles agree: a reward request is available after a profitable five-business-day cycle; later cycles repeat every five business days, and unprofitable cycles extend in five-business-day steps. Older “within 7 days” comparison wording is superseded. Program detail and evidence are complete for the captured U.S. offer.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundednext' and p.slug = 'stellar-1-step'
);
