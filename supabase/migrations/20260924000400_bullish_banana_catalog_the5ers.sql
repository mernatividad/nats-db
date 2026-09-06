-- First-party catalog expansion: The5ers High Stakes.
-- Keep only values stated on the official program page; unavailable fields remain null.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values ('The5ers', 'the5ers', 'A trading evaluation provider offering the two-step High Stakes program with a path to scaling and performance payouts.', 'https://the5ers.com/', 'published', now())
on conflict (slug) do update set description = excluded.description, website_url = excluded.website_url, updated_at = now();

insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, published_at)
select firms.id, 'The5ers High Stakes', 'high-stakes', 'A two-step evaluation with 8% and 5% profit targets, 5% maximum daily loss, and 10% maximum loss.', 'evaluation', 'published', 'USD', '[]'::jsonb, null, 'Bi-weekly', 3, true, true, now()
from bullish_banana.firms where firms.slug = 'the5ers'
on conflict (firm_id, slug) do update set description = excluded.description, payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed, updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, phase.profit_target_percent, 5.000, 10.000, 3, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers'
join (values
  (1, 'High Stakes Step 1', 8.000::numeric, '{"source_note":"The5ers official High Stakes page states an 8% Step 1 target, 5% maximum daily loss, 10% maximum loss, and three minimum profitable days."}'),
  (2, 'High Stakes Step 2', 5.000::numeric, '{"source_note":"The5ers official High Stakes page states a 5% Step 2 target, 5% maximum daily loss, 10% maximum loss, and three minimum profitable days."}')
) as phase(phase_number, name, profit_target_percent, raw_rules) on true
on conflict (program_id, phase_number) do update set name = excluded.name, profit_target_percent = excluded.profit_target_percent, daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent, minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values ('MetaTrader 5 Hedge', 'metatrader-5-hedge') on conflict (slug) do update set name = excluded.name;
insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers' join bullish_banana.platforms on platforms.slug = 'metatrader-5-hedge' where programs.slug = 'high-stakes' on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://the5ers.com/high-stakes', 'The5ers High Stakes overview', 'First-party page identifies the provider and High Stakes program.' from bullish_banana.firms where firms.slug = 'the5ers' and not exists (select 1 from bullish_banana.sources where sources.firm_id = firms.id and sources.source_url = 'https://the5ers.com/high-stakes');
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://the5ers.com/high-stakes', 'The5ers High Stakes rules', 'First-party page states the two-step structure, 8% then 5% targets, 5% daily loss, 10% maximum loss, three minimum profitable days, MT5 Hedge, and overnight/weekend holding.' from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers' where programs.slug = 'high-stakes' and not exists (select 1 from bullish_banana.sources where sources.program_id = programs.id and sources.source_url = 'https://the5ers.com/high-stakes');
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified against The5ers first-party High Stakes program page; pricing, account sizes, and profit split are intentionally unavailable until captured from the applicable official offer.' from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'the5ers' where programs.slug = 'high-stakes' and not exists (select 1 from bullish_banana.data_verifications where data_verifications.program_id = programs.id);
insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit The5ers High Stakes', 'https://the5ers.com/high-stakes', true, 'active' from bullish_banana.firms join bullish_banana.programs on programs.firm_id = firms.id and programs.slug = 'high-stakes' where firms.slug = 'the5ers' and not exists (select 1 from bullish_banana.affiliate_destinations where affiliate_destinations.program_id = programs.id and affiliate_destinations.kind = 'official_site');
