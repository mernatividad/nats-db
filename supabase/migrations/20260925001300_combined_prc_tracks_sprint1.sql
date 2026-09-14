-- Sprint 1: independent PRC result tracks.
--
-- This migration is intentionally forward-only. Legacy exams and dependent
-- rows are retained; the old source-URL index is removed only after the
-- staged identity backfill succeeds.

create or replace function board_pulse.canonicalize_prc_url(p_url text)
returns text
language sql
immutable
strict
set search_path = ''
as $$
  select regexp_replace(
    regexp_replace(lower(btrim(p_url)), '[?#].*$', ''),
    '/+$', ''
  )
  where btrim(p_url) ~* '^https?://[^[:space:]]+$';
$$;

create table board_pulse.prc_releases (
  id uuid primary key default extensions.gen_random_uuid(),
  canonical_article_url text not null,
  title text not null,
  scheduled_date date,
  status text not null default 'discovered',
  expected_track_count integer not null default 0,
  latest_parser_version text not null,
  source_version_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint prc_releases_canonical_url_key unique (canonical_article_url),
  constraint prc_releases_status_check check (status in ('discovered', 'partial', 'published', 'needs_review', 'archived')),
  constraint prc_releases_expected_count_check check (expected_track_count >= 0),
  constraint prc_releases_url_check check (canonical_article_url = board_pulse.canonicalize_prc_url(canonical_article_url)),
  constraint prc_releases_hash_check check (source_version_hash is null or source_version_hash ~ '^[0-9a-f]{64}$')
);

-- Stage 1: nullable identity columns. They are made required below only after
-- all existing rows have been mapped and validated.
alter table board_pulse.exams
  add column if not exists release_id uuid,
  add column if not exists track_key text,
  add column if not exists track_name text,
  add column if not exists track_status text default 'pending',
  add column if not exists validation_status text default 'unverified',
  add column if not exists is_searchable boolean default false,
  add column if not exists updated_at timestamptz default now();

create table board_pulse.prc_release_documents (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references board_pulse.prc_releases(id) on delete restrict,
  exam_id uuid references board_pulse.exams(id) on delete restrict,
  document_type text not null,
  label text not null,
  canonical_url text not null,
  association_confidence text not null default 'high',
  top_rank_limit integer,
  version_hash text,
  parse_status text not null default 'pending',
  staging_object_key text,
  committed_object_key text,
  promotion_status text not null default 'staged',
  promoted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint prc_release_documents_type_check check (document_type in ('official_result', 'passers', 'topnotchers', 'performance')),
  constraint prc_release_documents_confidence_check check (association_confidence in ('high', 'medium', 'ambiguous')),
  constraint prc_release_documents_parse_check check (parse_status in ('pending', 'processing', 'parsed', 'failed', 'ambiguous')),
  constraint prc_release_documents_promotion_check check (promotion_status in ('staged', 'promoted', 'failed')),
  constraint prc_release_documents_rank_check check (top_rank_limit is null or top_rank_limit > 0),
  constraint prc_release_documents_hash_check check (version_hash is null or version_hash ~ '^[0-9a-f]{64}$'),
  constraint prc_release_documents_owner_check check (
    (document_type in ('official_result', 'performance') and exam_id is null)
    or (document_type in ('passers', 'topnotchers') and exam_id is not null)
  ),
  constraint prc_release_documents_promoted_key_check check (
    (promotion_status = 'promoted' and committed_object_key is not null and promoted_at is not null)
    or promotion_status <> 'promoted'
  )
);

create table board_pulse.release_batches (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references board_pulse.prc_releases(id) on delete restrict,
  source_version_hash text not null,
  expected_track_count integer not null default 0,
  terminal_track_count integer not null default 0,
  search_refresh_status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint release_batches_release_hash_key unique (release_id, source_version_hash),
  constraint release_batches_hash_check check (source_version_hash ~ '^[0-9a-f]{64}$'),
  constraint release_batches_counts_check check (expected_track_count >= 0 and terminal_track_count >= 0 and terminal_track_count <= expected_track_count),
  constraint release_batches_refresh_check check (search_refresh_status in ('open', 'pending', 'running', 'succeeded', 'failed'))
);

create table board_pulse.release_artifacts (
  id uuid primary key default extensions.gen_random_uuid(),
  release_id uuid not null references board_pulse.prc_releases(id) on delete restrict,
  exam_id uuid not null references board_pulse.exams(id) on delete restrict,
  artifact_kind text not null,
  staging_object_key text not null,
  committed_object_key text not null,
  created_at timestamptz not null default now(),
  constraint release_artifacts_identity_key unique (exam_id, artifact_kind, committed_object_key)
);
alter table board_pulse.release_artifacts enable row level security;
create policy "public can read release artifacts" on board_pulse.release_artifacts for select to anon, authenticated using (true);
grant select on board_pulse.release_artifacts to anon, authenticated, service_role;
grant insert, update, delete on board_pulse.release_artifacts to service_role;

alter table board_pulse.school_performance
  add column if not exists first_timers_passed_count integer,
  add column if not exists first_timers_failed_count integer,
  add column if not exists first_timers_conditioned_count integer,
  add column if not exists first_timers_total_count integer,
  add column if not exists first_timers_passing_percentage numeric,
  add column if not exists repeaters_passed_count integer,
  add column if not exists repeaters_failed_count integer,
  add column if not exists repeaters_conditioned_count integer,
  add column if not exists repeaters_total_count integer,
  add column if not exists repeaters_passing_percentage numeric,
  add column if not exists overall_failed_count integer,
  add column if not exists overall_conditioned_count integer;

create table board_pulse.exam_ingestion_states (
  release_id uuid not null references board_pulse.prc_releases(id) on delete restrict,
  track_key text not null,
  parser_version text not null,
  exam_id uuid references board_pulse.exams(id) on delete restrict,
  is_expected boolean not null default true,
  expected_source_hash text,
  state text not null default 'pending',
  attempt_count integer not null default 0,
  lease_owner uuid,
  lease_fencing_token bigint not null default 0,
  lease_until timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (release_id, track_key, parser_version),
  constraint exam_ingestion_states_state_check check (state in ('pending', 'processing', 'published', 'failed', 'unavailable', 'ambiguous', 'history')),
  constraint exam_ingestion_states_history_check check (state <> 'history' or not is_expected),
  constraint exam_ingestion_states_count_check check (attempt_count >= 0),
  constraint exam_ingestion_states_hash_check check (expected_source_hash is null or expected_source_hash ~ '^[0-9a-f]{64}$'),
  constraint exam_ingestion_states_lease_check check ((lease_owner is null and lease_until is null) or (lease_owner is not null and lease_until is not null))
);

