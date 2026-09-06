-- First-party catalog expansion: Blue Guardian, FundedElite, and The Funded Trader.
-- Variant names are part of each slug so rules are not conflated across products.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values
  ('Blue Guardian', 'blue-guardian', 'A simulated forex evaluation provider offering Standard and Nano two-step models.', 'https://www.blueguardian.com/', 'published', now()),
  ('FundedElite', 'fundedelite', 'A simulated trading evaluation provider offering selectable challenge models and account parameters.', 'https://fundedelite.com/', 'published', now()),
  ('The Funded Trader', 'the-funded-trader', 'A simulated trading evaluation provider offering multi-phase challenge programs.', 'https://thefundedtraderprogram.com/', 'published', now())
on conflict (slug) do update set description = excluded.description, website_url = excluded.website_url, updated_at = now();

insert into bullish_banana.programs (firm_id, name, slug, description, program_type, status, currency, account_sizes, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, published_at)
select firms.id, values_row.name, values_row.slug, values_row.description, 'evaluation', 'published', 'USD', values_row.account_sizes::jsonb, values_row.profit_split_percent, values_row.payout_frequency, values_row.minimum_trading_days, values_row.news_allowed, values_row.weekend_holding_allowed, now()
from bullish_banana.firms
join (values
  ('blue-guardian', 'Blue Guardian 2-Step Standard', '2-step-standard', 'A two-phase forex evaluation with 8% and 4% targets, 4% daily drawdown, and 8% static maximum drawdown.', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 85.00::numeric, 'Every 14 days', 3, true, true),
  ('fundedelite', 'FundedElite Lite 2-Step', 'lite-2-step', 'A two-phase evaluation with selectable account parameters; this record uses the documented 8% maximum-loss and 8% first-target configuration.', '[{"account_size":5000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"}]', 80.00::numeric, 'Every 14 days', 3, null, null),
  ('the-funded-trader', 'The Funded Trader Rapid', 'rapid', 'A multi-phase simulated evaluation with 8% Phase 1 and 5% Phase 2 targets, 8% maximum drawdown, and 8% daily drawdown.', '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', null::numeric, null, 0, null, null)
) as values_row(firm_slug, name, slug, description, account_sizes, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed)
  on values_row.firm_slug = firms.slug
on conflict (firm_id, slug) do update set description = excluded.description, account_sizes = excluded.account_sizes, profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed, updated_at = now();

