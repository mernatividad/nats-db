-- Official PRC release dates are date-only facts.  results_released_at remains
-- the operational publication timestamp and is deliberately not repurposed.

do $$
begin
  if not exists (
    select 1 from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'board_pulse' and t.relname = 'exams'
      and c.conname = 'exams_id_release_key'
      and c.contype = 'u'
      and pg_get_constraintdef(c.oid) = 'UNIQUE (id, release_id)'
  ) then
    raise exception 'required constraint exams_id_release_key on exams(id, release_id) is absent or changed';
  end if;
end
$$;

alter table board_pulse.exams
  add column if not exists official_release_date date,
  add column if not exists official_release_date_source_url text,
  add column if not exists official_release_date_source_hash text,
  add column if not exists official_release_date_sources jsonb,
  add column if not exists official_release_date_conflict_reason text,
  add column if not exists official_release_date_parser_version text;

alter table board_pulse.prc_releases
  add column if not exists official_release_date date,
  add column if not exists official_release_date_source_url text,
  add column if not exists official_release_date_source_hash text,
  add column if not exists official_release_date_sources jsonb,
  add column if not exists official_release_date_conflict_reason text,
  add column if not exists official_release_date_parser_version text;

alter table board_pulse.exams
  drop constraint if exists exams_official_release_date_hash_check,
  add constraint exams_official_release_date_hash_check check (
    official_release_date_source_hash is null
    or official_release_date_source_hash ~ '^[0-9a-f]{64}$'
  );
alter table board_pulse.prc_releases
  drop constraint if exists prc_releases_official_release_date_hash_check,
  add constraint prc_releases_official_release_date_hash_check check (
    official_release_date_source_hash is null
    or official_release_date_source_hash ~ '^[0-9a-f]{64}$'
  );

create table if not exists board_pulse.official_release_date_audit (
  id uuid primary key default extensions.gen_random_uuid(),
  run_id uuid not null,
  operator text not null,
  exam_id uuid,
  release_id uuid not null references board_pulse.prc_releases(id) on delete restrict,
  action text not null check (action in ('set', 'preserve', 'conflict', 'skip')),
  old_date date,
  new_date date,
  source_hash text,
  reason text,
  idempotency_key text not null unique,
  created_at timestamptz not null default now(),
  constraint official_release_date_audit_exam_release_fk
    foreign key (exam_id, release_id) references board_pulse.exams(id, release_id),
  constraint official_release_date_audit_hash_check
    check (source_hash is null or source_hash ~ '^[0-9a-f]{64}$')
);
alter table board_pulse.official_release_date_audit enable row level security;
revoke all on board_pulse.official_release_date_audit from public, anon, authenticated;
grant select, insert, update on board_pulse.official_release_date_audit to service_role;

create or replace function board_pulse._lock_release_graph(p_release_id uuid)
returns void
language plpgsql security definer set search_path = board_pulse, pg_catalog
as $$
declare ignored record;
begin
  perform 1 from board_pulse.prc_releases where id = p_release_id for update;
  if not found then raise exception using errcode = 'P0001', message = 'release_not_found'; end if;
  for ignored in select id from board_pulse.release_batches where release_id = p_release_id order by id loop
    perform 1 from board_pulse.release_batches where id = ignored.id for update;
  end loop;
  for ignored in
    select release_id, track_key, parser_version
    from board_pulse.exam_ingestion_states
    where release_id = p_release_id
    order by track_key, parser_version
  loop
    perform 1 from board_pulse.exam_ingestion_states
      where release_id = ignored.release_id and track_key = ignored.track_key and parser_version = ignored.parser_version
      for update;
  end loop;
  for ignored in select id from board_pulse.exams where release_id = p_release_id order by id loop
    perform 1 from board_pulse.exams where id = ignored.id for update;
  end loop;
end;
$$;