create table board_pulse.release_outbox (
  id uuid primary key default extensions.gen_random_uuid(),
  batch_id uuid not null references board_pulse.release_batches(id) on delete restrict,
  release_id uuid not null references board_pulse.prc_releases(id) on delete restrict,
  exam_id uuid not null references board_pulse.exams(id) on delete restrict,
  event_key text not null unique,
  event_type text not null,
  source_version_hash text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  lease_owner uuid,
  lease_fencing_token bigint not null default 0,
  lease_until timestamptz,
  attempt_count integer not null default 0,
  max_attempts integer not null default 5,
  next_attempt_at timestamptz not null default now(),
  last_error text,
  succeeded_at timestamptz,
  dead_lettered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint release_outbox_event_type_check check (event_type = 'exam_results_released'),
  constraint release_outbox_status_check check (status in ('pending', 'processing', 'succeeded', 'dead_letter')),
  constraint release_outbox_event_key_check check (event_key = exam_id::text || ':' || event_type || ':' || source_version_hash),
  constraint release_outbox_hash_check check (source_version_hash ~ '^[0-9a-f]{64}$'),
  constraint release_outbox_count_check check (attempt_count >= 0),
  constraint release_outbox_attempt_limit_check check (max_attempts > 0),
  constraint release_outbox_lease_check check ((lease_owner is null and lease_until is null) or (lease_owner is not null and lease_until is not null))
);

create table board_pulse.exam_route_aliases (
  alias_slug text not null,
  alias_kind text not null,
  canonical_exam_id uuid not null references board_pulse.exams(id) on delete restrict,
  canonical_path text not null,
  created_at timestamptz not null default now(),
  primary key (alias_slug, alias_kind),
  constraint exam_route_aliases_kind_check check (alias_kind in ('passers', 'top-notchers', 'performance')),
  constraint exam_route_aliases_path_check check (canonical_path ~ '^/[a-z0-9]+(?:-[a-z0-9]+)*$')
);

create table board_pulse.migration_manifests (
  id uuid primary key default extensions.gen_random_uuid(),
  migration_key text not null unique,
  status text not null default 'prepared',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint migration_manifests_status_check check (status in ('prepared', 'running', 'verified', 'failed'))
);

-- Record the prepared manifest before any backfill mutation.
insert into board_pulse.migration_manifests (migration_key, status, payload)
values ('20260914173053_combined_prc_tracks_sprint1', 'prepared', jsonb_build_object('source', 'legacy exams'))
on conflict (migration_key) do nothing;

-- Stage 2: preflight and legacy mapping. Do not mutate dependents here: the
-- existing exam IDs remain canonical FK targets for this release.
do $$
declare
  invalid_count bigint;
  duplicate_count bigint;
begin
  select count(*) into invalid_count
  from board_pulse.exams
  where source_article_url is null
     or board_pulse.canonicalize_prc_url(source_article_url) is null
     or btrim(category) = '';
  if invalid_count > 0 then
    raise exception 'legacy exam preflight failed: % rows have null/invalid source URL or category', invalid_count;
  end if;

  select count(*) into duplicate_count
  from (
    select board_pulse.canonicalize_prc_url(source_article_url)
    from board_pulse.exams
    group by 1
    having count(*) > 1
  ) duplicates;
  if duplicate_count > 0 then
    raise exception 'legacy exam preflight failed: % normalized article URL collisions', duplicate_count;
  end if;
end;
$$;

insert into board_pulse.prc_releases (canonical_article_url, title, scheduled_date, status, expected_track_count, latest_parser_version)
select board_pulse.canonicalize_prc_url(e.source_article_url), max(e.name), min(e.scheduled_date),
       case when bool_or(e.results_released_at is not null) then 'published' else 'discovered' end,
       count(*), 'legacy-backfill'
from board_pulse.exams e
group by board_pulse.canonicalize_prc_url(e.source_article_url);

update board_pulse.migration_manifests
set status = 'running', payload = jsonb_build_object(
  'source', 'legacy exams', 'exam_count', (select count(*) from board_pulse.exams),
  'release_count', (select count(*) from board_pulse.prc_releases)
), updated_at = now()
where migration_key = '20260914173053_combined_prc_tracks_sprint1';

update board_pulse.exams e
set release_id = r.id,
    track_key = lower(regexp_replace(regexp_replace(btrim(e.category), '[^[:alnum:]]+', '-', 'g'), '(^-|-$)', '', 'g')),
    track_name = btrim(e.category),
    source_article_url = board_pulse.canonicalize_prc_url(e.source_article_url),
    track_status = case when e.results_released_at is not null then 'published' else 'pending' end,
    validation_status = case when e.validation_status = 'verified' then 'validated' else 'unverified' end,
    is_searchable = coalesce(e.is_searchable, false)
from board_pulse.prc_releases r
where r.canonical_article_url = board_pulse.canonicalize_prc_url(e.source_article_url);

-- Track keys are unique within a release.  Preserve every legacy row while
-- making collisions replayable: the first row (ordered by stable exam ID)
-- keeps the base key and subsequent rows receive deterministic suffixes.
do $$
declare duplicate_group record; duplicate_exam record; suffix integer;
begin
  for duplicate_group in
    select release_id, track_key from board_pulse.exams group by release_id, track_key having count(*) > 1
  loop
    suffix := 1;
    for duplicate_exam in
      select id from board_pulse.exams where release_id = duplicate_group.release_id and track_key = duplicate_group.track_key order by id
    loop
      if suffix > 1 then
        update board_pulse.exams set track_key = duplicate_group.track_key || '-legacy-' || suffix where id = duplicate_exam.id;
      end if;
      suffix := suffix + 1;
    end loop;
  end loop;
