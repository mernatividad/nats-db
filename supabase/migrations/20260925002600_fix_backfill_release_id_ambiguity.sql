-- Qualify the parent identity predicate: the RETURNS TABLE output column
-- `release_id` otherwise collides with the exams table column in PL/pgSQL.

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
  select rel.* into r from board_pulse.prc_releases rel where rel.id = p_release_id;
  select ex.* into e from board_pulse.exams ex where ex.id = p_exam_id and ex.release_id = p_release_id;
  if not found then raise exception using errcode = '23514', message = 'backfill_parent_identity_mismatch'; end if;
  if (r.official_release_date is not null and r.official_release_date <> p_official_release_date)
     or (e.official_release_date is not null and e.official_release_date <> p_official_release_date) then
    raise exception using errcode = 'P0001', message = 'backfill_official_release_date_conflict';
  end if;
  update board_pulse.prc_releases rel set official_release_date = p_official_release_date,
    official_release_date_source_url = p_provenance->'primary'->>'url', official_release_date_source_hash = p_source_hash,
    official_release_date_sources = p_provenance->'sources', official_release_date_parser_version = p_provenance->>'parser_version',
    official_release_date_conflict_reason = p_reason, updated_at = now() where rel.id = p_release_id;
  get diagnostics n = row_count;
  update board_pulse.exams ex set official_release_date = p_official_release_date,
    official_release_date_source_url = p_provenance->'primary'->>'url', official_release_date_source_hash = p_source_hash,
    official_release_date_sources = p_provenance->'sources', official_release_date_parser_version = p_provenance->>'parser_version',
    official_release_date_conflict_reason = p_reason, updated_at = now() where ex.id = p_exam_id and ex.release_id = p_release_id;
  insert into board_pulse.official_release_date_audit(run_id, operator, exam_id, release_id, action, old_date, new_date, source_hash, reason, idempotency_key)
  values(p_run_id, p_operator, p_exam_id, p_release_id, 'set', e.official_release_date, p_official_release_date, p_source_hash, p_reason, p_idempotency_key)
  on conflict (idempotency_key) do update set id = board_pulse.official_release_date_audit.id returning id into a;
  return query select p_exam_id, p_release_id, n, 1, a;
end;
$$;
revoke all on function board_pulse.backfill_official_release_date(uuid, uuid, date, jsonb, text, uuid, text, text, text) from public, anon, authenticated;
grant execute on function board_pulse.backfill_official_release_date(uuid, uuid, date, jsonb, text, uuid, text, text, text) to service_role;

notify pgrst, 'reload schema';