create or replace function board_pulse._validate_official_release_provenance(
  p_official_release_date date, p_source_url text, p_source_hash text,
  p_sources jsonb, p_conflict_reason text
)
returns void
language plpgsql immutable
set search_path = board_pulse, pg_catalog
as $$
declare item jsonb; primary_count integer := 0; canonical_url text; seen_urls text[] := '{}';
begin
  if p_source_hash is not null and p_source_hash !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'invalid_official_release_source_hash';
  end if;
  if jsonb_typeof(coalesce(p_sources, '[]'::jsonb)) <> 'array' then
    raise exception using errcode = '22023', message = 'invalid_official_release_sources';
  end if;
  for item in select value from jsonb_array_elements(coalesce(p_sources, '[]'::jsonb)) loop
    if jsonb_typeof(item) <> 'object'
       or item->>'role' not in ('primary', 'corroborating')
       or board_pulse.canonicalize_prc_url(item->>'url') is null
       or item->>'hash' !~ '^[0-9a-f]{64}$'
       or (item ? 'extracted_date' and item->>'extracted_date' is not null
           and item->>'extracted_date' !~ '^\d{4}-\d{2}-\d{2}$') then
      raise exception using errcode = '22023', message = 'malformed_official_release_source';
    end if;
    canonical_url := board_pulse.canonicalize_prc_url(item->>'url');
    if canonical_url = any(seen_urls) then
      raise exception using errcode = '22023', message = 'duplicate_official_release_source';
    end if;
    seen_urls := array_append(seen_urls, canonical_url);
    if item->>'role' = 'primary' then primary_count := primary_count + 1; end if;
    if item->>'extracted_date' is not null and p_official_release_date is not null
       and (item->>'extracted_date')::date <> p_official_release_date then
      raise exception using errcode = '22023', message = 'official_release_source_date_mismatch';
    end if;
  end loop;
  if p_official_release_date is not null then
    if primary_count <> 1 or p_source_url is null or p_source_hash is null
       or not exists (
         select 1 from jsonb_array_elements(p_sources) x
         where x->>'role' = 'primary'
           and board_pulse.canonicalize_prc_url(x->>'url') = board_pulse.canonicalize_prc_url(p_source_url)
           and x->>'hash' = p_source_hash
       ) then
      raise exception using errcode = '22023', message = 'incomplete_official_release_provenance';
    end if;
  elsif p_conflict_reason is not null and btrim(p_conflict_reason) = '' then
    raise exception using errcode = '22023', message = 'empty_official_release_conflict_reason';
  end if;
end;
$$;

create or replace function board_pulse.set_prc_release_official_date(
  p_release_id uuid, p_official_release_date date, p_source_url text, p_source_hash text,
  p_sources jsonb, p_parser_version text, p_conflict_reason text, p_run_id uuid,
  p_operator text, p_idempotency_key text
)
returns table(release_id uuid, official_release_date date, updated_exam_count integer, conflict_reason text)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare r board_pulse.prc_releases%rowtype; e record; old_date date; action_value text; changed integer := 0;
begin
  if p_run_id is null or p_operator is null or p_idempotency_key is null then
    raise exception using errcode = '22023', message = 'invalid_official_release_audit_contract';
  end if;
  perform board_pulse._validate_official_release_provenance(p_official_release_date, p_source_url, p_source_hash, p_sources, p_conflict_reason);
  perform board_pulse._lock_release_graph(p_release_id);
  select * into r from board_pulse.prc_releases where id = p_release_id;
  if r.official_release_date is not null and p_official_release_date is not null
     and r.official_release_date <> p_official_release_date then
    insert into board_pulse.official_release_date_audit(run_id, operator, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, p_release_id, 'conflict', r.official_release_date, p_official_release_date, p_source_hash, coalesce(p_conflict_reason, 'conflicting official release date'), p_idempotency_key)
    on conflict (idempotency_key) do nothing;
    return query select r.id, r.official_release_date, 0, coalesce(p_conflict_reason, 'conflicting official release date'); return;
  end if;
  if p_official_release_date is not null and r.official_release_date is null then
    update board_pulse.prc_releases set official_release_date = p_official_release_date,
      official_release_date_source_url = p_source_url, official_release_date_source_hash = p_source_hash,
      official_release_date_sources = p_sources, official_release_date_parser_version = p_parser_version,
      official_release_date_conflict_reason = p_conflict_reason, updated_at = now()
    where id = p_release_id;
  end if;
  for e in select * from board_pulse.exams where release_id = p_release_id order by id loop
    old_date := e.official_release_date;
    if old_date is null and p_official_release_date is not null then
      update board_pulse.exams set official_release_date = p_official_release_date,
        official_release_date_source_url = p_source_url, official_release_date_source_hash = p_source_hash,
        official_release_date_sources = p_sources, official_release_date_parser_version = p_parser_version,
        official_release_date_conflict_reason = p_conflict_reason, updated_at = now() where id = e.id;
      action_value := 'set'; changed := changed + 1;
    elsif old_date is not null and p_official_release_date is not null and old_date <> p_official_release_date then
      action_value := 'conflict';
    else action_value := 'preserve';
    end if;
    insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, e.id, p_release_id, action_value, old_date, p_official_release_date, p_source_hash, p_conflict_reason, p_idempotency_key || ':' || e.id)
    on conflict (idempotency_key) do nothing;
  end loop;
  if changed = 0 and not exists (select 1 from board_pulse.exams where release_id = p_release_id) then
    insert into board_pulse.official_release_date_audit(run_id, operator, release_id, action, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, p_release_id, case when p_conflict_reason is null then 'skip' else 'conflict' end, p_official_release_date, p_source_hash, p_conflict_reason, p_idempotency_key)
    on conflict (idempotency_key) do nothing;
  end if;
  select * into r from board_pulse.prc_releases where id = p_release_id;
  return query select r.id, r.official_release_date, changed, p_conflict_reason;
