do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'review_center_server') then
    create role review_center_server nologin;
  end if;
end $$;

create schema if not exists private;
alter schema private owner to postgres;
revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema private to review_center_server;

alter table board_pulse.review_centers add column if not exists featured boolean not null default false;
alter table board_pulse.review_centers add column if not exists featured_priority integer not null default 0;
alter table board_pulse.review_centers add column if not exists featured_starts_at timestamptz;
alter table board_pulse.review_centers add column if not exists featured_ends_at timestamptz;
alter table board_pulse.review_centers add constraint review_centers_featured_state_check check (
  (featured and status = 'published' and sponsored and featured_priority between 0 and 100 and featured_starts_at is not null and featured_ends_at is not null and featured_starts_at < featured_ends_at and featured_ends_at <= featured_starts_at + interval '90 days')
  or (featured and status = 'published' and not sponsored and featured_priority between 0 and 100 and featured_starts_at is not null and featured_ends_at is not null and featured_starts_at < featured_ends_at and featured_ends_at <= featured_starts_at + interval '90 days')
  or (not featured and not sponsored and featured_priority = 0 and featured_starts_at is null and featured_ends_at is null)
);

create index if not exists review_centers_featured_order_idx on board_pulse.review_centers (status, featured, featured_priority, name, id);