end;
$$;

-- Slugs are globally unique in the legacy schema.  Treat case/whitespace
-- variants as collisions too and suffix later rows deterministically.
do $$
declare duplicate_group record; duplicate_exam record; suffix integer; candidate text;
begin
  for duplicate_group in
    select lower(btrim(slug)) as slug_key from board_pulse.exams group by lower(btrim(slug)) having count(*) > 1
  loop
    suffix := 1;
    for duplicate_exam in
      select id, btrim(slug) as base_slug from board_pulse.exams where lower(btrim(slug)) = duplicate_group.slug_key order by id
    loop
      if suffix > 1 then
        candidate := duplicate_exam.base_slug || '-legacy-' || suffix;
        while exists (select 1 from board_pulse.exams where slug = candidate and id <> duplicate_exam.id) loop
          suffix := suffix + 1;
          candidate := duplicate_exam.base_slug || '-legacy-' || suffix;
        end loop;
        update board_pulse.exams set slug = candidate where id = duplicate_exam.id;
      end if;
      suffix := suffix + 1;
    end loop;
  end loop;
end;
$$;

do $$
declare invalid_count bigint;
begin
  select count(*) into invalid_count from board_pulse.exams
  where release_id is null or track_key is null or track_key = '' or track_name is null
     or track_status not in ('pending', 'processing', 'published', 'failed', 'unavailable')
     or validation_status not in ('unverified', 'validating', 'validated', 'failed', 'needs_review');
  if invalid_count > 0 then raise exception 'legacy exam backfill validation failed: % invalid exam identities', invalid_count; end if;
end;
$$;

alter table board_pulse.exams
  alter column release_id set not null,
  alter column track_key set not null,
  alter column track_name set not null,
  alter column track_status set not null,
  alter column validation_status set not null,
  alter column is_searchable set not null;

alter table board_pulse.exams
  add constraint exams_release_id_fkey foreign key (release_id) references board_pulse.prc_releases(id) on delete restrict,
  add constraint exams_track_status_check check (track_status in ('pending', 'processing', 'published', 'failed', 'unavailable')),
  add constraint exams_validation_status_check check (validation_status in ('unverified', 'validating', 'validated', 'failed', 'needs_review')),
  add constraint exams_track_key_check check (track_key = btrim(track_key) and track_key <> ''),
  add constraint exams_track_identity_key unique (release_id, track_key);

alter table board_pulse.exams add constraint exams_id_release_key unique (id, release_id);
alter table board_pulse.release_batches add constraint release_batches_id_release_key unique (id, release_id);

alter table board_pulse.prc_release_documents drop constraint if exists prc_release_documents_exam_id_fkey;
alter table board_pulse.prc_release_documents add constraint prc_release_documents_exam_release_fkey
  foreign key (exam_id, release_id) references board_pulse.exams(id, release_id);
alter table board_pulse.release_outbox drop constraint if exists release_outbox_release_id_fkey;
alter table board_pulse.release_outbox drop constraint if exists release_outbox_exam_id_fkey;
alter table board_pulse.release_outbox add constraint release_outbox_batch_release_fkey
  foreign key (batch_id, release_id) references board_pulse.release_batches(id, release_id);
alter table board_pulse.release_outbox add constraint release_outbox_exam_release_fkey
  foreign key (exam_id, release_id) references board_pulse.exams(id, release_id);

insert into board_pulse.exam_ingestion_states (release_id, track_key, parser_version, exam_id, is_expected, expected_source_hash, state)
select e.release_id, e.track_key, 'legacy-backfill', e.id, true, null, e.track_status
from board_pulse.exams e;

-- The old index encoded the incompatible article-as-exam identity. It is safe
-- to remove only after the normalized release identity and track key exist.
drop index if exists board_pulse.exams_source_article_url_key;

create index prc_release_documents_release_idx on board_pulse.prc_release_documents (release_id);
create index prc_release_documents_exam_idx on board_pulse.prc_release_documents (exam_id);
create unique index prc_release_documents_identity_key
  on board_pulse.prc_release_documents (release_id, document_type, canonical_url);
create index exam_ingestion_states_expected_idx on board_pulse.exam_ingestion_states (release_id, is_expected, parser_version);
create index exam_ingestion_states_exam_state_idx on board_pulse.exam_ingestion_states (exam_id, state);
create index release_batches_batch_status_idx on board_pulse.release_batches (id, search_refresh_status);
create index release_outbox_batch_status_idx on board_pulse.release_outbox (batch_id, status);
create index release_outbox_exam_status_idx on board_pulse.release_outbox (exam_id, status);
create index exam_route_aliases_exam_idx on board_pulse.exam_route_aliases (canonical_exam_id);
create index exams_release_idx on board_pulse.exams (release_id);

create or replace function board_pulse.validate_exam_track_links()
returns trigger
language plpgsql
security definer
set search_path = board_pulse, pg_catalog
as $$
begin
  if tg_table_name = 'exams' then
    if not exists (select 1 from board_pulse.prc_releases r where r.id = new.release_id and r.canonical_article_url = board_pulse.canonicalize_prc_url(new.source_article_url)) then
      raise exception using errcode = '23514', message = 'exam_release_mismatch';
    end if;
  elsif tg_table_name = 'exam_ingestion_states' and new.exam_id is not null then
    if not exists (select 1 from board_pulse.exams e where e.id = new.exam_id and e.release_id = new.release_id and e.track_key = new.track_key) then
      raise exception using errcode = '23514', message = 'ingestion_state_exam_mismatch';
    end if;
  elsif tg_table_name = 'exam_ingestion_states' then
    if new.expected_source_hash is not null and not exists (select 1 from board_pulse.prc_releases r where r.id = new.release_id and r.source_version_hash = new.expected_source_hash) then
      raise exception using errcode = '23514', message = 'ingestion_state_hash_mismatch';
    end if;
  elsif tg_table_name = 'release_outbox' then
    if not exists (select 1 from board_pulse.release_batches b join board_pulse.prc_releases r on r.id = b.release_id where b.id = new.batch_id and b.release_id = new.release_id and b.source_version_hash = new.source_version_hash and r.source_version_hash = new.source_version_hash) then
      raise exception using errcode = '23514', message = 'outbox_release_mismatch';
    end if;
  end if;
  return new;