end;
$$;

revoke all on function board_pulse.set_prc_release_official_date(uuid, date, text, text, jsonb, text, text, uuid, text, text) from public, anon, authenticated;
grant execute on function board_pulse.set_prc_release_official_date(uuid, date, text, text, jsonb, text, text, uuid, text, text) to service_role;

create or replace function board_pulse.resolve_or_create_prc_exam(
  p_canonical_article_url text, p_title text, p_slug text, p_scheduled_date date,
  p_track_key text, p_track_name text, p_parser_version text, p_source_version_hash text
)
returns table(exam_id uuid, release_id uuid)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare r board_pulse.prc_releases%rowtype; e board_pulse.exams%rowtype; canonical_url text;
begin
  canonical_url := board_pulse.canonicalize_prc_url(p_canonical_article_url);
  if canonical_url is null or btrim(p_title) = '' or btrim(p_slug) = '' or btrim(p_track_key) = '' or btrim(p_track_name) = ''
     or p_parser_version is null or p_source_version_hash !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'invalid_prc_exam_identity';
  end if;
  insert into board_pulse.prc_releases(canonical_article_url, title, scheduled_date, latest_parser_version, source_version_hash)
  values(canonical_url, btrim(p_title), p_scheduled_date, btrim(p_parser_version), p_source_version_hash)
  on conflict (canonical_article_url) do nothing;
  select * into r from board_pulse.prc_releases where canonical_article_url = canonical_url for update;
  if r.latest_parser_version is distinct from btrim(p_parser_version) or r.source_version_hash is distinct from p_source_version_hash then
    raise exception using errcode = 'P0001', message = 'prc_release_provenance_conflict';
  end if;
  insert into board_pulse.release_batches(release_id, source_version_hash)
  values(r.id, p_source_version_hash)
  on conflict (release_id, source_version_hash) do update set updated_at = now();
  if exists (select 1 from board_pulse.exams where source_article_url = canonical_url and release_id is null) then
    raise exception using errcode = '23514', message = 'parentless_exam_rejected';
  end if;
  insert into board_pulse.exams(release_id, name, slug, category, scheduled_date, source_article_url, track_key, track_name, track_status, validation_status, is_searchable)
  values(r.id, btrim(p_track_name), lower(btrim(p_slug)), btrim(p_track_name), coalesce(p_scheduled_date, r.scheduled_date, current_date), canonical_url, lower(btrim(p_track_key)), btrim(p_track_name), 'pending', 'unverified', false)
  on conflict (release_id, track_key) do update set name = excluded.name, track_name = excluded.track_name
  returning * into e;
  insert into board_pulse.exam_ingestion_states(release_id, track_key, parser_version, exam_id, expected_source_hash)
  values(r.id, lower(btrim(p_track_key)), btrim(p_parser_version), e.id, p_source_version_hash)
  on conflict (release_id, track_key, parser_version) do update set exam_id = excluded.exam_id;
  return query select e.id, r.id;
end;
$$;
revoke all on function board_pulse.resolve_or_create_prc_exam(text, text, text, date, text, text, text, text) from public, anon, authenticated;
grant execute on function board_pulse.resolve_or_create_prc_exam(text, text, text, date, text, text, text, text) to service_role;

