-- Current Funded Trading Plus catalog refresh, reviewed 2026-09-30.
-- Keep offers in review until checkout prices, platform variants and eligibility
-- can be confirmed. The official company site currently serves a bot challenge.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set description = 'A provider of simulated trading evaluations and instant simulated-funded accounts with real-world USD payout requests after meeting program criteria.',
    website_url = 'https://www.fundedtradingplus.com/',
    status = 'published',
    published_at = coalesce(published_at, now()),
    updated_at = now()
where slug = 'funded-trading-plus';

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'funded-trading-plus'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, supported_assets, profile_details)
select id, array['Forex', 'Commodities', 'Indices', 'Energy', 'Cryptocurrency'],
       '{"service_model":"Simulated trading assessments and simulated-live accounts; the firm states payouts are made in real-world USD.","profile_note":"Contracting entity, headquarters, founding date, and jurisdiction eligibility were not confirmed from accessible first-party pages.","source_note":"Reviewed official Funded Trading Plus Help Center on 2026-09-30."}'::jsonb
from bullish_banana.firms where slug = 'funded-trading-plus'
on conflict (firm_id) do update set
  supported_assets = excluded.supported_assets,
  profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
  updated_at = now();

-- Reclassify the existing Classic offer for a fresh review of current terms.
update bullish_banana.programs
set status = 'in_review', market_type = 'forex', currency = 'USD',
    account_sizes = '[]'::jsonb,
    description = 'Two-step evaluation with 7% targets in both phases, 4% daily loss limits and 8% static maximum loss limits. Checkout sizes and fees require confirmation.',
    profit_split_percent = 80,
    payout_frequency = 'Every 10 calendar days, subject to program criteria',
    weekend_holding_allowed = true,
    commercial_details = commercial_details || '{"consistency_rule":"35% in both evaluation phases; 50% on the simulated-live account","symbol_loss_limit_percent":3,"minimum_withdrawal":"1% of initial account size","swap_free":true,"time_limit":"No evaluation time limit; one completed trade is required within each 30-day period","checkout_pricing":"Not stated","platform_mapping":"Not stated"}'::jsonb,
    updated_at = now()
where slug = 'two-step-classic'
  and firm_id = (select id from bullish_banana.firms where slug = 'funded-trading-plus');

update bullish_banana.program_phases phase
set profit_target_percent = 7, daily_drawdown_percent = 4,
    maximum_drawdown_percent = 8, drawdown_type = 'static',
    raw_rules = phase.raw_rules || '{"consistency_rule_percent":35,"time_limit":"No time limit; 30-day account activity requirement","news_trading":"Not stated"}'::jsonb,
    updated_at = now()
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
where phase.program_id = program.id
  and firm.slug = 'funded-trading-plus'
  and program.slug = 'two-step-classic';

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, profit_split_percent, payout_frequency, news_allowed,
  weekend_holding_allowed, commercial_details
)
select firm.id, offer.name, offer.slug, offer.description, offer.program_type,
       'forex', 'in_review', 'USD', '[]'::jsonb, 80,
       offer.payout_frequency, null, offer.weekend_holding_allowed,
       offer.commercial_details::jsonb
