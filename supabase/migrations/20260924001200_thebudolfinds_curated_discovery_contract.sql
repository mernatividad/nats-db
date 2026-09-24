-- Forward-only contract repair for TheBudolFinds curated product discovery.
-- Keep this migration schema-qualified: ../nats-db is shared by multiple projects.

create schema if not exists thebudolfinds;
create extension if not exists pgcrypto with schema extensions;

set search_path = thebudolfinds, extensions, public;

alter table thebudolfinds.products
  add column if not exists image_url text,
  add column if not exists image_alt text;

create table if not exists thebudolfinds.homepage_feed_items (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references thebudolfinds.products(id) on delete cascade,
  collection text not null,
  collection_title text not null,
  editorial_blurb text,
  badge text,
  collection_order integer not null default 0,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (collection, product_id),
  constraint homepage_feed_items_window_check check (
    ends_at is null or starts_at is null or starts_at < ends_at
  )
);

-- Older local copies of the feed table may predate one of the columns or constraints.
alter table thebudolfinds.homepage_feed_items
  add column if not exists id uuid default gen_random_uuid(),
  add column if not exists product_id uuid,
  add column if not exists collection text,
  add column if not exists collection_title text,
  add column if not exists editorial_blurb text,
  add column if not exists badge text,
  add column if not exists collection_order integer default 0,
  add column if not exists sort_order integer default 0,
  add column if not exists is_active boolean default true,
  add column if not exists starts_at timestamptz,
  add column if not exists ends_at timestamptz,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

do $$
begin
  if exists (
    select 1 from thebudolfinds.homepage_feed_items where id is null
  ) then
    raise exception 'homepage_feed_items contains null ids';
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and contype = 'p'
  ) then
    alter table thebudolfinds.homepage_feed_items add primary key (id);
  end if;
end
$$;

do $$
begin
  if exists (
    select 1 from thebudolfinds.homepage_feed_items
    where id is null or product_id is null or collection is null or collection_title is null
  ) then
    raise exception 'homepage_feed_items contains null identity values required by the curated discovery contract';
  end if;

  if exists (
    select collection, product_id
    from thebudolfinds.homepage_feed_items
    group by collection, product_id
    having count(*) > 1
  ) then
    raise exception 'homepage_feed_items contains duplicate collection/product rows';
  end if;

  if exists (
    select feed.product_id
    from thebudolfinds.homepage_feed_items feed
    left join thebudolfinds.products product on product.id = feed.product_id
    where product.id is null
  ) then
    raise exception 'homepage_feed_items contains product references that do not exist';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and confrelid = 'thebudolfinds.products'::regclass
      and contype = 'f'
      and conkey = array[
        (select attnum from pg_attribute where attrelid = 'thebudolfinds.homepage_feed_items'::regclass and attname = 'product_id')
      ]::smallint[]
      and confkey = array[
        (select attnum from pg_attribute where attrelid = 'thebudolfinds.products'::regclass and attname = 'id')
      ]::smallint[]
  ) then
    alter table thebudolfinds.homepage_feed_items
      add constraint homepage_feed_items_product_fkey
      foreign key (product_id) references thebudolfinds.products(id) on delete cascade;
  end if;
end
$$;

update thebudolfinds.homepage_feed_items
set collection_order = coalesce(collection_order, 0),
    sort_order = coalesce(sort_order, 0),
    is_active = coalesce(is_active, true),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now())
where collection_order is null
   or sort_order is null
   or is_active is null
   or created_at is null
   or updated_at is null;

alter table thebudolfinds.homepage_feed_items
  alter column product_id set not null,
  alter column collection set not null,
  alter column collection_title set not null,
  alter column collection_order set default 0,
  alter column collection_order set not null,
  alter column sort_order set default 0,
  alter column sort_order set not null,
  alter column is_active set default true,
  alter column is_active set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- Older local copies of the feed table may predate one of the constraints.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%starts_at%'
      and pg_get_constraintdef(oid) like '%ends_at%'
  ) then
    alter table thebudolfinds.homepage_feed_items
      add constraint homepage_feed_items_window_check
      check (ends_at is null or starts_at is null or starts_at < ends_at);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'thebudolfinds.homepage_feed_items'::regclass
      and contype = 'u'
      and conkey = array[
        (select attnum from pg_attribute where attrelid = 'thebudolfinds.homepage_feed_items'::regclass and attname = 'collection'),
        (select attnum from pg_attribute where attrelid = 'thebudolfinds.homepage_feed_items'::regclass and attname = 'product_id')
      ]::smallint[]
  ) then
    alter table thebudolfinds.homepage_feed_items
      add constraint homepage_feed_items_collection_product_key unique (collection, product_id);
  end if;
