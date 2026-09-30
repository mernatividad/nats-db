begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'Unlimited',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', 'Crypto Fund Trader’s current official FAQ states there is no maximum time limit to complete an evaluation and separately documents its 3-Phase Evaluation. This applies to the three evaluation phases; final-stage reward conditions are separate.',
      'time_limit_scope', '1-Phase, 2-Phase, and 3-Phase evaluation challenges',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'crypto-fund-trader'
  and p.slug = '3-phase-evaluation' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://cryptofundtrader.com/faq/',
  'Crypto Fund Trader 3-Phase evaluation deadline — 2026-10-01',
  'The current official FAQ answers that there is no maximum time limit to complete an evaluation and has a separate 3-Phase Evaluation section describing its phases. The deadline is recorded only for those evaluation phases, separate from final-stage reward conditions.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'crypto-fund-trader' and p.slug = '3-phase-evaluation'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Crypto Fund Trader 3-Phase evaluation deadline — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked Crypto Fund Trader’s current official FAQ. It states that there is no maximum evaluation duration and separately documents the 3-Phase Evaluation; recorded for all three evaluation phases.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'crypto-fund-trader' and p.slug = '3-phase-evaluation'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked Crypto Fund Trader’s current official FAQ. It states that there is no maximum evaluation duration and separately documents the 3-Phase Evaluation; recorded for all three evaluation phases.');

commit;
