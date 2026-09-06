set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values
  ('FundedNext', 'fundednext', 'A simulated trading evaluation provider with CFD and futures programs, including the Stellar 2-Step path.', 'https://fundednext.com/', 'published', now()),
  ('Topstep', 'topstep', 'A futures-focused evaluation provider offering the Trading Combine and a path to funded trading.', 'https://www.topstep.com/', 'published', now())
on conflict (slug) do update set
  description = excluded.description,
  website_url = excluded.website_url,
  updated_at = now();

insert into bullish_banana.platforms (name, slug)
values ('TopstepX', 'topstepx')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency,
  account_sizes, profit_split_percent, published_at
)
select firms.id, values_row.name, values_row.slug, values_row.description,
  'evaluation', 'published', 'USD', values_row.account_sizes::jsonb,
  values_row.profit_split_percent, now()
from bullish_banana.firms
join (values
  (
    'FundedNext Stellar 2-Step',
    'stellar-2-step',
    'A two-phase CFD evaluation: reach an 8% profit target in phase one and 5% in phase two.',
    '[]',
    null::numeric
  ),
  (
    'Topstep Trading Combine',
    'trading-combine',
    'A futures evaluation leading to funded trading, with published buying-power tiers up to $150K and a 90% profit share.',
    '[{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":150000,"currency":"USD"}]',
    90.00::numeric
  )
) as values_row(name, slug, description, account_sizes, profit_split_percent)
  on values_row.slug = case firms.slug when 'fundednext' then 'stellar-2-step' else 'trading-combine' end
where firms.slug in ('fundednext', 'topstep')
on conflict (firm_id, slug) do update set
  description = excluded.description,
  account_sizes = excluded.account_sizes,
  profit_split_percent = excluded.profit_split_percent,
  updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, raw_rules
)
select programs.id, phase.phase_number, phase.name, phase.profit_target_percent, phase.raw_rules::jsonb
from bullish_banana.programs
join (values
  ('stellar-2-step', 1, 'Stellar Evaluation Phase 1', 8.000::numeric, '{"source_note":"FundedNext official Stellar 2-Step overview states an 8% first-phase target."}'),
  ('stellar-2-step', 2, 'Stellar Evaluation Phase 2', 5.000::numeric, '{"source_note":"FundedNext official Stellar 2-Step overview states a 5% second-phase target."}'),
  ('trading-combine', 1, 'Trading Combine', null::numeric, '{"source_note":"Topstep official Trading Combine page describes the evaluation and says the profit target is account-tier specific; the exact target is intentionally left unavailable here."}')
) as phase(program_slug, phase_number, name, profit_target_percent, raw_rules)
  on phase.program_slug = programs.slug
where programs.firm_id in (select id from bullish_banana.firms where slug in ('fundednext', 'topstep'))
on conflict (program_id, phase_number) do update set
  name = excluded.name,
  profit_target_percent = excluded.profit_target_percent,
  raw_rules = excluded.raw_rules,
  updated_at = now();

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'topstep'
join bullish_banana.platforms on platforms.slug = 'topstepx'
where programs.slug = 'trading-combine'
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.source_url, source.source_label, source.notes
from bullish_banana.firms
join (values
  ('fundednext', 'https://fundednext.com/', 'FundedNext official overview', 'First-party overview identifies the Stellar program family and simulated evaluation context.'),
  ('topstep', 'https://www.topstep.com/topstep-prop/', 'Topstep Trading Combine overview', 'First-party overview identifies the futures Trading Combine, buying-power tiers, and published profit-share statement.')
) as source(firm_slug, source_url, source_label, notes) on source.firm_slug = firms.slug
where not exists (
  select 1 from bullish_banana.sources existing
  where existing.firm_id = firms.id and existing.source_url = source.source_url
);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.source_url, source.source_label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('fundednext', 'stellar-2-step', 'https://fundednext.com/usa/cfds/stellar-2-step', 'FundedNext Stellar 2-Step', 'First-party page states the two-phase 8% then 5% target structure.'),
  ('topstep', 'trading-combine', 'https://www.topstep.com/topstep-prop/', 'Topstep Trading Combine', 'First-party page states the futures evaluation, buying-power tiers, and 90% profit share; unavailable fields remain null.')
) as source(firm_slug, program_slug, source_url, source_label, notes)
  on source.firm_slug = firms.slug and source.program_slug = programs.slug
where not exists (
  select 1 from bullish_banana.sources existing
  where existing.program_id = programs.id and existing.source_url = source.source_url
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(),
  case programs.slug
    when 'stellar-2-step' then 'Verified against FundedNext first-party Stellar 2-Step overview; exact pricing and unavailable rule fields require a later editorial capture.'
    else 'Verified against Topstep first-party Trading Combine overview; account-tier-specific targets and pricing require a later editorial capture.'
  end
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
where (firms.slug = 'fundednext' and programs.slug = 'stellar-2-step')
   or (firms.slug = 'topstep' and programs.slug = 'trading-combine')
  and not exists (
    select 1 from bullish_banana.data_verifications existing
    where existing.program_id = programs.id
  );

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site',
  case firms.slug when 'fundednext' then 'Visit FundedNext' else 'Visit Topstep' end,
  case firms.slug when 'fundednext' then 'https://fundednext.com/usa/cfds/stellar-2-step' else 'https://www.topstep.com/topstep-prop/' end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where (firms.slug = 'fundednext' and programs.slug = 'stellar-2-step')
   or (firms.slug = 'topstep' and programs.slug = 'trading-combine')
  and not exists (
    select 1 from bullish_banana.affiliate_destinations existing
    where existing.program_id = programs.id and existing.kind = 'official_site'
  );
