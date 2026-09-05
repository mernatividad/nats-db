create table if not exists board_pulse.review_centers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 180),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null default '',
  logo_url text,
  website_url text,
  enrollment_url text,
  email text,
  phone text,
  social_links jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check (status in ('draft','pending_review','published','needs_update','archived')),
  claim_state text not null default 'unclaimed' check (claim_state in ('unclaimed','pending','claimed')),
  sponsored boolean not null default false,
  last_confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists board_pulse.review_center_professions (
  review_center_id uuid not null references board_pulse.review_centers(id) on delete cascade,
  profession text not null check (char_length(profession) between 2 and 120),
  primary key (review_center_id, profession)
);

create table if not exists board_pulse.review_center_locations (
  id uuid primary key default gen_random_uuid(),
  review_center_id uuid not null references board_pulse.review_centers(id) on delete cascade,
  city text not null check (char_length(city) between 2 and 120),
  area text,
  format text not null check (format in ('onsite','online','hybrid'))
);

create table if not exists board_pulse.review_center_claims (
  id uuid primary key default gen_random_uuid(),
  review_center_id uuid not null references board_pulse.review_centers(id) on delete cascade,
  representative_name text not null,
  role text not null,
  business_email text not null,
  phone text not null,
  relationship text not null,
  evidence_url text,
  requested_corrections text not null default '',
  status text not null default 'submitted' check (status in ('submitted','under_review','approved','rejected')),
  decision_reason text,
  verification_method text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists board_pulse.review_center_submissions (
  id uuid primary key default gen_random_uuid(),
  center_name text not null,
  website_url text,
  contact_name text not null,
  business_email text not null,
  professions text[] not null default '{}',
  locations text[] not null default '{}',
  format text not null check (format in ('onsite','online','hybrid')),
  description text not null default '',
  enrollment_url text,
  public_contact text,
  logo_url text,
  status text not null default 'submitted' check (status in ('submitted','under_review','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table if not exists board_pulse.review_center_reports (
  id uuid primary key default gen_random_uuid(),
  review_center_id uuid not null references board_pulse.review_centers(id) on delete cascade,
  reason text not null check (reason in ('inaccurate','duplicate','misleading','impersonation','other')),
  details text not null,
  reporter_email text,
  status text not null default 'open' check (status in ('open','under_review','resolved','dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists board_pulse.review_center_audit_events (
  id uuid primary key default gen_random_uuid(),
  review_center_id uuid references board_pulse.review_centers(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  actor text not null default 'system',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists review_centers_public_idx on board_pulse.review_centers(status, name);
create index if not exists review_center_professions_lookup_idx on board_pulse.review_center_professions(profession, review_center_id);
create index if not exists review_center_locations_lookup_idx on board_pulse.review_center_locations(city, format, review_center_id);

alter table board_pulse.review_centers enable row level security;
alter table board_pulse.review_center_professions enable row level security;
alter table board_pulse.review_center_locations enable row level security;
alter table board_pulse.review_center_claims enable row level security;
alter table board_pulse.review_center_submissions enable row level security;
alter table board_pulse.review_center_reports enable row level security;
alter table board_pulse.review_center_audit_events enable row level security;

create policy "public can read published review centers" on board_pulse.review_centers for select to anon, authenticated using (status = 'published');
create policy "public can read published center professions" on board_pulse.review_center_professions for select to anon, authenticated using (exists (select 1 from board_pulse.review_centers c where c.id = review_center_id and c.status = 'published'));
create policy "public can read published center locations" on board_pulse.review_center_locations for select to anon, authenticated using (exists (select 1 from board_pulse.review_centers c where c.id = review_center_id and c.status = 'published'));
create policy "public may submit center" on board_pulse.review_center_submissions for insert to anon, authenticated with check (true);
create policy "public may submit claim" on board_pulse.review_center_claims for insert to anon, authenticated with check (exists (select 1 from board_pulse.review_centers c where c.id = review_center_id and c.status = 'published'));
create policy "public may report center" on board_pulse.review_center_reports for insert to anon, authenticated with check (exists (select 1 from board_pulse.review_centers c where c.id = review_center_id and c.status = 'published'));

grant select on board_pulse.review_centers, board_pulse.review_center_professions, board_pulse.review_center_locations to anon, authenticated;
grant insert on board_pulse.review_center_submissions, board_pulse.review_center_claims, board_pulse.review_center_reports to anon, authenticated;
grant all on all tables in schema board_pulse to service_role;

create or replace function board_pulse.touch_review_center_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists review_center_updated_at on board_pulse.review_centers;
create trigger review_center_updated_at before update on board_pulse.review_centers for each row execute function board_pulse.touch_review_center_updated_at();
