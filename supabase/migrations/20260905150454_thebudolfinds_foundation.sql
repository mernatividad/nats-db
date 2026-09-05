-- TheBudolFinds application foundation. Keep application objects out of public.
create schema if not exists thebudolfinds;

create extension if not exists pgcrypto with schema extensions;

set search_path = thebudolfinds, extensions, public;

create table thebudolfinds.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
  notification_email boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table thebudolfinds.brands (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table thebudolfinds.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table thebudolfinds.merchants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  domain text not null,
  support_status text not null default 'manual' check (support_status in ('supported', 'manual', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table thebudolfinds.sellers (
  id uuid primary key default gen_random_uuid(),
  merchant_id uuid not null references thebudolfinds.merchants(id) on delete restrict,
  external_id text,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (merchant_id, external_id)
);

create table thebudolfinds.products (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid references thebudolfinds.brands(id) on delete set null,
  category_id uuid references thebudolfinds.categories(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  source_type text not null default 'curated' check (source_type in ('curated', 'provider', 'user_report')),
  freshness_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table thebudolfinds.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references thebudolfinds.products(id) on delete cascade,
  external_id text,
  name text not null,
  attributes jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, external_id)
);

create table thebudolfinds.merchant_listings (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references thebudolfinds.products(id) on delete cascade,
  variant_id uuid references thebudolfinds.product_variants(id) on delete set null,
  merchant_id uuid not null references thebudolfinds.merchants(id) on delete restrict,
  seller_id uuid references thebudolfinds.sellers(id) on delete set null,
  external_id text not null,
  canonical_url text not null,
  title text not null,
  currency text not null default 'PHP',
  current_price numeric(12,2),
  availability text not null default 'unknown' check (availability in ('in_stock', 'out_of_stock', 'unknown')),
  source_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (merchant_id, external_id)
);

create table thebudolfinds.price_observations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references thebudolfinds.merchant_listings(id) on delete cascade,
  price numeric(12,2),
  currency text not null default 'PHP',
  availability text not null default 'unknown' check (availability in ('in_stock', 'out_of_stock', 'unknown')),
  confidence text not null default 'unknown' check (confidence in ('verified', 'reported', 'inferred', 'unknown')),
  observed_at timestamptz not null,
  source_updated_at timestamptz,
  created_at timestamptz not null default now(),
  unique (listing_id, observed_at)
);

create table thebudolfinds.score_snapshots (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references thebudolfinds.products(id) on delete cascade,
  algorithm_version text not null,
  score numeric(5,2),
  confidence text not null check (confidence in ('high', 'medium', 'low', 'not_enough_data')),
  verdict text not null,
  evidence jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table thebudolfinds.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users(id) on delete set null,
  product_id uuid references thebudolfinds.products(id) on delete set null,
  listing_id uuid references thebudolfinds.merchant_listings(id) on delete set null,
  report_type text not null check (report_type in ('product', 'price', 'seller', 'mapping', 'other')),
  details text not null,
  status text not null default 'open' check (status in ('open', 'triaged', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table thebudolfinds.affiliate_clicks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  product_id uuid references thebudolfinds.products(id) on delete set null,
  listing_id uuid references thebudolfinds.merchant_listings(id) on delete set null,
  network text not null,
  campaign text,
  placement text,
  page_path text,
  created_at timestamptz not null default now()
);

create table thebudolfinds.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  before_state jsonb,
  after_state jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create index products_brand_id_idx on thebudolfinds.products (brand_id);
create index products_category_id_idx on thebudolfinds.products (category_id);
create index product_variants_product_id_idx on thebudolfinds.product_variants (product_id);
create index listings_product_id_idx on thebudolfinds.merchant_listings (product_id);
create index listings_merchant_id_idx on thebudolfinds.merchant_listings (merchant_id);
create index price_observations_listing_time_idx on thebudolfinds.price_observations (listing_id, observed_at desc);
create index score_snapshots_product_time_idx on thebudolfinds.score_snapshots (product_id, created_at desc);
create index reports_status_created_idx on thebudolfinds.reports (status, created_at);
create index audit_logs_target_idx on thebudolfinds.audit_logs (target_type, target_id, created_at desc);

alter table thebudolfinds.profiles enable row level security;
alter table thebudolfinds.brands enable row level security;
alter table thebudolfinds.categories enable row level security;
alter table thebudolfinds.merchants enable row level security;
alter table thebudolfinds.sellers enable row level security;
alter table thebudolfinds.products enable row level security;
alter table thebudolfinds.product_variants enable row level security;
alter table thebudolfinds.merchant_listings enable row level security;
alter table thebudolfinds.price_observations enable row level security;
alter table thebudolfinds.score_snapshots enable row level security;
alter table thebudolfinds.reports enable row level security;
alter table thebudolfinds.affiliate_clicks enable row level security;
alter table thebudolfinds.audit_logs enable row level security;

create policy "profiles are self readable" on thebudolfinds.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "profiles are self editable" on thebudolfinds.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "catalog is publicly readable" on thebudolfinds.products for select to anon, authenticated using (true);
create policy "variants are publicly readable" on thebudolfinds.product_variants for select to anon, authenticated using (true);
create policy "listings are publicly readable" on thebudolfinds.merchant_listings for select to anon, authenticated using (true);
create policy "prices are publicly readable" on thebudolfinds.price_observations for select to anon, authenticated using (true);
create policy "scores are publicly readable" on thebudolfinds.score_snapshots for select to anon, authenticated using (true);
create policy "reports are self readable" on thebudolfinds.reports for select to authenticated using ((select auth.uid()) = reporter_id);
create policy "reports are anonymously insertable" on thebudolfinds.reports for insert to anon, authenticated with check (reporter_id is null or (select auth.uid()) = reporter_id);
create policy "affiliate clicks are insertable" on thebudolfinds.affiliate_clicks for insert to anon, authenticated with check (user_id is null or (select auth.uid()) = user_id);
create policy "affiliate clicks are self readable" on thebudolfinds.affiliate_clicks for select to authenticated using ((select auth.uid()) = user_id);

create or replace function thebudolfinds.is_admin_or_moderator()
returns boolean
language sql
stable
security invoker
set search_path = thebudolfinds, auth, pg_catalog
as $$
  select exists (
    select 1 from thebudolfinds.profiles
    where id = (select auth.uid()) and role in ('moderator', 'admin')
  );
$$;

create policy "moderators can manage reports" on thebudolfinds.reports for update to authenticated using (thebudolfinds.is_admin_or_moderator()) with check (thebudolfinds.is_admin_or_moderator());
create policy "admins can read audit logs" on thebudolfinds.audit_logs for select to authenticated using (thebudolfinds.is_admin_or_moderator());

grant usage on schema thebudolfinds to anon, authenticated;
grant select on thebudolfinds.products, thebudolfinds.product_variants, thebudolfinds.merchant_listings, thebudolfinds.price_observations, thebudolfinds.score_snapshots to anon, authenticated;
grant select, insert on thebudolfinds.reports to anon, authenticated;
grant select, insert on thebudolfinds.affiliate_clicks to anon, authenticated;
grant select, update on thebudolfinds.profiles to authenticated;
grant select, update on thebudolfinds.reports, thebudolfinds.audit_logs to authenticated;

alter role authenticator set pgrst.db_schemas = 'public, board_pulse, wheretayo, thebudolfinds';
notify pgrst, 'reload config';