end
$$;

create index if not exists homepage_feed_items_active_order_idx
  on thebudolfinds.homepage_feed_items (is_active, collection_order, sort_order, id);

create index if not exists homepage_feed_items_collection_sort_idx
  on thebudolfinds.homepage_feed_items (collection, sort_order, updated_at, id);

alter table thebudolfinds.homepage_feed_items enable row level security;

drop policy if exists "homepage feed is publicly readable" on thebudolfinds.homepage_feed_items;
create policy "homepage feed is publicly readable"
  on thebudolfinds.homepage_feed_items
  for select to anon, authenticated
  using (
    is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now())
  );

revoke all on table thebudolfinds.homepage_feed_items from anon, authenticated;
grant select on table thebudolfinds.homepage_feed_items to anon, authenticated;
grant select, insert, update, delete on table thebudolfinds.homepage_feed_items to service_role;

-- Keep the supported seed merchants deterministic without touching other merchants.
insert into thebudolfinds.merchants (name, slug, domain, support_status)
values
  ('Shopee', 'shopee', 'shopee.ph', 'supported'),
  ('Lazada', 'lazada', 'lazada.com.ph', 'supported')
on conflict (slug) do update set
  name = excluded.name,
  domain = excluded.domain,
  support_status = excluded.support_status,
  updated_at = now();

alter table thebudolfinds.affiliate_clicks
  add column if not exists disclosure_shown boolean;

update thebudolfinds.affiliate_clicks
set disclosure_shown = false
where disclosure_shown is null;

alter table thebudolfinds.affiliate_clicks
  alter column disclosure_shown set default false,
  alter column disclosure_shown set not null;

create index if not exists affiliate_clicks_listing_created_idx
  on thebudolfinds.affiliate_clicks (listing_id, created_at desc);

revoke all on table thebudolfinds.affiliate_clicks from anon, authenticated;
grant select, insert on table thebudolfinds.affiliate_clicks to service_role;

create table if not exists thebudolfinds.import_runs (
  id uuid primary key default gen_random_uuid(),
  source_type text not null check (source_type in ('manual_json', 'manual_csv')),
  status text not null check (status in ('completed', 'quarantined', 'failed')),
  accepted_count integer not null default 0,
  quarantined_count integer not null default 0,
  errors jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists thebudolfinds.import_quarantine (
  id uuid primary key default gen_random_uuid(),
  import_run_id uuid not null references thebudolfinds.import_runs(id) on delete cascade,
  record_index integer not null,
  payload jsonb not null,
  error_message text not null,
  created_at timestamptz not null default now()
);

alter table thebudolfinds.import_runs
  add column if not exists id uuid default gen_random_uuid();

update thebudolfinds.import_runs
set id = gen_random_uuid()
where id is null;

alter table thebudolfinds.import_runs
  alter column id set default gen_random_uuid(),
  alter column id set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.import_runs'::regclass and contype = 'p'
  ) then
    alter table thebudolfinds.import_runs add primary key (id);
  end if;
end
$$;

alter table thebudolfinds.import_quarantine
  add column if not exists id uuid default gen_random_uuid();

update thebudolfinds.import_quarantine
set id = gen_random_uuid()
where id is null;

alter table thebudolfinds.import_quarantine
  alter column id set default gen_random_uuid(),
  alter column id set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.import_quarantine'::regclass and contype = 'p'
  ) then
    alter table thebudolfinds.import_quarantine add primary key (id);
  end if;
end
$$;

alter table thebudolfinds.import_runs
  add column if not exists source_type text,
  add column if not exists status text,
  add column if not exists accepted_count integer default 0,
  add column if not exists quarantined_count integer default 0,
  add column if not exists errors jsonb default '[]'::jsonb,
  add column if not exists created_at timestamptz default now();

update thebudolfinds.import_runs
set source_type = coalesce(source_type, 'manual_json'),
    status = coalesce(status, 'failed'),
    accepted_count = coalesce(accepted_count, 0),
    quarantined_count = coalesce(quarantined_count, 0),
    errors = coalesce(errors, '[]'::jsonb),
    created_at = coalesce(created_at, now())
