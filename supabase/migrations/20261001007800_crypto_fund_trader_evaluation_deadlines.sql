begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_days', 0,
      'time_limit_note', 'Crypto Fund Trader states evaluations have no maximum time limit. This applies to evaluation phases; funded-stage inactivity and payout conditions are separate.',
      'time_limit_scope', 'Crypto Fund Trader 1-Phase, 2-Phase, and Ascend Forex evaluation phases',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'crypto-fund-trader'
  and p.slug in ('1-phase-evaluation','2-phase-evaluation','ascend-evaluation')
  and p.market_type = 'forex';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://cryptofundtrader.com/faq/',
  'Crypto Fund Trader evaluation duration FAQ — ' || p.name || ' — 2026-10-01',
  'The current official FAQ names the 1-Phase and 2-Phase evaluation models and states there is no maximum time limit to complete an evaluation. The deadline is recorded for challenge phases; funded-stage inactivity rules are not treated as the evaluation deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'crypto-fund-trader'
  and p.slug in ('1-phase-evaluation','2-phase-evaluation','ascend-evaluation')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Crypto Fund Trader evaluation duration FAQ — ' || p.name || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked the current official Crypto Fund Trader FAQ. It states there is no maximum evaluation duration. Recorded the deadline as unlimited for this evaluation program, separately from post-evaluation funded-stage rules.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'crypto-fund-trader'
  and p.slug in ('1-phase-evaluation','2-phase-evaluation','ascend-evaluation')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz);

commit;