end;
$$;

create trigger exams_release_link_check before insert or update of release_id, source_article_url
  on board_pulse.exams for each row execute function board_pulse.validate_exam_track_links();
create trigger ingestion_state_exam_link_check before insert or update of release_id, track_key, exam_id
  on board_pulse.exam_ingestion_states for each row execute function board_pulse.validate_exam_track_links();
create trigger outbox_release_link_check before insert or update of batch_id, release_id, source_version_hash
  on board_pulse.release_outbox for each row execute function board_pulse.validate_exam_track_links();

alter table board_pulse.prc_releases enable row level security;
alter table board_pulse.prc_release_documents enable row level security;
alter table board_pulse.release_batches enable row level security;
alter table board_pulse.exam_ingestion_states enable row level security;
alter table board_pulse.release_outbox enable row level security;
alter table board_pulse.exam_route_aliases enable row level security;
alter table board_pulse.migration_manifests enable row level security;

create policy "public can read PRC releases" on board_pulse.prc_releases for select to anon, authenticated using (true);
create policy "public can read release documents" on board_pulse.prc_release_documents for select to anon, authenticated using (true);
create policy "public can read exam route aliases" on board_pulse.exam_route_aliases for select to anon, authenticated using (true);
create policy "service role manages PRC releases" on board_pulse.prc_releases for all to service_role using (true) with check (true);
create policy "service role manages release documents" on board_pulse.prc_release_documents for all to service_role using (true) with check (true);
create policy "service role manages release batches" on board_pulse.release_batches for all to service_role using (true) with check (true);
create policy "service role manages ingestion states" on board_pulse.exam_ingestion_states for all to service_role using (true) with check (true);
create policy "service role manages release outbox" on board_pulse.release_outbox for all to service_role using (true) with check (true);
create policy "service role manages route aliases" on board_pulse.exam_route_aliases for all to service_role using (true) with check (true);
create policy "service role manages migration manifests" on board_pulse.migration_manifests for all to service_role using (true) with check (true);

grant select on board_pulse.prc_releases, board_pulse.prc_release_documents, board_pulse.exam_route_aliases to anon, authenticated;
grant select, insert, update, delete on board_pulse.prc_releases, board_pulse.prc_release_documents, board_pulse.release_batches, board_pulse.exam_ingestion_states, board_pulse.release_outbox, board_pulse.release_artifacts, board_pulse.exam_route_aliases, board_pulse.migration_manifests to service_role;
grant select, insert, update, delete on board_pulse.exams to service_role;

create or replace function board_pulse.claim_release_outbox(
  p_lease_owner uuid, p_lease_seconds integer default 900, p_limit integer default 10
)
returns setof board_pulse.release_outbox
language plpgsql security definer set search_path = board_pulse, pg_catalog
as $$
begin
  if p_lease_seconds < 1 or p_limit < 1 or p_limit > 100 then
    raise exception using errcode = '22023', message = 'invalid_outbox_claim_options';
  end if;
  return query
  with candidates as (
    select o.id
    from board_pulse.release_outbox o
    where ((o.status = 'pending' and o.next_attempt_at <= now())
       or (o.status = 'processing' and o.lease_until < now()))
      and o.attempt_count < o.max_attempts
    order by o.next_attempt_at asc, o.created_at asc
    for update skip locked
    limit p_limit
  )
  update board_pulse.release_outbox o
  set status = 'processing', lease_owner = p_lease_owner,
      lease_fencing_token = o.lease_fencing_token + 1,
      lease_until = now() + make_interval(secs => p_lease_seconds),
      attempt_count = o.attempt_count + 1, updated_at = now()
  from candidates c
  where o.id = c.id
  returning o.*;
end;
$$;

-- The manifest is the replay contract: it captures every release and exam
-- identity produced by this migration, including the source URL, parser, key,
-- slug, and release hash.  It is intentionally updated after backfill and
-- constraint installation so a replay can prove the complete final mapping.
update board_pulse.migration_manifests m
set status = 'prepared',
    payload = jsonb_build_object(
      'source', 'legacy exams',
      'exam_count', (select count(*) from board_pulse.exams),
      'release_count', (select count(*) from board_pulse.prc_releases),
      'releases', coalesce((select jsonb_agg(jsonb_build_object('release_id', r.id, 'canonical_article_url', r.canonical_article_url, 'source_version_hash', r.source_version_hash, 'latest_parser_version', r.latest_parser_version) order by r.id) from board_pulse.prc_releases r), '[]'::jsonb),
      'exams', coalesce((select jsonb_agg(jsonb_build_object('exam_id', e.id, 'release_id', e.release_id, 'track_key', e.track_key, 'track_name', e.track_name, 'slug', e.slug, 'source_article_url', e.source_article_url) order by e.id) from board_pulse.exams e), '[]'::jsonb),
      'documents', coalesce((select jsonb_agg(jsonb_build_object('document_id', d.id, 'release_id', d.release_id, 'exam_id', d.exam_id, 'document_type', d.document_type, 'canonical_url', d.canonical_url, 'version_hash', d.version_hash) order by d.id) from board_pulse.prc_release_documents d), '[]'::jsonb),
      'batches', coalesce((select jsonb_agg(jsonb_build_object('batch_id', b.id, 'release_id', b.release_id, 'source_version_hash', b.source_version_hash) order by b.id) from board_pulse.release_batches b), '[]'::jsonb),
      'ingestion_states', coalesce((select jsonb_agg(jsonb_build_object('release_id', s.release_id, 'track_key', s.track_key, 'parser_version', s.parser_version, 'exam_id', s.exam_id, 'is_expected', s.is_expected, 'expected_source_hash', s.expected_source_hash, 'state', s.state) order by s.release_id, s.track_key, s.parser_version) from board_pulse.exam_ingestion_states s), '[]'::jsonb)
    ),
    updated_at = now()
where m.migration_key = '20260914173053_combined_prc_tracks_sprint1';