from bullish_banana.firms firm
cross join (values
  ('1-Step Express', 'one-step-express', 'One-step evaluation with 10% target, 4% daily loss limit and 6% relative trailing maximum loss. Fees, checkout sizes and platform variants require confirmation.', 'evaluation', 'Every 7 days after the first eligible request; minimum withdrawal $50', true, '{"maximum_drawdown_type":"relative_trailing","time_limit":"No evaluation time limit; one completed trade is required within each 30-day period","news_trading":"Not stated","checkout_pricing":"Not stated","platform_mapping":"Not stated"}'),
  ('Instant Program', 'instant-program', 'Instant simulated-funded account with 6% daily loss limit and 6% relative trailing maximum loss. Fees, checkout sizes and platform variants require confirmation.', 'instant_funding', 'Every 7 days after the first eligible request; minimum withdrawal $50', false, '{"maximum_drawdown_type":"relative_trailing","time_limit":"One completed trade is required within each 30-day period","news_trading":"Not stated","checkout_pricing":"Not stated","platform_mapping":"Not stated","weekend_rule":"Trades must be closed by 16:30 US Eastern on Friday; new trades may be opened when markets reopen"}')
) as offer(name, slug, description, program_type, payout_frequency, weekend_holding_allowed, commercial_details)
where firm.slug = 'funded-trading-plus'
on conflict (firm_id, slug) do update set
  description = excluded.description, program_type = excluded.program_type,
  market_type = excluded.market_type, status = 'in_review', currency = excluded.currency,
  account_sizes = excluded.account_sizes, profit_split_percent = excluded.profit_split_percent,
  payout_frequency = excluded.payout_frequency,
  weekend_holding_allowed = excluded.weekend_holding_allowed,
  commercial_details = bullish_banana.programs.commercial_details || excluded.commercial_details,
  updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, raw_rules
)
select program.id, phase.phase_number, phase.name, phase.target, phase.daily_loss,
       phase.max_loss, phase.drawdown_type, phase.raw_rules::jsonb
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
join (values
  ('one-step-express', 1, '1-Step Express Evaluation', 10.0::numeric, 4.0::numeric, 6.0::numeric, 'relative_trailing', '{"time_limit":"No evaluation time limit; 30-day account activity requirement","minimum_trading_days":"Not stated"}'),
  ('instant-program', 1, 'Instant Simulated-Funded Phase', null::numeric, 6.0::numeric, 6.0::numeric, 'relative_trailing', '{"time_limit":"30-day account activity requirement","minimum_trading_days":"Not stated"}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, raw_rules)
  on phase.program_slug = program.slug
where firm.slug = 'funded-trading-plus'
on conflict (program_id, phase_number) do update set
  name = excluded.name, profit_target_percent = excluded.profit_target_percent,
  daily_drawdown_percent = excluded.daily_drawdown_percent,
  maximum_drawdown_percent = excluded.maximum_drawdown_percent,
  drawdown_type = excluded.drawdown_type, raw_rules = excluded.raw_rules,
  updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firm.id, 'https://help.fundedtradingplus.com/what-is-funded-trading-plus/',
       'Funded Trading Plus service model',
       'Current official Help Center describes simulated trading accounts, assessments, payout requests in real-world USD, and an instant-funded Master option.'
from bullish_banana.firms firm
where firm.slug = 'funded-trading-plus'
  and not exists (select 1 from bullish_banana.sources source where source.firm_id = firm.id and source.source_url = 'https://help.fundedtradingplus.com/what-is-funded-trading-plus/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select program.id, source.url, source.label, source.notes
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
join (values
  ('one-step-express', 'https://help.fundedtradingplus.com/1-step-express-program-information/', '1-Step Express rules', 'Official guide states 10% target, 4% daily loss, 6% relative trailing maximum loss, no evaluation time limit, 80% payout split, and $50 minimum withdrawal.'),
  ('two-step-classic', 'https://help.fundedtradingplus.com/2-step-classic-program-information/', '2-Step Classic rules', 'Official guide states 7% targets per phase, 4% daily loss and 8% static maximum loss per phase; 35% evaluation consistency; 3% symbol loss limit; 80% split; minimum withdrawal of 1% of initial balance.'),
  ('instant-program', 'https://help.fundedtradingplus.com/instant-program-information/', 'Instant Program rules', 'Official guide states 6% daily loss, 6% relative trailing maximum loss, 80% payout split and $50 minimum withdrawal. It specifies a Friday close requirement for open trades.'),
  ('one-step-express', 'https://help.fundedtradingplus.com/ft-leverage/', 'Funded Trading Plus leverage', 'Official Help Center states Forex leverage up to 1:30 for 1-Step Express and Instant, and up to 1:50 for 2-Step Classic.')
) as source(program_slug, url, label, notes) on source.program_slug = program.slug
where firm.slug = 'funded-trading-plus'
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = program.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firm.id, now(), 'Funded Trading Plus Help Center is active and its official current guides document three Forex candidate offers. Fees, full account-size matrices, platform-to-offer mapping, entity and jurisdiction eligibility remain unconfirmed; all offers are held in review.'
from bullish_banana.firms firm where firm.slug = 'funded-trading-plus';