insert into bullish_banana.program_phases (program_id, phase_number, name, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules)
select programs.id, phase.phase_number, phase.name, phase.profit_target_percent, phase.daily_drawdown_percent, phase.maximum_drawdown_percent, phase.drawdown_type, phase.minimum_trading_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('blue-guardian', '2-step-standard', 1, 'Blue Guardian 2-Step Standard Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3, '{"source_note":"Blue Guardian first-party comparison states an 8% Phase 1 target, 4% daily drawdown, 8% static maximum drawdown, and three profitable trading days."}'),
  ('blue-guardian', '2-step-standard', 2, 'Blue Guardian 2-Step Standard Phase 2', 4.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3, '{"source_note":"Blue Guardian first-party comparison states a 4% Phase 2 target and the same 4% daily and 8% static maximum drawdown model."}'),
  ('fundedelite', 'lite-2-step', 1, 'FundedElite Lite Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3, '{"source_note":"FundedElite first-party FAQ documents selectable phase-one targets including 8%, fixed 4% daily loss, selectable maximum loss including 8%, and three minimum profitable days."}'),
  ('fundedelite', 'lite-2-step', 2, 'FundedElite Lite Phase 2', 5.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 3, '{"source_note":"FundedElite first-party FAQ states the Lite 2-Step Phase 2 target reduces to 5% and requires three minimum profitable days."}'),
  ('the-funded-trader', 'rapid', 1, 'The Funded Trader Rapid Phase 1', 8.000::numeric, 8.000::numeric, 8.000::numeric, 'static', 0, '{"source_note":"The Funded Trader first-party Funding Process page states the Rapid Challenge has an 8% Phase 1 target, 8% maximum drawdown, 8% daily drawdown, and no minimum trading days."}'),
  ('the-funded-trader', 'rapid', 2, 'The Funded Trader Rapid Phase 2', 5.000::numeric, 8.000::numeric, 8.000::numeric, 'static', 0, '{"source_note":"The Funded Trader first-party Funding Process page states the Rapid Challenge has a 5% Phase 2 target and no minimum trading days."}')
) as phase(firm_slug, program_slug, phase_number, name, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules)
  on phase.firm_slug = firms.slug and phase.program_slug = programs.slug
on conflict (program_id, phase_number) do update set name = excluded.name, profit_target_percent = excluded.profit_target_percent, daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent, drawdown_type = excluded.drawdown_type, minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.source_url, source.source_label, source.notes
from bullish_banana.firms
join (values
  ('blue-guardian', 'https://origin.blueguardian.com/blogs/blue-guardian-2-step-standard-vs-2-step-nano', 'Blue Guardian 2-Step comparison', 'First-party comparison of the current Standard and Nano models.'),
  ('fundedelite', 'https://faq.fundedelite.com/en/articles/12683646-lite-2-step-challenge', 'FundedElite Lite 2-Step FAQ', 'First-party FAQ documents the Lite 2-Step selectable parameters and phase structure.'),
  ('the-funded-trader', 'https://thefundedtraderprogram.com/funding-process/', 'The Funded Trader Funding Process', 'First-party Funding Process page documents the Rapid Challenge structure and targets.')
) as source(firm_slug, source_url, source_label, notes) on source.firm_slug = firms.slug
where not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.source_url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.source_url, source.source_label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('blue-guardian', '2-step-standard', 'https://origin.blueguardian.com/blogs/blue-guardian-2-step-standard-vs-2-step-nano', 'Blue Guardian 2-Step Standard rules', 'First-party comparison states the selected Standard targets, drawdowns, profitable-day requirement, payout cadence, news, and weekend permissions.'),
  ('fundedelite', 'lite-2-step', 'https://faq.fundedelite.com/en/articles/12683646-lite-2-step-challenge', 'FundedElite Lite 2-Step rules', 'First-party FAQ states the selected 8% target and 8% maximum-loss configuration, fixed daily loss, phase-two target, minimum days, account sizes, payout options, and platform options.'),
  ('the-funded-trader', 'rapid', 'https://thefundedtraderprogram.com/funding-process/', 'The Funded Trader Rapid rules', 'First-party page states the Rapid Challenge targets, daily and maximum drawdown, and zero minimum trading days; other fields remain unavailable.')
) as source(firm_slug, program_slug, source_url, source_label, notes) on source.firm_slug = firms.slug and source.program_slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.source_url);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified against the provider first-party program page; variant-specific pricing, platform availability, and other unavailable fields remain explicitly unrepresented.'
from bullish_banana.programs join bullish_banana.firms on firms.id = programs.firm_id
where (firms.slug, programs.slug) in (('blue-guardian', '2-step-standard'), ('fundedelite', 'lite-2-step'), ('the-funded-trader', 'rapid'))
  and not exists (select 1 from bullish_banana.data_verifications existing where existing.program_id = programs.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', source.label, source.url, true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
join (values
  ('blue-guardian', '2-step-standard', 'Visit Blue Guardian', 'https://origin.blueguardian.com/forex'),
  ('fundedelite', 'lite-2-step', 'Visit FundedElite', 'https://fundedelite.com/challenges/lite-account'),
  ('the-funded-trader', 'rapid', 'Visit The Funded Trader', 'https://thefundedtraderprogram.com/funding-process/')
) as source(firm_slug, program_slug, label, url) on source.firm_slug = firms.slug and source.program_slug = programs.slug
where not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