create or replace function board_pulse.upsert_prc_release(
  p_canonical_article_url text,
  p_title text,
  p_scheduled_date date,
  p_parser_version text,
  p_source_version_hash text,
  p_batch_id uuid default null
)
returns table(release_id uuid, batch_id uuid, canonical_article_url text, status text)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare release_row board_pulse.prc_releases%rowtype; batch_row board_pulse.release_batches%rowtype; canonical_url text;
begin
  canonical_url := board_pulse.canonicalize_prc_url(p_canonical_article_url);
  if canonical_url is null or btrim(p_title) = '' or p_parser_version is null or p_source_version_hash !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'invalid_release_contract';
  end if;
  insert into board_pulse.prc_releases(canonical_article_url, title, scheduled_date, latest_parser_version, source_version_hash)
  values(canonical_url, btrim(p_title), p_scheduled_date, btrim(p_parser_version), p_source_version_hash)
  on conflict on constraint prc_releases_canonical_url_key do update set title = excluded.title, scheduled_date = excluded.scheduled_date,
    latest_parser_version = excluded.latest_parser_version,
    status = case when board_pulse.prc_releases.source_version_hash is distinct from excluded.source_version_hash then 'discovered' else board_pulse.prc_releases.status end,
    source_version_hash = excluded.source_version_hash, updated_at = now()
  returning * into release_row;
  if p_batch_id is not null then
    select * into batch_row from board_pulse.release_batches b where b.id = p_batch_id and b.release_id = release_row.id and b.source_version_hash = p_source_version_hash for update;
    if not found then raise exception using errcode = 'P0001', message = 'batch_release_mismatch'; end if;
  else
    insert into board_pulse.release_batches(release_id, source_version_hash)
    values(release_row.id, p_source_version_hash)
    on conflict on constraint release_batches_release_hash_key do update set updated_at = now()
    returning * into batch_row;
  end if;
  return query select release_row.id as release_id, batch_row.id as batch_id, release_row.canonical_article_url, release_row.status;
end;
$$;

create or replace function board_pulse.sync_expected_tracks(
  p_release_id uuid, p_parser_version text, p_batch_id uuid, p_source_version_hash text, p_expected_tracks_json jsonb
)
returns table(track_key text, track_name text, slug text, exam_id uuid, state text, is_expected boolean)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare item jsonb; key text; current_keys text[] := '{}'::text[]; release_row board_pulse.prc_releases%rowtype; expected_count integer;
begin
  select * into release_row from board_pulse.prc_releases where id = p_release_id for update;
  if not found then raise exception using errcode = 'P0001', message = 'release_not_found'; end if;
  if not exists(select 1 from board_pulse.release_batches where id = p_batch_id and release_id = p_release_id and source_version_hash = p_source_version_hash) then
    raise exception using errcode = 'P0001', message = 'batch_release_mismatch';
  end if;
  update board_pulse.exams e
  set track_status = 'pending', validation_status = 'validating', is_searchable = false, updated_at = now()
  from board_pulse.exam_ingestion_states s
  where s.release_id = p_release_id and s.parser_version = p_parser_version and s.is_expected
    and s.state = 'published' and s.expected_source_hash is distinct from p_source_version_hash
    and e.id = s.exam_id;
  for item in select value from jsonb_array_elements(coalesce(p_expected_tracks_json, '[]'::jsonb)) loop
    key := lower(btrim(item->>'track_key'));
    if key is null or key = '' or btrim(item->>'track_name') = '' or btrim(item->>'slug') = '' then raise exception using errcode = '22023', message = 'invalid_expected_track'; end if;
    current_keys := array_append(current_keys, key);
    insert into board_pulse.exam_ingestion_states(release_id, track_key, parser_version, is_expected, expected_source_hash, state)
    values(p_release_id, key, p_parser_version, true, p_source_version_hash, 'pending')
    on conflict on constraint exam_ingestion_states_pkey do update set is_expected = true, expected_source_hash = excluded.expected_source_hash,
      state = case
        when board_pulse.exam_ingestion_states.state = 'history'
          or (board_pulse.exam_ingestion_states.state = 'published'
              and board_pulse.exam_ingestion_states.expected_source_hash is distinct from excluded.expected_source_hash)
          then 'pending'
        else board_pulse.exam_ingestion_states.state
      end,
      updated_at = now();
  end loop;
  update board_pulse.exam_ingestion_states s set is_expected = false, state = 'history', updated_at = now()
  where s.release_id = p_release_id and s.parser_version = p_parser_version and s.is_expected and not (s.track_key = any(current_keys));
  select count(*) into expected_count from board_pulse.exam_ingestion_states s0 where s0.release_id = p_release_id and s0.parser_version = p_parser_version and s0.is_expected;
  update board_pulse.prc_releases set expected_track_count = expected_count, latest_parser_version = p_parser_version, updated_at = now() where id = p_release_id;
  update board_pulse.release_batches set expected_track_count = expected_count, terminal_track_count = 0, search_refresh_status = 'open', updated_at = now() where id = p_batch_id;
  return query select s.track_key, coalesce(e.track_name, s.track_key), e.slug, s.exam_id, s.state, s.is_expected
    from board_pulse.exam_ingestion_states s left join board_pulse.exams e on e.id = s.exam_id
    where s.release_id = p_release_id and s.parser_version = p_parser_version and s.is_expected order by s.track_key;
end;
$$;

create or replace function board_pulse.claim_exam_track(
  p_release_url text, p_track_key text, p_track_name text, p_slug text, p_scheduled_date date, p_parser_version text, p_batch_id uuid
)
returns table(release_id uuid, exam_id uuid, batch_id uuid, claim_status text, lease_owner uuid, lease_fencing_token bigint)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare r board_pulse.prc_releases%rowtype; e board_pulse.exams%rowtype; s board_pulse.exam_ingestion_states%rowtype; owner_id uuid; key text;
  batch_hash text; slug_value text; slug_suffix integer := 0;
