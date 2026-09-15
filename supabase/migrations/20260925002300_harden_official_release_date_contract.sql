-- Forward-only hardening after the initial official-date rollout.
-- The preceding migration is already applied remotely and must remain immutable.

revoke all on function board_pulse._lock_release_graph(uuid) from public, anon, authenticated;

create or replace function board_pulse.fail_exam_track(
  p_exam_id uuid, p_parser_version text, p_lease_owner uuid,
  p_lease_fencing_token bigint, p_error text
)
returns boolean
language plpgsql security definer set search_path = board_pulse, pg_catalog
as $$
declare changed integer; release_key uuid;
begin
  select release_id into release_key from board_pulse.exams where id = p_exam_id;
  if release_key is null then return false; end if;
  perform board_pulse._lock_release_graph(release_key);
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
revoke all on function board_pulse.fail_exam_track(uuid, text, uuid, bigint, text) from public, anon, authenticated;
grant execute on function board_pulse.fail_exam_track(uuid, text, uuid, bigint, text) to service_role;

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
  if p_official_release_date is not null and (
    (e.official_release_date is not null and e.official_release_date <> p_official_release_date)
    or (r.official_release_date is not null and r.official_release_date <> p_official_release_date)
  ) then
    insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, e.id, e.release_id, 'conflict', coalesce(e.official_release_date, r.official_release_date), p_official_release_date, p_source_hash, coalesce(p_conflict_reason, 'conflicting official release date'), p_idempotency_key)
    on conflict (idempotency_key) do nothing;
    return query select e.id, e.release_id, false, coalesce(e.official_release_date, r.official_release_date);
    return;
  end if;
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
  if coalesce(p_validation_status, 'validated') = 'validated' then
    insert into board_pulse.notification_events(exam_id, event_type, event_key, payload)
    values(e.id, 'exam_results_released', p_idempotency_key, jsonb_build_object(
      'exam_id', e.id,
      'release_id', e.release_id,
      'exam_name', e.name,
      'exam_slug', e.slug,
      'article_url', e.source_article_url,
      'source_url', e.source_article_url,
      'passers_pdf_url', e.passers_pdf_url,
      'top_notchers_pdf_url', e.top_notchers_pdf_url,
      'passers_path', '/' || e.slug || '-passers',
      'top_notchers_path', '/' || e.slug || '-top-notchers',
      'passers_count', (select count(*) from board_pulse.results where exam_id = e.id),
      'topnotchers_count', (select count(*) from board_pulse.top_notchers where exam_id = e.id),
      'official_release_date', effective_date
    )) on conflict (event_key) do nothing;
  end if;
  return query select e.id, e.release_id, true, effective_date;
end;
$$;
revoke all on function board_pulse.publish_legacy_exam(uuid, text, date, text, text, jsonb, text, text, uuid, text, text) from public, anon, authenticated;
grant execute on function board_pulse.publish_legacy_exam(uuid, text, date, text, text, jsonb, text, text, uuid, text, text) to service_role;

-- Replace the wrapper so a release-level date conflict is rejected before the
-- legacy destructive result rewrite is called.
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
    if exists (select 1 from board_pulse.prc_releases where id = e.release_id and official_release_date is not null and official_release_date <> proposed_date) then
      raise exception using errcode = 'P0001', message = 'official_release_date_conflict';
    end if;
  end if;
  select * into legacy_result from board_pulse._publish_exam_track_legacy(
    p_exam_id, p_parser_version, p_source_version_hash, p_batch_id, p_lease_owner,
    p_lease_fencing_token, p_validated_payload_json
  );
  if legacy_result.published and payload ? 'official_release_date' then
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
  if (r.official_release_date is not null and r.official_release_date <> p_official_release_date)
     or (e.official_release_date is not null and e.official_release_date <> p_official_release_date) then
    raise exception using errcode = 'P0001', message = 'backfill_official_release_date_conflict';
  end if;
  update board_pulse.prc_releases set official_release_date = p_official_release_date,
    official_release_date_source_url = p_provenance->'primary'->>'url', official_release_date_source_hash = p_source_hash,
    official_release_date_sources = p_provenance->'sources', official_release_date_parser_version = p_provenance->>'parser_version',
    official_release_date_conflict_reason = p_reason, updated_at = now() where id = p_release_id;
  get diagnostics n = row_count;
  update board_pulse.exams set official_release_date = p_official_release_date,
    official_release_date_source_url = p_provenance->'primary'->>'url', official_release_date_source_hash = p_source_hash,
    official_release_date_sources = p_provenance->'sources', official_release_date_parser_version = p_provenance->>'parser_version',
    official_release_date_conflict_reason = p_reason, updated_at = now() where id = p_exam_id and release_id = p_release_id;
  insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
  values(p_run_id, p_operator, p_exam_id, p_release_id, 'set', e.official_release_date, p_official_release_date, p_source_hash, p_reason, p_idempotency_key)
  on conflict (idempotency_key) do update set id = board_pulse.official_release_date_audit.id returning id into a;
  return query select p_exam_id, p_release_id, n, 1, a;
end;
$$;
revoke all on function board_pulse.backfill_official_release_date(uuid, uuid, date, jsonb, text, uuid, text, text, text) from public, anon, authenticated;
grant execute on function board_pulse.backfill_official_release_date(uuid, uuid, date, jsonb, text, uuid, text, text, text) to service_role;

notify pgrst, 'reload schema';
