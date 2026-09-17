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
  if p_official_release_date is not null and ((e.official_release_date is not null and e.official_release_date <> p_official_release_date) or (r.official_release_date is not null and r.official_release_date <> p_official_release_date)) then
    insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
    values(p_run_id, p_operator, e.id, e.release_id, 'conflict', coalesce(e.official_release_date, r.official_release_date), p_official_release_date, p_source_hash, coalesce(p_conflict_reason, 'conflicting official release date'), p_idempotency_key) on conflict (idempotency_key) do nothing;
    return query select e.id, e.release_id, false, coalesce(e.official_release_date, r.official_release_date); return;
  end if;
  effective_date := coalesce(e.official_release_date, p_official_release_date, r.official_release_date);
  update board_pulse.exams set track_status = 'published', validation_status = coalesce(p_validation_status, 'validated'), is_searchable = true, results_released_at = coalesce(results_released_at, now()), official_release_date = effective_date, official_release_date_source_url = coalesce(official_release_date_source_url, p_source_url), official_release_date_source_hash = coalesce(official_release_date_source_hash, p_source_hash), official_release_date_sources = coalesce(official_release_date_sources, p_sources), official_release_date_parser_version = coalesce(official_release_date_parser_version, p_parser_version), official_release_date_conflict_reason = p_conflict_reason, updated_at = now() where id = e.id;
  update board_pulse.prc_releases as rel set official_release_date = coalesce(rel.official_release_date, effective_date), official_release_date_source_url = coalesce(rel.official_release_date_source_url, p_source_url), official_release_date_source_hash = coalesce(rel.official_release_date_source_hash, p_source_hash), official_release_date_sources = coalesce(rel.official_release_date_sources, p_sources), official_release_date_parser_version = coalesce(rel.official_release_date_parser_version, p_parser_version), updated_at = now() where rel.id = e.release_id;
  insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
  values(p_run_id, p_operator, e.id, e.release_id, case when e.official_release_date is null and effective_date is not null then 'set' else 'preserve' end, e.official_release_date, effective_date, p_source_hash, p_conflict_reason, p_idempotency_key) on conflict (idempotency_key) do nothing;
  if coalesce(p_validation_status, 'validated') = 'validated' then
    insert into board_pulse.notification_events(exam_id, event_type, event_key, payload)
    values(e.id, 'exam_results_released', p_idempotency_key, jsonb_build_object('exam_id', e.id, 'release_id', e.release_id, 'exam_name', e.name, 'exam_slug', e.slug, 'article_url', e.source_article_url, 'source_url', e.source_article_url, 'passers_pdf_url', e.passers_pdf_url, 'top_notchers_pdf_url', e.top_notchers_pdf_url, 'passers_path', '/' || e.slug || '-passers', 'top_notchers_path', '/' || e.slug || '-top-notchers', 'passers_count', (select count(*) from board_pulse.results res where res.exam_id = e.id), 'topnotchers_count', (select count(*) from board_pulse.top_notchers tn where tn.exam_id = e.id), 'official_release_date', effective_date)) on conflict (event_key) do nothing;
  end if;
  return query select e.id, e.release_id, true, effective_date;
end;
$$;
revoke all on function board_pulse.publish_legacy_exam(uuid, text, date, text, text, jsonb, text, text, uuid, text, text) from public, anon, authenticated;
grant execute on function board_pulse.publish_legacy_exam(uuid, text, date, text, text, jsonb, text, text, uuid, text, text) to service_role;
