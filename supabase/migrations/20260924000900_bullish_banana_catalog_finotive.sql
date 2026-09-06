-- First-party catalog expansion: Finotive Funding 2-Step Challenge.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'Finotive Funding',
  'finotive-funding',
  'A proprietary trading evaluation provider offering one-step and two-step challenge models with static drawdown rules.',
  'https://finotivefunding.com/',
  'published',
  now()
)
on conflict (slug) do update set
  description = excluded.description,
  website_url = excluded.website_url,
  updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, published_at
)
select firms.id,
  'Finotive 2-Step Challenge',
  '2-step-challenge',
  'A two-stage evaluation with 7.5% and 5% targets, 4.5% daily drawdown, 9% static maximum drawdown, and an 80% profit split.',
  'evaluation',
  'published',
  'USD',
  '[{"account_size":2500,"currency":"USD"},{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]'::jsonb,
  80.00,
  'Weekly',
  2,
  null,
  null,
  now()
from bullish_banana.firms
where firms.slug = 'finotive-funding'
on conflict (firm_id, slug) do update set
  description = excluded.description,
  account_sizes = excluded.account_sizes,
  profit_split_percent = excluded.profit_split_percent,
  payout_frequency = excluded.payout_frequency,
  minimum_trading_days = excluded.minimum_trading_days,
  news_allowed = excluded.news_allowed,
  weekend_holding_allowed = excluded.weekend_holding_allowed,
  status = excluded.status,
  updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent,
  daily_drawdown_percent, maximum_drawdown_percent, drawdown_type,
  minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, phase.profit_target_percent,
  phase.daily_drawdown_percent, phase.maximum_drawdown_percent,
  phase.drawdown_type, phase.minimum_trading_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('finotive-funding', '2-step-challenge', 1, 'Finotive 2-Step Phase 1', 7.500::numeric, 4.500::numeric, 9.000::numeric, 'static', 2, '{"source_note":"Finotive first-party rules page documents a 7.5% Phase 1 target, 4.5% daily drawdown, 9% maximum overall drawdown, static drawdown, and two minimum profitable days per stage."}'),
  ('finotive-funding', '2-step-challenge', 2, 'Finotive 2-Step Phase 2', 5.000::numeric, 4.500::numeric, 9.000::numeric, 'static', 2, '{"source_note":"Finotive first-party challenge and rules pages document a 5% Phase 2 target and the same static drawdown model; two minimum profitable days apply per stage."}')
) as phase(firm_slug, program_slug, phase_number, name, profit_target_percent, daily_drawdown_percent, maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules)
  on phase.firm_slug = firms.slug and phase.program_slug = programs.slug
on conflict (program_id, phase_number) do update set
  name = excluded.name,
  profit_target_percent = excluded.profit_target_percent,
  daily_drawdown_percent = excluded.daily_drawdown_percent,
  maximum_drawdown_percent = excluded.maximum_drawdown_percent,
  drawdown_type = excluded.drawdown_type,
  minimum_trading_days = excluded.minimum_trading_days,
  raw_rules = excluded.raw_rules,
  updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.source_url, source.source_label, source.notes
from bullish_banana.firms
join (values
  ('finotive-funding', 'https://finotivefunding.com/challenge', 'Finotive Challenge accounts', 'First-party challenge page documents the 2-Step targets, account-size options, 4.5% daily drawdown, 9% static maximum drawdown, 80% split, and weekly payouts.'),
  ('finotive-funding', 'https://finotivefunding.com/rules', 'Finotive Trading Rules', 'First-party rules page documents the static drawdown mechanics and two minimum profitable days per stage for the Two-Step model.')
) as source(firm_slug, source_url, source_label, notes)
  on source.firm_slug = firms.slug
where not exists (
  select 1 from bullish_banana.sources existing
  where existing.firm_id = firms.id and existing.source_url = source.source_url
);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.source_url, source.source_label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('finotive-funding', '2-step-challenge', 'https://finotivefunding.com/challenge', 'Finotive 2-Step Challenge facts', 'First-party challenge page documents the 7.5% and 5% targets, account sizes, 4.5% daily drawdown, 9% static maximum drawdown, 80% split, and weekly payouts.'),
  ('finotive-funding', '2-step-challenge', 'https://finotivefunding.com/rules', 'Finotive 2-Step rules', 'First-party rules page documents two minimum profitable days per stage; unspecified news and weekend permissions remain unavailable.')
) as source(firm_slug, program_slug, source_url, source_label, notes)
  on source.firm_slug = firms.slug and source.program_slug = programs.slug
where not exists (
  select 1 from bullish_banana.sources existing
  where existing.program_id = programs.id and existing.source_url = source.source_url
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified against Finotive first-party challenge and rules pages; news, weekend, platform, and variant-specific pricing details remain explicitly unrepresented.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'finotive-funding'
  and programs.slug = '2-step-challenge'
  and not exists (select 1 from bullish_banana.data_verifications existing where existing.program_id = programs.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit Finotive Funding', 'https://finotivefunding.com/challenge', true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'finotive-funding'
  and programs.slug = '2-step-challenge'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations existing
    where existing.program_id = programs.id and existing.kind = 'official_site'
  );