create or replace function board_pulse.publish_legacy_exam(
  p_exam_id uuid, p_validation_status text, p_official_release_date date, p_source_url text,
  p_source_hash text, p_sources jsonb, p_parser_version text, p_conflict_reason text,
  p_run_id uuid, p_operator text, p_idempotency_key text
)
returns table(exam_id uuid, release_id uuid, published boolean, official_release_date date)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare e board_pulse.exams%rowtype; r board_pulse.prc_releases%rowtype; effective_date date;
begin
  perform board_pulse._validate_official_release_provenance(p_official_release_date, p_source_url, p_source_hash, p_sources, p_conflict_reason);
  select * into e from board_pulse.exams where id = p_exam_id;
  if not found or e.release_id is null then return query select p_exam_id, null::uuid, false, null::date; return; end if;
  perform board_pulse._lock_release_graph(e.release_id);
  select * into e from board_pulse.exams where id = p_exam_id for update;
  select * into r from board_pulse.prc_releases where id = e.release_id;
  if e.official_release_date is not null and p_official_release_date is not null and e.official_release_date <> p_official_release_date then
    insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, e.id, e.release_id, 'conflict', e.official_release_date, p_official_release_date, p_source_hash, coalesce(p_conflict_reason, 'conflicting official release date'), p_idempotency_key)
    on conflict (idempotency_key) do nothing;
    effective_date := e.official_release_date;
  else
    effective_date := coalesce(e.official_release_date, p_official_release_date, r.official_release_date);
    update board_pulse.exams set track_status = 'published', validation_status = coalesce(p_validation_status, 'validated'), is_searchable = true,
      results_released_at = coalesce(results_released_at, now()), official_release_date = effective_date,
      official_release_date_source_url = coalesce(official_release_date_source_url, p_source_url),
      official_release_date_source_hash = coalesce(official_release_date_source_hash, p_source_hash),
      official_release_date_sources = coalesce(official_release_date_sources, p_sources),
      official_release_date_parser_version = coalesce(official_release_date_parser_version, p_parser_version),
      official_release_date_conflict_reason = p_conflict_reason, updated_at = now() where id = e.id;
    update board_pulse.prc_releases set official_release_date = coalesce(official_release_date, effective_date),
      official_release_date_source_url = coalesce(official_release_date_source_url, p_source_url),
      official_release_date_source_hash = coalesce(official_release_date_source_hash, p_source_hash),
      official_release_date_sources = coalesce(official_release_date_sources, p_sources),
      official_release_date_parser_version = coalesce(official_release_date_parser_version, p_parser_version), updated_at = now()
    where id = e.release_id;
    insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, e.id, e.release_id, case when e.official_release_date is null and effective_date is not null then 'set' else 'preserve' end, e.official_release_date, effective_date, p_source_hash, p_conflict_reason, p_idempotency_key)
    on conflict (idempotency_key) do nothing;
    insert into board_pulse.notification_events(exam_id, event_type, event_key, payload)
    values(e.id, 'exam_results_released', p_idempotency_key, jsonb_build_object('exam_id', e.id, 'release_id', e.release_id, 'official_release_date', effective_date))
    on conflict (event_key) do nothing;
  end if;
  return query select e.id, e.release_id, true, effective_date;
end;
$$;
revoke all on function board_pulse.publish_legacy_exam(uuid, text, date, text, text, jsonb, text, text, uuid, text, text) from public, anon, authenticated;
grant execute on function board_pulse.publish_legacy_exam(uuid, text, date, text, text, jsonb, text, text, uuid, text, text) to service_role;

-- Keep the fixed RPC signature and all existing result/publication validation,
-- but acquire the canonical parent locks and apply the optional date contract
-- before that implementation can delete/rewrite result rows.
alter function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb)
  rename to _publish_exam_track_legacy;
revoke all on function board_pulse._publish_exam_track_legacy(uuid, text, text, uuid, uuid, bigint, jsonb) from public, anon, authenticated;

create or replace function board_pulse.publish_exam_track(
  p_exam_id uuid, p_parser_version text, p_source_version_hash text, p_batch_id uuid,
  p_lease_owner uuid, p_lease_fencing_token bigint, p_validated_payload_json jsonb
)
returns table(exam_id uuid, release_id uuid, published boolean, outbox_id uuid, error_code text)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare e board_pulse.exams%rowtype; payload jsonb := coalesce(p_validated_payload_json, '{}'::jsonb);
  proposed_date date; legacy_result record; event_key_value text; audit_run uuid := coalesce(p_lease_owner, extensions.gen_random_uuid());
