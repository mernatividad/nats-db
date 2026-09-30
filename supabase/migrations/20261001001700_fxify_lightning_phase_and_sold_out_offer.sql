begin;

-- FXIFY Lightning is a current one-step offer; its normalized phase was missing.
insert into bullish_banana.program_phases (
  program_id, name, phase_number, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, raw_rules
)
select p.id, 'Lightning Evaluation', 1, 5, 3, 4, 'trailing', 5,
  '{"consistency_percent":30,"consistency_applies_to":"Challenge and funded stages","stop_loss_required":true,"daily_loss_basis":"Previous day balance at 5 PM EST","drawdown_reference":"Trailing highest closed balance; locks at starting balance","source_note":"Current official FXIFY Lightning product page and FAQs reviewed 2026-09-30. Five-day pass window is shown on the current product page."}'::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'lightning-challenge'
  and not exists (select 1 from bullish_banana.program_phases ph where ph.program_id = p.id);

update bullish_banana.programs p
set description = 'One-step simulated Forex evaluation with a 5% target and five-day pass window. It uses a 3% daily limit, 4% trailing maximum drawdown, and a 30% consistency rule.',
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platforms', '["MetaTrader 5"]'::jsonb,
      'evaluation_rules', 'One phase; 5% target; 3% daily loss; 4% trailing max loss; 30% consistency rule; five-day window; mandatory stop loss unless the no-stop-loss add-on is selected.',
      'account_size_price_note', coalesce(p.commercial_details->>'account_size_price_note', 'The current official page confirms available sizes up to $100,000 but does not expose a complete current size/fee matrix in the reviewed page capture; confirm the live selector.')
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fxify' and p.slug = 'lightning-challenge';

-- This candidate's current official product page is explicitly sold out, so it
-- is retained in catalog history and removed from active challenge discovery.
update bullish_banana.programs p
set status = 'archived', published_at = null, updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'crypto-fund-trader' and p.slug = 'break-evaluation'
  and p.status <> 'archived';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('fxify','lightning-challenge','https://fxify.com/programs/lightning-challenge/','Lightning Challenge product page','Current official product page lists one phase, a 5% target, five-day pass window, and account sizes up to $100,000; reviewed 2026-09-30.'),
  ('fxify','lightning-challenge','https://fxify.com/faqs/all-faqs/lightning-plan/lighting-plan-whats-the-daily-drawdown-limit/','Lightning daily drawdown FAQ','Official FAQ states a 3% Lightning daily drawdown; reviewed 2026-09-30.'),
  ('fxify','lightning-challenge','https://fxify.com/faqs/all-faqs/how-do-you-calculate-the-daily-loss-limit/','Daily loss calculation FAQ','Official FAQ explains the daily reference balance and Lightning daily loss; reviewed 2026-09-30.'),
  ('fxify','lightning-challenge','https://fxify.com/faqs/all-faqs/lightning-plan/lighting-plan-whats-the-consistency-rule/','Lightning consistency FAQ','Official FAQ states a 30% consistency rule for challenge and live stages; reviewed 2026-09-30.'),
  ('crypto-fund-trader','break-evaluation','https://cryptofundtrader.com/break/','Break evaluation offer availability','Official offer page reviewed 2026-09-30; the Break product is marked sold out. Historical rules and price conflicts remain in the archived record.')
) as x(firm_slug, program_slug, source_url, source_label, notes)
  on x.firm_slug = f.slug and x.program_slug = p.slug
where not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.source_url);

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'FXIFY Lightning phase details verified from current official product and FAQ sources on 2026-09-30; current size/fee matrix remains unconfirmed in the captured public page. Crypto Fund Trader Break was confirmed sold out on its official offer page and archived from current discovery.')
where v.program_id in (
  select p.id from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
  where (f.slug = 'fxify' and p.slug = 'lightning-challenge')
     or (f.slug = 'crypto-fund-trader' and p.slug = 'break-evaluation')
);

commit;