where source_type is null
   or status is null
   or accepted_count is null
   or quarantined_count is null
   or errors is null
   or created_at is null;

alter table thebudolfinds.import_runs
  alter column source_type set default 'manual_json',
  alter column source_type set not null,
  alter column status set not null,
  alter column accepted_count set default 0,
  alter column accepted_count set not null,
  alter column quarantined_count set default 0,
  alter column quarantined_count set not null,
  alter column errors set default '[]'::jsonb,
  alter column errors set not null,
  alter column created_at set default now(),
  alter column created_at set not null;

alter table thebudolfinds.import_quarantine
  add column if not exists import_run_id uuid,
  add column if not exists record_index integer,
  add column if not exists payload jsonb,
  add column if not exists error_message text,
  add column if not exists created_at timestamptz default now();

update thebudolfinds.import_quarantine
set created_at = coalesce(created_at, now())
where created_at is null;

alter table thebudolfinds.import_quarantine
  alter column import_run_id set not null,
  alter column record_index set not null,
  alter column payload set not null,
  alter column error_message set not null,
  alter column created_at set default now(),
  alter column created_at set not null;

-- Older copies may have the tables but not the required checks/foreign key.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.import_runs'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%manual_json%'
      and pg_get_constraintdef(oid) like '%manual_csv%'
  ) then
    alter table thebudolfinds.import_runs
      add constraint import_runs_source_type_check
      check (source_type in ('manual_json', 'manual_csv'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.import_runs'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%completed%'
      and pg_get_constraintdef(oid) like '%quarantined%'
      and pg_get_constraintdef(oid) like '%failed%'
  ) then
    alter table thebudolfinds.import_runs
      add constraint import_runs_status_check
      check (status in ('completed', 'quarantined', 'failed'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'thebudolfinds.import_quarantine'::regclass
      and confrelid = 'thebudolfinds.import_runs'::regclass
      and contype = 'f'
  ) then
    alter table thebudolfinds.import_quarantine
      add constraint import_quarantine_run_fkey
      foreign key (import_run_id) references thebudolfinds.import_runs(id) on delete cascade;
  end if;
end
$$;

create index if not exists import_quarantine_run_idx
  on thebudolfinds.import_quarantine (import_run_id, record_index);

alter table thebudolfinds.import_runs enable row level security;
alter table thebudolfinds.import_quarantine enable row level security;

revoke all on table thebudolfinds.import_runs, thebudolfinds.import_quarantine from anon, authenticated;
grant select, insert, update, delete on table thebudolfinds.import_runs, thebudolfinds.import_quarantine to service_role;

-- Better Auth users are the only valid actors for server-side merchandising audit rows.
do $$
declare
  actor_type text;
begin
  if to_regclass('thebudolfinds.users') is null then
    raise exception 'TheBudolFinds Better Auth users table is missing';
  end if;

  select format_type(att.atttypid, att.atttypmod)
    into actor_type
  from pg_attribute att
  where att.attrelid = 'thebudolfinds.audit_logs'::regclass
    and att.attname = 'actor_id'
    and not att.attisdropped;

  if actor_type is distinct from 'text' then
    raise exception 'thebudolfinds.audit_logs.actor_id must be text for Better Auth users; found %', actor_type;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'thebudolfinds.audit_logs'::regclass
      and confrelid = 'thebudolfinds.users'::regclass
      and contype = 'f'
      and conkey = array[
        (select attnum from pg_attribute where attrelid = 'thebudolfinds.audit_logs'::regclass and attname = 'actor_id')
      ]::smallint[]
      and confkey = array[
        (select attnum from pg_attribute where attrelid = 'thebudolfinds.users'::regclass and attname = 'id')
      ]::smallint[]
  ) then
    alter table thebudolfinds.audit_logs
      add constraint audit_logs_actor_users_fkey
      foreign key (actor_id) references thebudolfinds.users(id) on delete set null;
  end if;
end
$$;

create index if not exists audit_logs_target_created_idx
  on thebudolfinds.audit_logs (target_type, target_id, created_at desc);

revoke all on table thebudolfinds.audit_logs from anon, authenticated;
grant select, insert on table thebudolfinds.audit_logs to service_role;

grant usage on schema thebudolfinds to anon, authenticated, service_role;