begin
  key := lower(btrim(p_track_key));
  if key is null or key = '' or btrim(p_track_name) = '' or btrim(p_slug) = '' or p_parser_version is null then
    raise exception using errcode = '22023', message = 'invalid_claim_contract';
  end if;
  select * into r from board_pulse.prc_releases where canonical_article_url = board_pulse.canonicalize_prc_url(p_release_url) for update;
  if not found then raise exception using errcode = 'P0001', message = 'release_not_found'; end if;
  select source_version_hash into batch_hash from board_pulse.release_batches b
  where b.id = p_batch_id and b.release_id = r.id for update;
  if not found or batch_hash is distinct from r.source_version_hash then raise exception using errcode = 'P0001', message = 'batch_release_mismatch'; end if;
  select * into s from board_pulse.exam_ingestion_states
  where release_id = r.id and track_key = key and parser_version = p_parser_version for update;
  if not found or not s.is_expected or r.latest_parser_version <> p_parser_version or s.expected_source_hash is distinct from batch_hash then
    raise exception using errcode = 'P0001', message = 'track_not_currently_expected';
  end if;
  slug_value := lower(btrim(p_slug));
  while exists (select 1 from board_pulse.exams x where x.slug = slug_value and not (x.release_id = r.id and x.track_key = key)) loop
    slug_suffix := slug_suffix + 1;
    slug_value := lower(btrim(p_slug)) || '-' || substr(md5(r.id::text || ':' || key), 1, 8) || case when slug_suffix = 1 then '' else '-' || slug_suffix::text end;
  end loop;
  insert into board_pulse.exams(release_id, name, slug, category, scheduled_date, source_article_url, track_key, track_name, track_status, validation_status, is_searchable)
  values(r.id, btrim(p_track_name), slug_value, btrim(p_track_name), coalesce(p_scheduled_date, r.scheduled_date, current_date), r.canonical_article_url, key, btrim(p_track_name), 'pending', 'validating', false)
  on conflict on constraint exams_track_identity_key do update set name = excluded.name, track_name = excluded.track_name
  returning * into e;
  if s.exam_id is not null and s.exam_id <> e.id then raise exception using errcode = '23514', message = 'track_exam_mismatch'; end if;
  update board_pulse.exam_ingestion_states i3 set exam_id = e.id where i3.release_id = r.id and i3.track_key = key and i3.parser_version = p_parser_version;
  if s.state = 'published' and s.expected_source_hash = batch_hash then
    return query select r.id as release_id, e.id as exam_id, p_batch_id as batch_id, 'already_published', null::uuid as lease_owner, s.lease_fencing_token as lease_fencing_token; return;
  end if;
  if s.state = 'processing' and s.lease_until > now() then
    return query select r.id as release_id, e.id as exam_id, p_batch_id as batch_id, 'already_processing', s.lease_owner as lease_owner, s.lease_fencing_token as lease_fencing_token; return;
  end if;
  owner_id := extensions.gen_random_uuid();
  update board_pulse.exam_ingestion_states i4 set state = 'processing', attempt_count = i4.attempt_count + 1, lease_owner = owner_id,
    lease_fencing_token = i4.lease_fencing_token + 1, lease_until = now() + interval '15 minutes', last_error = null, updated_at = now()
  where i4.release_id = r.id and i4.track_key = key and i4.parser_version = p_parser_version
  returning * into s;
  update board_pulse.exams set track_status = 'processing', validation_status = 'validating' where id = e.id;
  return query select r.id as release_id, e.id as exam_id, p_batch_id as batch_id, 'claimed', owner_id as lease_owner, s.lease_fencing_token as lease_fencing_token;
end;
$$;