begin
  select * into e from board_pulse.exams where id = p_exam_id;
  if not found then return query select p_exam_id, null::uuid, false, null::uuid, 'exam_not_found'; return; end if;
  perform board_pulse._lock_release_graph(e.release_id);
  if payload ? 'official_release_date' and payload->>'official_release_date' is not null then
    proposed_date := (payload->>'official_release_date')::date;
    perform board_pulse._validate_official_release_provenance(
      proposed_date, payload->>'official_release_date_source_url', payload->>'official_release_date_source_hash',
      payload->'official_release_date_sources', payload->>'official_release_date_conflict_reason'
    );
    if e.official_release_date is not null and e.official_release_date <> proposed_date then
      raise exception using errcode = 'P0001', message = 'official_release_date_conflict';
    end if;
  end if;
  select * into legacy_result from board_pulse._publish_exam_track_legacy(
    p_exam_id, p_parser_version, p_source_version_hash, p_batch_id, p_lease_owner,
    p_lease_fencing_token, p_validated_payload_json
  );
  if legacy_result.published then
    if payload ? 'official_release_date' then
      select * into e from board_pulse.exams where id = p_exam_id;
      perform board_pulse.set_prc_release_official_date(
        e.release_id, proposed_date, payload->>'official_release_date_source_url',
        payload->>'official_release_date_source_hash', payload->'official_release_date_sources',
        payload->>'official_release_date_parser_version', payload->>'official_release_date_conflict_reason',
        audit_run, 'publish_exam_track', e.id::text || ':' || p_source_version_hash
      );
      event_key_value := e.id::text || ':exam_results_released:' || p_source_version_hash;
      update board_pulse.release_outbox ro set payload = ro.payload || jsonb_build_object('official_release_date', proposed_date)
      where ro.event_key = event_key_value;
    end if;
  end if;
  return query select legacy_result.exam_id, legacy_result.release_id, legacy_result.published, legacy_result.outbox_id, legacy_result.error_code;
end;
$$;
revoke all on function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb) from public, anon, authenticated;
grant execute on function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb) to service_role;

create or replace function board_pulse.backfill_official_release_date(
  p_exam_id uuid, p_release_id uuid, p_official_release_date date, p_provenance jsonb,
  p_source_hash text, p_run_id uuid, p_operator text, p_reason text, p_idempotency_key text
)
returns table(exam_id uuid, release_id uuid, updated_release_count integer, updated_exam_count integer, audit_id uuid)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare e board_pulse.exams%rowtype; r board_pulse.prc_releases%rowtype; a uuid; n integer;
begin
  perform board_pulse._validate_official_release_provenance(p_official_release_date, p_provenance->'primary'->>'url', p_source_hash, p_provenance->'sources', p_reason);
  perform board_pulse._lock_release_graph(p_release_id);
  select * into r from board_pulse.prc_releases where id = p_release_id;
  select * into e from board_pulse.exams where id = p_exam_id and release_id = p_release_id;
  if not found then raise exception using errcode = '23514', message = 'backfill_parent_identity_mismatch'; end if;
  update board_pulse.prc_releases set official_release_date = p_official_release_date, official_release_date_source_hash = p_source_hash,
    official_release_date_sources = p_provenance->'sources', updated_at = now() where id = p_release_id;
  get diagnostics n = row_count;
  update board_pulse.exams set official_release_date = p_official_release_date, official_release_date_source_hash = p_source_hash,
    official_release_date_sources = p_provenance->'sources', updated_at = now() where id = p_exam_id and release_id = p_release_id;
  insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
  values(p_run_id, p_operator, p_exam_id, p_release_id, 'set', e.official_release_date, p_official_release_date, p_source_hash, p_reason, p_idempotency_key)
  on conflict (idempotency_key) do update set id = board_pulse.official_release_date_audit.id
  returning id into a;
  return query select p_exam_id, p_release_id, n, 1, a;
end;
$$;
revoke all on function board_pulse.backfill_official_release_date(uuid, uuid, date, jsonb, text, uuid, text, text, text) from public, anon, authenticated;
grant execute on function board_pulse.backfill_official_release_date(uuid, uuid, date, jsonb, text, uuid, text, text, text) to service_role;

create or replace function board_pulse.audit_notification_release_date_conflict(
  p_exam_id uuid, p_event_id uuid, p_canonical_date date, p_legacy_date date, p_reason text
)
returns uuid
language plpgsql security definer set search_path = board_pulse, pg_catalog
as $$
declare rid uuid; aid uuid;
begin
  select release_id into rid from board_pulse.exams where id = p_exam_id;
  if rid is null then raise exception using errcode = '23514', message = 'exam_release_not_found'; end if;
  insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, reason, idempotency_key)
  values(p_event_id, 'notification_adapter', p_exam_id, rid, 'conflict', p_legacy_date, p_canonical_date, p_reason, p_event_id::text)
  on conflict (idempotency_key) do update set reason = excluded.reason
  returning id into aid;
  return aid;
