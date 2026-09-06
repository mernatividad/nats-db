-- First-party catalog expansion: Funded Trading Plus 2-Step Classic.
-- Promotional prices and unavailable fields are intentionally excluded.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values ('Funded Trading Plus', 'funded-trading-plus', 'A simulated trading evaluation provider offering a two-step classic challenge with static drawdown.', 'https://www.fundedtradingplus.com/', 'published', now())
on conflict (slug) do update set description = excluded.description, website_url = excluded.website_url, updated_at = now();

insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, profit_split_percent, payout_frequency, news_allowed, weekend_holding_allowed, published_at)
select firms.id, '2-Step Classic', 'two-step-classic', 'A two-phase simulated evaluation with 7% targets in each phase, static 8% maximum loss, and 4% maximum daily loss.', 'evaluation', 'published', 'USD', '[{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]'::jsonb, 80.00, 'Every 10 calendar days', true, true, now()
from bullish_banana.firms where firms.slug = 'funded-trading-plus'
on conflict (firm_id, slug) do update set description = excluded.description, account_sizes = excluded.account_sizes, profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency, news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed, updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, raw_rules)
select programs.id, phase.phase_number, phase.name, 7.000, 4.000, 8.000, 'static', phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'funded-trading-plus'
join (values
  (1, '2-Step Classic Step 1', '{"source_note":"Funded Trading Plus official 2-Step Classic page states a 7% target, 4% maximum daily loss, and 8% static maximum loss for Step 1."}'),
  (2, '2-Step Classic Step 2', '{"source_note":"Funded Trading Plus official 2-Step Classic page states a 7% target, 4% maximum daily loss, and 8% static maximum loss for Step 2."}')
) as phase(phase_number, name, raw_rules) on true
on conflict (program_id, phase_number) do update set name = excluded.name, profit_target_percent = excluded.profit_target_percent, daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent, drawdown_type = excluded.drawdown_type, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values ('Match-Trader', 'match-trader') on conflict (slug) do update set name = excluded.name;
insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'funded-trading-plus' join bullish_banana.platforms on platforms.slug in ('metatrader-5', 'match-trader') where programs.slug = 'two-step-classic' on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://www.fundedtradingplus.com/prop-trading-challenges/two-step', 'Funded Trading Plus 2-Step Classic overview', 'First-party page identifies the provider and two-step challenge.' from bullish_banana.firms where firms.slug = 'funded-trading-plus' and not exists (select 1 from bullish_banana.sources where sources.firm_id = firms.id and sources.source_url = 'https://www.fundedtradingplus.com/prop-trading-challenges/two-step');
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://www.fundedtradingplus.com/prop-trading-challenges/two-step', 'Funded Trading Plus 2-Step Classic rules', 'First-party page states 7% targets, 4% daily loss, 8% static maximum loss, 35% evaluation consistency, 80% reward split, 10-day reward frequency, news trading, and available account sizes.' from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'funded-trading-plus' where programs.slug = 'two-step-classic' and not exists (select 1 from bullish_banana.sources where sources.program_id = programs.id and sources.source_url = 'https://www.fundedtradingplus.com/prop-trading-challenges/two-step');
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified against the Funded Trading Plus first-party 2-Step Classic page; exact current checkout pricing and account-location platform availability are intentionally not represented as fixed catalog facts.' from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'funded-trading-plus' where programs.slug = 'two-step-classic' and not exists (select 1 from bullish_banana.data_verifications where data_verifications.program_id = programs.id);
insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit Funded Trading Plus', 'https://www.fundedtradingplus.com/prop-trading-challenges/two-step', true, 'active' from bullish_banana.firms join bullish_banana.programs on programs.firm_id = firms.id and programs.slug = 'two-step-classic' where firms.slug = 'funded-trading-plus' and not exists (select 1 from bullish_banana.affiliate_destinations where affiliate_destinations.program_id = programs.id and affiliate_destinations.kind = 'official_site');