create or replace function board_pulse.publish_exam_track(
  p_exam_id uuid, p_parser_version text, p_source_version_hash text, p_batch_id uuid, p_lease_owner uuid, p_lease_fencing_token bigint, p_validated_payload_json jsonb
)
returns table(exam_id uuid, release_id uuid, published boolean, outbox_id uuid, error_code text)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare e board_pulse.exams%rowtype; s board_pulse.exam_ingestion_states%rowtype; b board_pulse.release_batches%rowtype; payload jsonb := coalesce(p_validated_payload_json, '{}'::jsonb); outbox_row board_pulse.release_outbox%rowtype; event_key text;
begin
  select * into e from board_pulse.exams where id = p_exam_id for update;
  if not found then return query select p_exam_id, null::uuid, false, null::uuid, 'exam_not_found'; return; end if;
  select * into b from board_pulse.release_batches where id = p_batch_id and release_id = e.release_id for update;
  if not found or b.source_version_hash is distinct from p_source_version_hash
     or b.source_version_hash is distinct from (select source_version_hash from board_pulse.prc_releases where id = e.release_id) then
    return query select e.id, e.release_id, false, null::uuid, 'batch_release_mismatch'; return;
  end if;
  select * into s from board_pulse.exam_ingestion_states i where i.exam_id = e.id and i.parser_version = p_parser_version for update;
  if not found or not s.is_expected or s.state <> 'processing' or s.lease_owner <> p_lease_owner or s.lease_fencing_token <> p_lease_fencing_token or s.lease_until <= now() then
    return query select e.id, e.release_id, false, null::uuid, 'stale_lease'; return;
  end if;
  if p_source_version_hash is null or p_source_version_hash !~ '^[0-9a-f]{64}$' or payload->>'schema_version' is distinct from '1'
     or payload->>'exam_id' is distinct from e.id::text or payload->>'release_id' is distinct from e.release_id::text
     or payload->>'track_key' is distinct from e.track_key or payload->>'source_version_hash' is distinct from p_source_version_hash
     or coalesce(jsonb_typeof(payload->'documents') <> 'array', true) or coalesce(jsonb_array_length(payload->'documents'), 0) = 0
     or exists (select 1 from jsonb_array_elements(payload->'documents') d where jsonb_typeof(d) <> 'object' or coalesce(btrim(d->>'document_type'), '') = '' or coalesce(btrim(d->>'canonical_url'), '') = '' or d->>'release_id' is distinct from e.release_id::text or d->>'version_hash' is null or d->>'version_hash' !~ '^[0-9a-f]{64}$')
     or exists (select 1 from board_pulse.prc_release_documents d where d.release_id = e.release_id and not exists (select 1 from jsonb_array_elements(payload->'documents') p where p->>'document_type' = d.document_type and p->>'canonical_url' = d.canonical_url))
     or coalesce(jsonb_typeof(payload->'results') <> 'array', true) or coalesce(jsonb_typeof(payload->'top_notchers') <> 'array', true)
     or coalesce((payload->'validation'->>'extraction_complete')::boolean, false) is not true
     or coalesce((payload->'validation'->>'duplicate_count')::integer, 1) <> 0
     or ((payload->'validation'->>'count_status') <> 'unavailable' and coalesce((payload->'validation'->>'parsed_count')::integer, -1) <> coalesce((payload->'validation'->>'expected_count')::integer, -2))
     or exists (select 1 from jsonb_to_recordset(payload->'results') x(full_name text, school text, rating numeric, remarks text, rank integer) where btrim(coalesce(x.full_name, '')) = '' or x.rank is not null and x.rank < 1)
     or exists (select 1 from (select lower(btrim(x.full_name)) as full_name from jsonb_to_recordset(payload->'results') x(full_name text, school text, rating numeric, remarks text, rank integer) group by lower(btrim(x.full_name)) having count(*) > 1) duplicates)
     or exists (select 1 from jsonb_to_recordset(payload->'top_notchers') x(rank integer, full_name text, school text, rating numeric) where x.rank is null or x.rank < 1 or btrim(coalesce(x.full_name, '')) = '')
     or exists (select 1 from (select x.rank from jsonb_to_recordset(payload->'top_notchers') x(rank integer, full_name text, school text, rating numeric) group by x.rank having count(*) > 1) duplicates)
     or exists (select 1 from jsonb_to_recordset(payload->'top_notchers') tn(rank integer, full_name text, school text, rating numeric) where not exists (select 1 from jsonb_to_recordset(payload->'results') rr(full_name text, school text, rating numeric, remarks text, rank integer) where lower(btrim(rr.full_name)) = lower(btrim(tn.full_name)) and rr.rating is not distinct from tn.rating))
     or exists (select 1 from board_pulse.prc_release_documents d where d.release_id = e.release_id and d.document_type = 'performance')
        and not (
          payload->'validation'->>'performance_status' = 'unavailable'
          or (payload->'validation'->>'performance_status' = 'validated'
              and coalesce(jsonb_typeof(payload->'performance') <> 'array', true) is not true
              and coalesce((payload->'validation'->>'performance_reconciled')::boolean, false) is true)
        ) then
    update board_pulse.exam_ingestion_states i2 set state = 'failed', lease_owner = null, lease_until = null, last_error = 'validation_failed', updated_at = now() where i2.release_id = s.release_id and i2.track_key = s.track_key and i2.parser_version = s.parser_version;
    update board_pulse.exams set track_status = 'failed', validation_status = 'failed' where id = e.id;
    return query select e.id, e.release_id, false, null::uuid, 'validation_failed'; return;
  end if;
  insert into board_pulse.prc_release_documents(
    release_id, exam_id, document_type, label, canonical_url, association_confidence,
    top_rank_limit, version_hash, parse_status, committed_object_key, promotion_status, promoted_at
  )
  select e.release_id,
    case when d->>'document_type' in ('passers', 'topnotchers') then e.id else null end,
    d->>'document_type', coalesce(d->>'label', d->>'document_type'), d->>'canonical_url', 'high',
    nullif(d->>'top_rank_limit', '')::integer, d->>'version_hash', 'parsed', d->>'committed_object_key',
    case when coalesce(d->>'committed_object_key', '') <> '' then 'promoted' else 'staged' end,
    case when coalesce(d->>'committed_object_key', '') <> '' then now() else null end
  from jsonb_array_elements(payload->'documents') d
  on conflict (release_id, document_type, canonical_url) do update set
    exam_id = excluded.exam_id, label = excluded.label, version_hash = excluded.version_hash,
    parse_status = excluded.parse_status, committed_object_key = excluded.committed_object_key,
    promotion_status = excluded.promotion_status, promoted_at = excluded.promoted_at,
    updated_at = now();
  delete from board_pulse.results as result_row where result_row.exam_id = e.id;
  insert into board_pulse.results(exam_id, full_name, school, rating, remarks, rank)
  select e.id, btrim(x.full_name), btrim(coalesce(x.school, '')), x.rating, btrim(x.remarks), x.rank
  from jsonb_to_recordset(coalesce(payload->'results', '[]'::jsonb)) x(full_name text, school text, rating numeric, remarks text, rank integer);
  delete from board_pulse.top_notchers t2 where t2.exam_id = e.id;
  insert into board_pulse.top_notchers(exam_id, rank, full_name, school, rating)
  select e.id, x.rank, btrim(x.full_name), btrim(coalesce(x.school, '')), x.rating
  from jsonb_to_recordset(coalesce(payload->'top_notchers', '[]'::jsonb)) x(rank integer, full_name text, school text, rating numeric);
  delete from board_pulse.school_performance sp where sp.exam_id = e.id;
  insert into board_pulse.school_performance(
    exam_id, school_name, examined_count, passed_count, passing_percentage, rank, qualification_text, source_row_text,
    first_timers_passed_count, first_timers_failed_count, first_timers_conditioned_count, first_timers_total_count,
    first_timers_passing_percentage, repeaters_passed_count, repeaters_failed_count, repeaters_conditioned_count,
    repeaters_total_count, repeaters_passing_percentage, overall_failed_count, overall_conditioned_count
  )
  select e.id, btrim(x.school_name), x.examined_count, x.passed_count, x.passing_percentage, x.rank,
         x.qualification_text, btrim(x.source_row_text), x.first_timers_passed_count, x.first_timers_failed_count,
         x.first_timers_conditioned_count, x.first_timers_total_count, x.first_timers_passing_percentage,
         x.repeaters_passed_count, x.repeaters_failed_count, x.repeaters_conditioned_count, x.repeaters_total_count,
         x.repeaters_passing_percentage, x.overall_failed_count, x.overall_conditioned_count
  from jsonb_to_recordset(coalesce(payload->'performance', '[]'::jsonb)) x(
    school_name text, examined_count integer, passed_count integer, passing_percentage numeric,
    rank integer, qualification_text text, source_row_text text,
    first_timers_passed_count integer, first_timers_failed_count integer, first_timers_conditioned_count integer,
    first_timers_total_count integer, first_timers_passing_percentage numeric, repeaters_passed_count integer,
    repeaters_failed_count integer, repeaters_conditioned_count integer, repeaters_total_count integer,
    repeaters_passing_percentage numeric, overall_failed_count integer, overall_conditioned_count integer
  )
  where btrim(coalesce(x.school_name, '')) <> '' and btrim(coalesce(x.source_row_text, '')) <> '';
  insert into board_pulse.release_artifacts(release_id, exam_id, artifact_kind, staging_object_key, committed_object_key)
  select e.release_id, e.id, x.kind, x.staging_object_key, x.committed_object_key
  from jsonb_to_recordset(coalesce(payload->'artifacts', '[]'::jsonb)) x(kind text, staging_object_key text, committed_object_key text)
  where btrim(coalesce(x.kind, '')) <> '' and btrim(coalesce(x.staging_object_key, '')) <> ''
    and btrim(coalesce(x.committed_object_key, '')) <> ''
  on conflict (exam_id, artifact_kind, committed_object_key) do update set staging_object_key = excluded.staging_object_key;
  update board_pulse.exams set track_status = 'published', validation_status = 'validated', is_searchable = true, results_released_at = coalesce(results_released_at, now()),
    passers_pdf_url = coalesce((select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'passers' limit 1), passers_pdf_url),
    top_notchers_pdf_url = coalesce((select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'topnotchers' limit 1), top_notchers_pdf_url),
    performance_of_schools_pdf_url = coalesce((select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'performance' limit 1), performance_of_schools_pdf_url),
    updated_at = now()
  where id = e.id;
  update board_pulse.exam_ingestion_states set state = 'published', expected_source_hash = p_source_version_hash, lease_owner = null, lease_until = null, updated_at = now()
  where release_id = e.release_id and track_key = e.track_key and parser_version = p_parser_version;
  event_key := e.id::text || ':exam_results_released:' || p_source_version_hash;
  insert into board_pulse.release_outbox(batch_id, release_id, exam_id, event_key, event_type, source_version_hash, payload)
  values(p_batch_id, e.release_id, e.id, event_key, 'exam_results_released', p_source_version_hash, jsonb_build_object(
    'exam_id', e.id, 'release_id', e.release_id, 'track_key', e.track_key,
    'exam_name', e.name, 'exam_slug', e.slug,
    'passers_count', (select count(*) from board_pulse.results where exam_id = e.id),
    'top_notchers_count', (select count(*) from board_pulse.top_notchers where exam_id = e.id),
    'passers_pdf_url', (select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'passers' limit 1),
    'top_notchers_pdf_url', (select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'topnotchers' limit 1),
    'performance_of_schools_pdf_url', (select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'performance' limit 1)
  ))
  on conflict(event_key) do update set updated_at = now()
  returning * into outbox_row;
  update board_pulse.release_batches b set terminal_track_count = (select count(*) from board_pulse.exam_ingestion_states i join board_pulse.prc_releases r on r.id = i.release_id where i.release_id = e.release_id and i.parser_version = r.latest_parser_version and i.is_expected and i.state in ('published', 'unavailable')),
    search_refresh_status = case when (select count(*) from board_pulse.exam_ingestion_states i join board_pulse.prc_releases r on r.id = i.release_id where i.release_id = e.release_id and i.parser_version = r.latest_parser_version and i.is_expected and i.state not in ('published', 'unavailable')) = 0 then 'pending' else 'open' end,
    updated_at = now() where b.id = p_batch_id;
  update board_pulse.prc_releases r2
  set status = case
    when (select terminal_track_count from board_pulse.release_batches where id = p_batch_id)
      >= (select expected_track_count from board_pulse.release_batches where id = p_batch_id) then 'published'
    when (select terminal_track_count from board_pulse.release_batches where id = p_batch_id) > 0 then 'partial'
    else r2.status
  end, updated_at = now()
  where r2.id = e.release_id;
  return query select e.id, e.release_id, true, outbox_row.id, null::text;