end;
$$;
revoke all on function board_pulse.audit_notification_release_date_conflict(uuid, uuid, date, date, text) from public, anon, authenticated;
grant execute on function board_pulse.audit_notification_release_date_conflict(uuid, uuid, date, date, text) to service_role;

-- Rebuild the search contract because result_release_date changes from timestamptz to date.
drop materialized view if exists board_pulse.passer_search_index;
drop view if exists board_pulse.passer_search_index_refresh_source;
create view board_pulse.passer_search_index_refresh_source with (security_invoker = true) as
with passer_rows as (
  select r.id result_id, r.exam_id, r.full_name, r.school, coalesce(tn.rating, r.rating) rating,
    coalesce(tn.rank, r.rank) rank, r.remarks, tn.id is not null is_topnotcher
  from board_pulse.results r left join board_pulse.top_notchers tn
    on tn.exam_id = r.exam_id and board_pulse.normalize_search_name(tn.full_name) = board_pulse.normalize_search_name(r.full_name)
    and board_pulse.normalize_search_name(tn.school) = board_pulse.normalize_search_name(r.school)
  union all
  select tn.id, tn.exam_id, tn.full_name, tn.school, tn.rating, tn.rank, 'PASSED', true
  from board_pulse.top_notchers tn where not exists (select 1 from board_pulse.results r where r.exam_id = tn.exam_id
    and board_pulse.normalize_search_name(r.full_name) = board_pulse.normalize_search_name(tn.full_name)
    and board_pulse.normalize_search_name(r.school) = board_pulse.normalize_search_name(tn.school))
), prepared as (
  select p.result_id, p.exam_id, e.release_id, nullif(lower(btrim(e.track_key)), '') track_key, e.slug exam_slug,
    e.name exam_name, e.category profession, p.full_name, board_pulse.normalize_search_name(p.full_name) normalized_name,
    board_pulse.normalize_search_name(p.school) normalized_school, p.school,
    case when p.remarks = 'PASSED' then 'passed' else lower(p.remarks) end result_status, p.rank, p.rating,
    e.scheduled_date exam_date, e.official_release_date result_release_date,
    coalesce(e.source_article_url, case when p.is_topnotcher then e.top_notchers_pdf_url else e.passers_pdf_url end) source_url,
    case when p.is_topnotcher then e.top_notchers_pdf_url else e.passers_pdf_url end official_source_url,
    p.is_topnotcher, e.validation_status,
    case when coalesce(e.source_article_url, e.passers_pdf_url, e.top_notchers_pdf_url) is null then 'incomplete' else 'complete' end source_coverage_status,
    1 normalization_version
  from passer_rows p join board_pulse.exams e on e.id = p.exam_id
  where (e.results_released_at is not null or exists (select 1 from board_pulse.results x where x.exam_id = e.id)
    or exists (select 1 from board_pulse.top_notchers x where x.exam_id = e.id))
    and e.validation_status in ('validated', 'verified') and e.is_searchable = true and e.completeness_status = 'complete'
    and (e.track_status is null or e.track_status = 'published') and (e.track_key is null or btrim(e.track_key) <> '')
)
select prepared.*, array_to_string(array(select token from unnest(regexp_split_to_array(prepared.normalized_name, '\s+')) token order by token), ' ') normalized_tokens,
  array_to_string(array(select token from unnest(regexp_split_to_array(prepared.normalized_name, '\s+')) token order by token), ' ') search_document
from prepared;
create materialized view board_pulse.passer_search_index as select * from board_pulse.passer_search_index_refresh_source;
revoke all on board_pulse.passer_search_index_refresh_source from public, anon, authenticated, service_role;
create unique index passer_search_index_result_id_key on board_pulse.passer_search_index (result_id);
create index passer_search_index_identity_idx on board_pulse.passer_search_index (exam_id, release_id, track_key, result_release_date desc nulls last, full_name asc, result_id asc);
create index passer_search_index_search_document_trgm_idx on board_pulse.passer_search_index using gin (search_document gin_trgm_ops);
create index passer_search_index_exam_scope_idx on board_pulse.passer_search_index (exam_slug, is_topnotcher, result_release_date desc nulls last, exam_name asc, result_id asc, exam_id asc);
grant select on board_pulse.passer_search_index to anon, authenticated, service_role;
select board_pulse.refresh_passer_search_index();
notify pgrst, 'reload schema';
