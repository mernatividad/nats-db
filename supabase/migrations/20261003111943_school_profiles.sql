create table if not exists board_pulse.schools (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  display_name text not null,
  normalized_name text not null unique,
  is_verified boolean not null default false,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists board_pulse.school_aliases (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references board_pulse.schools(id) on delete cascade,
  source_name text not null,
  normalized_name text not null unique,
  created_at timestamptz not null default now()
);

create index if not exists school_aliases_school_id_idx on board_pulse.school_aliases(school_id);

create table if not exists board_pulse.school_correction_requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references board_pulse.schools(id) on delete cascade,
  reporter_name text not null,
  reporter_email text not null,
  details text not null,
  status text not null default 'pending' check (status in ('pending', 'reviewing', 'resolved', 'rejected')),
  created_at timestamptz not null default now()
);

create index if not exists school_correction_requests_status_created_idx
  on board_pulse.school_correction_requests(status, created_at desc);

alter table board_pulse.schools enable row level security;
alter table board_pulse.school_aliases enable row level security;
alter table board_pulse.school_correction_requests enable row level security;

drop policy if exists "public can read schools" on board_pulse.schools;
create policy "public can read schools" on board_pulse.schools for select to anon, authenticated using (true);
drop policy if exists "public can read school aliases" on board_pulse.school_aliases;
create policy "public can read school aliases" on board_pulse.school_aliases for select to anon, authenticated using (true);

grant select on table board_pulse.schools, board_pulse.school_aliases to anon, authenticated, service_role;
grant insert, update, delete on table board_pulse.schools, board_pulse.school_aliases to service_role;
grant select, insert, update on table board_pulse.school_correction_requests to service_role;

create or replace function board_pulse.normalize_school_name(p_name text)
returns text
language sql
immutable
parallel safe
as $$
  select upper(regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g'));
$$;

create or replace function board_pulse.school_slug_base(p_name text)
returns text
language sql
immutable
parallel safe
as $$
  select trim(both '-' from regexp_replace(lower(coalesce(p_name, '')), '[^a-z0-9]+', '-', 'g'));
$$;

create or replace function board_pulse.ensure_school_alias(p_name text)
returns void
language plpgsql
set search_path = board_pulse, public
as $$
declare
  normalized text := board_pulse.normalize_school_name(p_name);
  base_slug text;
  school_id uuid;
  new_id uuid := gen_random_uuid();
  new_slug text;
begin
  if normalized = '' then return; end if;

  base_slug := board_pulse.school_slug_base(p_name);
  if base_slug = '' then base_slug := 'school'; end if;
  new_slug := base_slug;
  if exists (select 1 from board_pulse.schools where slug = new_slug and normalized_name <> normalized) then
    new_slug := base_slug || '-' || left(new_id::text, 8);
  end if;

  insert into board_pulse.schools(id, slug, display_name, normalized_name)
  values (new_id, new_slug, btrim(p_name), normalized)
  on conflict (normalized_name) do update set updated_at = now()
  returning id into school_id;

  insert into board_pulse.school_aliases(school_id, source_name, normalized_name)
  values (school_id, btrim(p_name), normalized)
  on conflict (normalized_name) do nothing;
end;
$$;

revoke all on function board_pulse.ensure_school_alias(text) from public, anon, authenticated;
grant execute on function board_pulse.ensure_school_alias(text) to service_role;

create or replace function board_pulse.sync_school_alias_from_performance()
returns trigger
language plpgsql
set search_path = board_pulse, public
as $$
begin
  perform board_pulse.ensure_school_alias(new.school_name);
  return new;
end;
$$;

revoke all on function board_pulse.sync_school_alias_from_performance() from public, anon, authenticated;
grant execute on function board_pulse.sync_school_alias_from_performance() to service_role;

create or replace function board_pulse.sync_school_alias_from_topnotcher()
returns trigger
language plpgsql
set search_path = board_pulse, public
as $$
begin
  perform board_pulse.ensure_school_alias(new.school);
  return new;
end;
$$;

revoke all on function board_pulse.sync_school_alias_from_topnotcher() from public, anon, authenticated;
grant execute on function board_pulse.sync_school_alias_from_topnotcher() to service_role;

drop trigger if exists sync_school_alias_from_performance on board_pulse.school_performance;
create trigger sync_school_alias_from_performance
after insert or update of school_name on board_pulse.school_performance
for each row execute function board_pulse.sync_school_alias_from_performance();

drop trigger if exists sync_school_alias_from_topnotcher on board_pulse.top_notchers;
create trigger sync_school_alias_from_topnotcher
after insert or update of school on board_pulse.top_notchers
for each row execute function board_pulse.sync_school_alias_from_topnotcher();

do $$
declare school_name_value text;
begin
  for school_name_value in
    select school_name from board_pulse.school_performance
    union
    select school from board_pulse.top_notchers
  loop
    perform board_pulse.ensure_school_alias(school_name_value);
  end loop;
end;
$$;