exception when others then
  raise;
end;
$$;

create or replace function board_pulse.fail_exam_track(
  p_exam_id uuid, p_parser_version text, p_lease_owner uuid,
  p_lease_fencing_token bigint, p_error text
)
returns boolean
language plpgsql security definer set search_path = board_pulse, pg_catalog
as $$
declare changed integer;
begin
  update board_pulse.exam_ingestion_states
  set state = 'failed', lease_owner = null, lease_until = null,
      last_error = left(coalesce(p_error, 'track_failed'), 2000), updated_at = now()
  where exam_id = p_exam_id and parser_version = p_parser_version
    and state = 'processing' and lease_owner = p_lease_owner
    and lease_fencing_token = p_lease_fencing_token;
  get diagnostics changed = row_count;
  if changed = 1 then
    update board_pulse.exams set track_status = 'failed', validation_status = 'failed', updated_at = now()
    where id = p_exam_id;
  end if;
  return changed = 1;
end;
$$;

revoke all on function board_pulse.upsert_prc_release(text, text, date, text, text, uuid) from public, anon, authenticated;
revoke all on function board_pulse.sync_expected_tracks(uuid, text, uuid, text, jsonb) from public, anon, authenticated;
revoke all on function board_pulse.claim_exam_track(text, text, text, text, date, text, uuid) from public, anon, authenticated;
revoke all on function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb) from public, anon, authenticated;
revoke all on function board_pulse.claim_release_outbox(uuid, integer, integer) from public, anon, authenticated;
revoke all on function board_pulse.fail_exam_track(uuid, text, uuid, bigint, text) from public, anon, authenticated;
grant execute on function board_pulse.upsert_prc_release(text, text, date, text, text, uuid) to service_role;
grant execute on function board_pulse.sync_expected_tracks(uuid, text, uuid, text, jsonb) to service_role;
grant execute on function board_pulse.claim_exam_track(text, text, text, text, date, text, uuid) to service_role;
grant execute on function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb) to service_role;
grant execute on function board_pulse.claim_release_outbox(uuid, integer, integer) to service_role;
grant execute on function board_pulse.fail_exam_track(uuid, text, uuid, bigint, text) to service_role;

notify pgrst, 'reload schema';
