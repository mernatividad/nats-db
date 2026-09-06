-- Editorial seed: one real provider with two currently documented evaluation paths.
-- Prices are captured examples from the linked official pages and must be re-verified
-- before changing a record back to published after an editorial review.
set search_path = bullish_banana, extensions, public;

with firm_row as (
  insert into bullish_banana.firms (
    name, slug, description, website_url, status, ranking_score,
    ranking_methodology_version, published_at
  ) values (
    'FTMO',
    'ftmo',
    'A prop trading evaluation provider offering one-step and two-step paths to an FTMO Account.',
    'https://ftmo.com/',
    'published',
    90.000,
    'editorial-v1',
    now()
  )
  on conflict (slug) do update set
    description = excluded.description,
    website_url = excluded.website_url,
    updated_at = now()
  returning id
),
platform_row as (
  insert into bullish_banana.platforms (name, slug)
  values ('MetaTrader 5', 'metatrader-5')
  on conflict (slug) do update set name = excluded.name
  returning id
),
program_rows as (
  insert into bullish_banana.programs (
    firm_id, name, slug, description, program_type, status, currency,
    account_sizes, profit_split_percent, payout_frequency,
    minimum_trading_days, news_allowed, weekend_holding_allowed, published_at
  )
  select
    firm_row.id,
    values_row.name,
    values_row.slug,
    values_row.description,
    'evaluation',
    'published',
    'EUR',
    values_row.account_sizes::jsonb,
    90.00,
    'On request after meeting the applicable objectives',
    values_row.minimum_trading_days,
    null,
    null,
    now()
  from firm_row
  cross join (values
    (
      'FTMO Challenge: 2-Step',
      'ftmo-2-step',
      'Two evaluation phases: FTMO Challenge followed by Verification.',
      '[{"account_size":100000,"fee":540,"currency":"EUR"}]',
      4
    ),
    (
      'FTMO Challenge: 1-Step',
      'ftmo-1-step',
      'A single evaluation phase with no Verification phase.',
      '[{"account_size":100000,"fee":499,"currency":"EUR"}]',
      null
    )
  ) as values_row(name, slug, description, account_sizes, minimum_trading_days)
  on conflict (firm_id, slug) do update set
    description = excluded.description,
    account_sizes = excluded.account_sizes,
    profit_split_percent = excluded.profit_split_percent,
    minimum_trading_days = excluded.minimum_trading_days,
    updated_at = now()
  returning id, slug
)
select 1;

insert into bullish_banana.program_phases (
  program_id, phase_number, name, fee, profit_target_percent,
  daily_drawdown_percent, maximum_drawdown_percent, drawdown_type,
  time_limit_days, minimum_trading_days, raw_rules
)
select
  program_row.id,
  phase.phase_number,
  phase.name,
  phase.fee,
  phase.profit_target_percent,
  phase.daily_drawdown_percent,
  10.000,
  'static',
  null,
  4,
  phase.raw_rules::jsonb
from bullish_banana.programs as program_row
join (values
  ('ftmo-2-step', 1, 'FTMO Challenge', 540.00, 10.000, 5.000, '{"source_note":"Official FTMO 2-Step page documents 10% Phase 1 target, 5% Phase 2 target, 5% max daily loss, 10% max loss, 4 minimum trading days, and unlimited trading period."}'),
  ('ftmo-2-step', 2, 'Verification', null, 5.000, 5.000, '{"source_note":"Official FTMO Trading Objectives page documents the Verification target and the same 5% daily / 10% maximum loss limits."}'),
  ('ftmo-1-step', 1, 'FTMO Challenge', 499.00, 10.000, 3.000, '{"source_note":"Official FTMO 1-Step page documents 10% target, 3% max daily loss, 10% max loss, 50% best-day rule, and unlimited trading period."}')
) as phase(program_slug, phase_number, name, fee, profit_target_percent, daily_drawdown_percent, raw_rules)
  on phase.program_slug = program_row.slug
where program_row.firm_id = (select id from bullish_banana.firms where slug = 'ftmo')
on conflict (program_id, phase_number) do update set
  name = excluded.name,
  fee = excluded.fee,
  profit_target_percent = excluded.profit_target_percent,
  daily_drawdown_percent = excluded.daily_drawdown_percent,
  maximum_drawdown_percent = excluded.maximum_drawdown_percent,
  drawdown_type = excluded.drawdown_type,
  minimum_trading_days = excluded.minimum_trading_days,
  raw_rules = excluded.raw_rules,
  updated_at = now();

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
cross join bullish_banana.platforms
where programs.firm_id = (select id from bullish_banana.firms where slug = 'ftmo')
  and platforms.slug = 'metatrader-5'
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select id, 'https://ftmo.com/en/challenge/', 'FTMO Challenge overview', 'Official FTMO overview of evaluation objectives and simulated trading model.'
from bullish_banana.firms where slug = 'ftmo'
and not exists (select 1 from bullish_banana.sources s where s.firm_id = firms.id and s.source_url = 'https://ftmo.com/en/challenge/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.source_url, source.source_label, source.notes
from bullish_banana.programs
join (values
  ('ftmo-2-step', 'https://ftmo.com/en/2-step-challenge/', 'FTMO 2-Step Challenge', 'Official page documents the two phases, targets, limits, refund, reward ratio, and minimum trading days.'),
  ('ftmo-1-step', 'https://ftmo.com/en/1-step-challenge/', 'FTMO 1-Step Challenge', 'Official page documents the single phase, targets, limits, best-day rule, and account path.')
) as source(program_slug, source_url, source_label, notes) on source.program_slug = programs.slug
where programs.firm_id = (select id from bullish_banana.firms where slug = 'ftmo')
and not exists (select 1 from bullish_banana.sources s where s.program_id = programs.id and s.source_url = source.source_url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Seeded from official FTMO pages; editorial review is required before relying on price or platform details.'
from bullish_banana.firms where slug = 'ftmo'
and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = firms.id);

insert into bullish_banana.affiliate_destinations (
  firm_id, program_id, kind, label, destination_url, is_primary, status
)
select firms.id, programs.id, 'official_site', 'Visit FTMO',
  case programs.slug
    when 'ftmo-2-step' then 'https://ftmo.com/en/2-step-challenge/'
    else 'https://ftmo.com/en/1-step-challenge/'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'ftmo'
and not exists (
  select 1 from bullish_banana.affiliate_destinations d
  where d.program_id = programs.id and d.kind = 'official_site'
);
