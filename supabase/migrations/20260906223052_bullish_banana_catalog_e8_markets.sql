-- First-party catalog expansion: E8 Markets E8 One Perpetual.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'E8 Markets',
  'e8-markets',
  'A simulated trading evaluation provider offering a single-phase perpetual-futures path through the HyperLiquid feed.',
  'https://e8markets.com/',
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
  'E8 One Perpetual',
  'e8-one-perpetual',
  'A one-step perpetual-futures challenge with a 6% target, 3% daily drawdown, and 4% dynamic drawdown.',
  'evaluation',
  'published',
  'USD',
  '[]'::jsonb,
  null,
  'On-demand',
  null,
  null,
  null,
  now()
from bullish_banana.firms
where firms.slug = 'e8-markets'
on conflict (firm_id, slug) do update set
  description = excluded.description,
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
select programs.id, 1, 'E8 One Perpetual Challenge', 6.000::numeric,
  3.000::numeric, 4.000::numeric, 'dynamic', null,
  '{"source_note":"E8 Markets first-party help-center page states a 6% profit target, 3% daily drawdown, and 4% dynamic drawdown for the preset E8 One Perpetual challenge."}'::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'e8-markets' and programs.slug = 'e8-one-perpetual'
on conflict (program_id, phase_number) do update set
  name = excluded.name,
  profit_target_percent = excluded.profit_target_percent,
  daily_drawdown_percent = excluded.daily_drawdown_percent,
  maximum_drawdown_percent = excluded.maximum_drawdown_percent,
  drawdown_type = excluded.drawdown_type,
  minimum_trading_days = excluded.minimum_trading_days,
  raw_rules = excluded.raw_rules,
  updated_at = now();

insert into bullish_banana.platforms (name, slug)
values ('HyperLiquid', 'hyperliquid')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join bullish_banana.platforms on platforms.slug = 'hyperliquid'
where firms.slug = 'e8-markets' and programs.slug = 'e8-one-perpetual'
on conflict (program_id, platform_id) do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://help.e8markets.com/en/articles/16773821-e8-one-perpetual', 'E8 One Perpetual rules', 'First-party help-center page identifies the E8 One Perpetual product, its single-step structure, preset challenge rules, HyperLiquid feed, and stage-specific trading policies.'
from bullish_banana.firms
where firms.slug = 'e8-markets'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://help.e8markets.com/en/articles/16773821-e8-one-perpetual');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, 'https://help.e8markets.com/en/articles/16773821-e8-one-perpetual', 'E8 One Perpetual challenge rules', 'First-party page documents the 6% target, 3% daily drawdown, 4% dynamic drawdown, unlimited trading days, and the distinction between challenge and performance rules.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'e8-markets' and programs.slug = 'e8-one-perpetual'
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = 'https://help.e8markets.com/en/articles/16773821-e8-one-perpetual');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Verified against the E8 Markets first-party E8 One Perpetual help-center page; account-size, pricing, split, minimum-day, and stage-specific permission fields remain unavailable or intentionally unrepresented.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where firms.slug = 'e8-markets' and programs.slug = 'e8-one-perpetual'
  and not exists (select 1 from bullish_banana.data_verifications existing where existing.program_id = programs.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'Visit E8 Markets E8 One', 'https://e8markets.com/e8-one', true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'e8-markets' and programs.slug = 'e8-one-perpetual'
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
