set search_path = bullish_banana, extensions, public;

-- Firms can operate across several markets; each individual program still has one market.
create table bullish_banana.firm_markets (
  firm_id uuid not null references bullish_banana.firms(id) on delete cascade,
  market_type text not null check (market_type in ('forex', 'futures', 'crypto')),
  created_at timestamptz not null default now(),
  primary key (firm_id, market_type)
);

create index firm_markets_market_firm_idx
  on bullish_banana.firm_markets (market_type, firm_id);

-- The catalog foundation migration recreates the application schema, so these
-- earlier catalog firms must be restored before their current Forex refreshes
-- run later in this migration chain.
insert into bullish_banana.firms
  (name, slug, description, website_url, status, market_type)
values
  ('FundedNext', 'fundednext', 'A simulated trading evaluation provider offering current Stellar Forex CFD challenges.', 'https://fundednext.com/usa/cfds', 'in_review', 'forex'),
  ('E8 Markets', 'e8-markets', 'A simulated trading provider offering Forex challenges through its current E8 One, E8 Pro and E8 Signature programs.', 'https://e8markets.com/', 'in_review', 'forex'),
  ('Maven Trading', 'maven-trading', 'A simulated Forex provider offering evaluation, instant funding and direct-funded account programs.', 'https://maventrading.com/', 'in_review', 'forex')
on conflict (slug) do nothing;

-- This legacy record is outside the PropFirmMatch Forex roster used for this MVP.
update bullish_banana.firms
set status = 'archived', published_at = null,
    archived_at = coalesce(archived_at, now()), updated_at = now()
where slug = 'the-funded-trader';

update bullish_banana.programs p
set status = 'archived', published_at = null,
    archived_at = coalesce(p.archived_at, now()), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'the-funded-trader';

-- Reclassify firms whose catalog programs are Futures-only. Keep their firm rows and history.
update bullish_banana.firms
set market_type = 'futures', updated_at = now()
where slug in ('apex-trader-funding', 'earn2trade', 'my-funded-futures')
  and market_type = 'forex';

update bullish_banana.programs p
set market_type = 'futures', updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug in ('apex-trader-funding', 'earn2trade', 'my-funded-futures')
  and p.market_type = 'forex';

delete from bullish_banana.firm_markets fm
using bullish_banana.firms f
where fm.firm_id = f.id
  and f.slug in ('apex-trader-funding', 'earn2trade', 'my-funded-futures')
  and fm.market_type = 'forex';

-- Keep the legacy single-market column as the primary market during the compatibility rollout.
insert into bullish_banana.firm_markets (firm_id, market_type)
select id, market_type from bullish_banana.firms
where status <> 'archived'
on conflict (firm_id, market_type) do nothing;

-- E8's official site lists Classic Markets (Forex, Commodities, Indices, Energies) alongside Futures and Perpetuals; checked 2026-09-28: https://e8markets.com/.
insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'e8-markets'
on conflict (firm_id, market_type) do nothing;

create table bullish_banana.firm_profiles (
  firm_id uuid primary key references bullish_banana.firms(id) on delete cascade,
  country_code text check (country_code is null or country_code ~ '^[A-Z]{2}$'),
  established_on date,
  legal_entity_name text,
  supported_assets text[] not null default '{}'::text[],
  profile_details jsonb not null default '{}'::jsonb check (jsonb_typeof(profile_details) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table bullish_banana.programs
  add column commercial_details jsonb not null default '{}'::jsonb
  check (jsonb_typeof(commercial_details) = 'object');

alter table bullish_banana.firm_markets enable row level security;
alter table bullish_banana.firm_profiles enable row level security;

grant all on bullish_banana.firm_markets, bullish_banana.firm_profiles to service_role;
grant select on bullish_banana.firm_markets, bullish_banana.firm_profiles to anon, authenticated;

create policy "published firm markets are publicly readable"
  on bullish_banana.firm_markets for select to anon, authenticated
  using (exists (
    select 1 from bullish_banana.firms f
    where f.id = firm_id and f.status = 'published'
  ));

create policy "published firm profiles are publicly readable"
  on bullish_banana.firm_profiles for select to anon, authenticated
  using (exists (
    select 1 from bullish_banana.firms f
    where f.id = firm_id and f.status = 'published'
  ));