create table if not exists private.review_center_featured_terms (
  id uuid primary key default gen_random_uuid(),
  review_center_id uuid not null references board_pulse.review_centers(id) on delete restrict,
  term_sequence integer not null check (term_sequence > 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  ended_at timestamptz,
  unique (review_center_id, term_sequence),
  check (starts_at < ends_at),
  check (ends_at <= starts_at + interval '90 days')
);
alter table private.review_center_featured_terms enable row level security;

create table if not exists private.review_center_lead_events (
  id uuid primary key default gen_random_uuid(),
  review_center_id uuid not null references board_pulse.review_centers(id) on delete restrict,
  client_event_uuid uuid not null,
  event_type text not null check (event_type in ('website_click','enrollment_click','email_click','phone_click')),
  source_surface text not null check (source_surface = 'profile'),
  destination_kind text not null check (destination_kind in ('external_website','enrollment_page','email','phone')),
  profile_path text not null check (profile_path ~ '^/review-centers/[a-z0-9]+(?:-[a-z0-9]+)*$' and char_length(profile_path) <= 200),
  featured_at_event boolean not null default false,
  sponsored_at_event boolean not null default false,
  created_at timestamptz not null default now(),
  constraint review_center_lead_event_uuid_unique unique (client_event_uuid),
  constraint review_center_lead_event_mapping_check check (
    (event_type = 'website_click' and destination_kind = 'external_website') or
    (event_type = 'enrollment_click' and destination_kind = 'enrollment_page') or
    (event_type = 'email_click' and destination_kind = 'email') or
    (event_type = 'phone_click' and destination_kind = 'phone')
  )
);
alter table private.review_center_lead_events enable row level security;
revoke all on private.review_center_lead_events, private.review_center_featured_terms from public, anon, authenticated, service_role;

create table if not exists private.review_center_lead_rate_limits (
  bucket_hash text not null,
  window_start timestamptz not null,
  event_count integer not null default 0 check (event_count >= 0),
  primary key (bucket_hash, window_start)
);
revoke all on private.review_center_lead_rate_limits from public, anon, authenticated, service_role;

create or replace function private.record_review_center_lead_event(p_center_id uuid, p_client_event_uuid uuid, p_event_type text, p_source_surface text, p_destination_kind text, p_profile_slug text, p_bucket_hash text, p_consent_token text) returns jsonb
language plpgsql security definer set search_path = pg_catalog, board_pulse, private as $$
declare center_row board_pulse.review_centers%rowtype; inserted_id uuid; window_start timestamptz := date_trunc('minute', now()) - make_interval(mins => (extract(minute from now())::integer % 15));
begin
  select * into center_row from board_pulse.review_centers where id = p_center_id and status = 'published' for share;
  if not found or p_consent_token is null or length(p_consent_token) = 0 then raise exception using errcode = 'P0001', message = 'ineligible_event'; end if;
  if (p_event_type = 'website_click' and (p_destination_kind <> 'external_website' or center_row.website_url is null)) or (p_event_type = 'enrollment_click' and (p_destination_kind <> 'enrollment_page' or center_row.enrollment_url is null)) or (p_event_type = 'email_click' and (p_destination_kind <> 'email' or center_row.email is null)) or (p_event_type = 'phone_click' and (p_destination_kind <> 'phone' or center_row.phone is null)) then raise exception using errcode = 'P0001', message = 'ineligible_destination'; end if;
  insert into private.review_center_lead_events (review_center_id, client_event_uuid, event_type, source_surface, destination_kind, profile_path, featured_at_event, sponsored_at_event) values (p_center_id, p_client_event_uuid, p_event_type, p_source_surface, p_destination_kind, '/review-centers/' || p_profile_slug, center_row.featured, center_row.sponsored) on conflict (client_event_uuid) do nothing returning id into inserted_id;
  if inserted_id is null then return jsonb_build_object('duplicate', true); end if;
  insert into private.review_center_lead_rate_limits(bucket_hash, window_start, event_count) values (p_bucket_hash, window_start, 1) on conflict (bucket_hash, window_start) do update set event_count = private.review_center_lead_rate_limits.event_count + 1 where private.review_center_lead_rate_limits.event_count < 100;
  if not found then raise exception using errcode = 'P0001', message = 'rate_limited'; end if;
  return jsonb_build_object('ok', true);
end; $$;

revoke all on function private.record_review_center_lead_event(uuid, uuid, text, text, text, text, text, text) from public, anon, authenticated, service_role;
grant execute on function private.record_review_center_lead_event(uuid, uuid, text, text, text, text, text, text) to review_center_server;

grant all on private.review_center_lead_events, private.review_center_lead_rate_limits, private.review_center_featured_terms to review_center_server;

create or replace function private.report_review_center_leads(p_days integer) returns table(center_id uuid, center_name text, currently_featured boolean, currently_sponsored boolean, total bigint, website bigint, enrollment bigint, email bigint, phone bigint)
language sql security definer set search_path = pg_catalog, board_pulse, private as $$
  select c.id, c.name, c.featured, c.sponsored, count(e.id), count(e.id) filter (where e.event_type = 'website_click'), count(e.id) filter (where e.event_type = 'enrollment_click'), count(e.id) filter (where e.event_type = 'email_click'), count(e.id) filter (where e.event_type = 'phone_click')
  from board_pulse.review_centers c left join private.review_center_lead_events e on e.review_center_id = c.id and e.created_at >= now() - make_interval(days => p_days)
  where p_days in (7,30,90) group by c.id, c.name, c.featured, c.sponsored order by count(e.id) desc, c.name;
$$;
create or replace function private.purge_review_center_lead_events() returns integer language plpgsql security definer set search_path = pg_catalog, private as $$ declare deleted_count integer; begin delete from private.review_center_lead_events where created_at < now() - interval '90 days'; get diagnostics deleted_count = row_count; return deleted_count; end; $$;
create or replace function private.expire_review_center_placements() returns integer language plpgsql security definer set search_path = pg_catalog, board_pulse, private as $$ declare changed_count integer; begin update board_pulse.review_centers set featured = false, sponsored = false, featured_priority = 0, featured_starts_at = null, featured_ends_at = null where featured and featured_ends_at <= now(); get diagnostics changed_count = row_count; return changed_count; end; $$;
revoke all on function private.report_review_center_leads(integer), private.purge_review_center_lead_events(), private.expire_review_center_placements() from public, anon, authenticated, service_role;
grant execute on function private.report_review_center_leads(integer), private.purge_review_center_lead_events(), private.expire_review_center_placements() to review_center_server;
