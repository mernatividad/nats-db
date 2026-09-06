-- First-party catalog expansion: Alpha Capital Group Alpha Pro 8%.
-- The plan has multiple variants; this record names the 8%/5% rule set explicitly.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values ('Alpha Capital Group', 'alpha-capital-group', 'A simulated trading evaluation provider offering Alpha Pro two-step rule-set variants.', 'https://alphacapitalgroup.uk/', 'published', now())
on conflict (slug) do update set description = excluded.description, website_url = excluded.website_url, updated_at = now();

insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, published_at)
select firms.id, 'Alpha Pro 8%', 'alpha-pro-8', 'A two-phase Alpha Pro evaluation with 8% Phase 1 and 5% Phase 2 targets, 8% static maximum drawdown, and 4% balance-based daily drawdown.', 'evaluation', 'published', 'USD', '[]'::jsonb, null, 'Bi-weekly or on-demand', 3, true, true, now()
from bullish_banana.firms where firms.slug = 'alpha-capital-group'
on conflict (firm_id, slug) do update set description = excluded.description, payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed, updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, phase.profit_target_percent, 4.000, 8.000, 'static', 3, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group'
join (values
  (1, 'Alpha Pro 8% Phase 1', 8.000::numeric, '{"source_note":"Alpha Capital Group official terms state the Alpha Pro 8% plan has an 8% Phase 1 target, 4% balance-based daily drawdown, 8% static maximum drawdown, and three minimum trading days."}'),
  (2, 'Alpha Pro 8% Phase 2', 5.000::numeric, '{"source_note":"Alpha Capital Group official terms state the Alpha Pro 8% plan has a 5% Phase 2 target and three minimum trading days."}')
) as phase(phase_number, name, profit_target_percent, raw_rules) on true
on conflict (program_id, phase_number) do update set name = excluded.name, profit_target_percent = excluded.profit_target_percent, daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent, drawdown_type = excluded.drawdown_type, minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group' join bullish_banana.platforms on platforms.slug = 'metatrader-5' where programs.slug = 'alpha-pro-8' on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://alphacapitalgroup.uk/terms-and-conditions', 'Alpha Capital Group terms', 'First-party terms identify Alpha Pro and its evaluation rule variants.' from bullish_banana.firms where firms.slug = 'alpha-capital-group' and not exists (select 1 from bullish_banana.sources where sources.firm_id = firms.id and sources.source_url = 'https://alphacapitalgroup.uk/terms-and-conditions');
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://alphacapitalgroup.uk/terms-and-conditions', 'Alpha Pro 8% rules', 'First-party terms state 8% then 5% targets, 8% static maximum drawdown, 4% balance-based daily drawdown, three minimum trading days, news and weekend holding, and up to 1:100 leverage.' from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group' where programs.slug = 'alpha-pro-8' and not exists (select 1 from bullish_banana.sources where sources.program_id = programs.id and sources.source_url = 'https://alphacapitalgroup.uk/terms-and-conditions');
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified against Alpha Capital Group first-party terms; account sizes and exact current checkout pricing are intentionally unavailable until captured from the applicable official offer.' from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'alpha-capital-group' where programs.slug = 'alpha-pro-8' and not exists (select 1 from bullish_banana.data_verifications where data_verifications.program_id = programs.id);
insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit Alpha Capital Group', 'https://alphacapitalgroup.uk/product/2-step', true, 'active' from bullish_banana.firms join bullish_banana.programs on programs.firm_id = firms.id and programs.slug = 'alpha-pro-8' where firms.slug = 'alpha-capital-group' and not exists (select 1 from bullish_banana.affiliate_destinations where affiliate_destinations.program_id = programs.id and affiliate_destinations.kind = 'official_site');
