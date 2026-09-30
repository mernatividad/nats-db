begin;

-- Keep the normalized percentage fields when an official rule is expressed as
-- a cash amount or explicitly has no daily loss limit.
update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily loss limit during the SimFi Challenge. The 2% soft daily pause applies only to the funded SimFi Performance stage.',
  'maximum_drawdown_rule', 'End-of-day dynamic loss limit by account size; it locks at the initial balance.',
  'drawdown_by_account_size', '[{"account_size":25000,"max_loss":1000},{"account_size":50000,"max_loss":2000},{"account_size":100000,"max_loss":3000},{"account_size":150000,"max_loss":4500}]'::jsonb
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id
  and f.slug = 'e8-markets'
  and p.slug = 'e8-signature-forex'
  and ph.phase_number = 1;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily loss limit; the official guide lists the daily loss limit as None.',
  'maximum_drawdown_rule', '5% trailing maximum loss based on closed balance, recalculated at the 22:00 UTC daily reset and capped at starting balance.'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id
  and f.slug = 'tradeify-fx'
  and p.slug = 'daily-1-step'
  and ph.phase_number = 1;

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Phase disclosures refreshed 2026-09-30 against current official E8 Signature Forex and Tradeify FX Daily (1-Step) guides; evaluation-stage scope is distinguished from funded-stage rules.')
where v.program_id in (
  select p.id
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where (f.slug = 'e8-markets' and p.slug = 'e8-signature-forex')
     or (f.slug = 'tradeify-fx' and p.slug = 'daily-1-step')
);

commit;
