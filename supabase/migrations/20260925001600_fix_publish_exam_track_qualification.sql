create or replace function board_pulse.publish_exam_track(
  p_exam_id uuid, p_parser_version text, p_source_version_hash text, p_batch_id uuid, p_lease_owner uuid, p_lease_fencing_token bigint, p_validated_payload_json jsonb
)
returns table(exam_id uuid, release_id uuid, published boolean, outbox_id uuid, error_code text)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
#variable_conflict use_column
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
        and not (payload->'validation'->>'performance_status' = 'unavailable' or (payload->'validation'->>'performance_status' = 'validated' and coalesce(jsonb_typeof(payload->'performance') <> 'array', true) is not true and coalesce((payload->'validation'->>'performance_reconciled')::boolean, false) is true)) then
    update board_pulse.exam_ingestion_states i2 set state = 'failed', lease_owner = null, lease_until = null, last_error = 'validation_failed', updated_at = now() where i2.release_id = s.release_id and i2.track_key = s.track_key and i2.parser_version = s.parser_version;
    update board_pulse.exams set track_status = 'failed', validation_status = 'failed' where id = e.id;
    return query select e.id, e.release_id, false, null::uuid, 'validation_failed'; return;
  end if;
  insert into board_pulse.prc_release_documents(release_id, exam_id, document_type, label, canonical_url, association_confidence, top_rank_limit, version_hash, parse_status, committed_object_key, promotion_status, promoted_at)
  select e.release_id, case when d->>'document_type' in ('passers', 'topnotchers') then e.id else null end, d->>'document_type', coalesce(d->>'label', d->>'document_type'), d->>'canonical_url', 'high', nullif(d->>'top_rank_limit', '')::integer, d->>'version_hash', 'parsed', d->>'committed_object_key', case when coalesce(d->>'committed_object_key', '') <> '' then 'promoted' else 'staged' end, case when coalesce(d->>'committed_object_key', '') <> '' then now() else null end
  from jsonb_array_elements(payload->'documents') d
  on conflict (release_id, document_type, canonical_url) do update set exam_id = excluded.exam_id, label = excluded.label, version_hash = excluded.version_hash, parse_status = excluded.parse_status, committed_object_key = excluded.committed_object_key, promotion_status = excluded.promotion_status, promoted_at = excluded.promoted_at, updated_at = now();
  delete from board_pulse.results as result_row where result_row.exam_id = e.id;
  insert into board_pulse.results(exam_id, full_name, school, rating, remarks, rank)
  select e.id, btrim(x.full_name), btrim(coalesce(x.school, '')), x.rating, btrim(x.remarks), x.rank from jsonb_to_recordset(coalesce(payload->'results', '[]'::jsonb)) x(full_name text, school text, rating numeric, remarks text, rank integer);
  delete from board_pulse.top_notchers t2 where t2.exam_id = e.id;
  insert into board_pulse.top_notchers(exam_id, rank, full_name, school, rating)
  select e.id, x.rank, btrim(x.full_name), btrim(coalesce(x.school, '')), x.rating from jsonb_to_recordset(coalesce(payload->'top_notchers', '[]'::jsonb)) x(rank integer, full_name text, school text, rating numeric);
  delete from board_pulse.school_performance sp where sp.exam_id = e.id;
  insert into board_pulse.school_performance(exam_id, school_name, examined_count, passed_count, passing_percentage, rank, qualification_text, source_row_text, first_timers_passed_count, first_timers_failed_count, first_timers_conditioned_count, first_timers_total_count, first_timers_passing_percentage, repeaters_passed_count, repeaters_failed_count, repeaters_conditioned_count, repeaters_total_count, repeaters_passing_percentage, overall_failed_count, overall_conditioned_count)
  select e.id, btrim(x.school_name), x.examined_count, x.passed_count, x.passing_percentage, x.rank, x.qualification_text, btrim(x.source_row_text), x.first_timers_passed_count, x.first_timers_failed_count, x.first_timers_conditioned_count, x.first_timers_total_count, x.first_timers_passing_percentage, x.repeaters_passed_count, x.repeaters_failed_count, x.repeaters_conditioned_count, x.repeaters_total_count, x.repeaters_passing_percentage, x.overall_failed_count, x.overall_conditioned_count
  from jsonb_to_recordset(coalesce(payload->'performance', '[]'::jsonb)) x(school_name text, examined_count integer, passed_count integer, passing_percentage numeric, rank integer, qualification_text text, source_row_text text, first_timers_passed_count integer, first_timers_failed_count integer, first_timers_conditioned_count integer, first_timers_total_count integer, first_timers_passing_percentage numeric, repeaters_passed_count integer, repeaters_failed_count integer, repeaters_conditioned_count integer, repeaters_total_count integer, repeaters_passing_percentage numeric, overall_failed_count integer, overall_conditioned_count integer)
  where btrim(coalesce(x.school_name, '')) <> '' and btrim(coalesce(x.source_row_text, '')) <> '';
  insert into board_pulse.release_artifacts(release_id, exam_id, artifact_kind, staging_object_key, committed_object_key)
  select e.release_id, e.id, x.kind, x.staging_object_key, x.committed_object_key from jsonb_to_recordset(coalesce(payload->'artifacts', '[]'::jsonb)) x(kind text, staging_object_key text, committed_object_key text)
  where btrim(coalesce(x.kind, '')) <> '' and btrim(coalesce(x.staging_object_key, '')) <> '' and btrim(coalesce(x.committed_object_key, '')) <> ''
  on conflict (exam_id, artifact_kind, committed_object_key) do update set staging_object_key = excluded.staging_object_key;
  update board_pulse.exams set track_status = 'published', validation_status = 'validated', is_searchable = true, results_released_at = coalesce(results_released_at, now()), passers_pdf_url = coalesce((select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'passers' limit 1), passers_pdf_url), top_notchers_pdf_url = coalesce((select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'topnotchers' limit 1), top_notchers_pdf_url), performance_of_schools_pdf_url = coalesce((select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'performance' limit 1), performance_of_schools_pdf_url), updated_at = now() where id = e.id;
  update board_pulse.exam_ingestion_states set state = 'published', expected_source_hash = p_source_version_hash, lease_owner = null, lease_until = null, updated_at = now() where release_id = e.release_id and track_key = e.track_key and parser_version = p_parser_version;
  event_key := e.id::text || ':exam_results_released:' || p_source_version_hash;
  insert into board_pulse.release_outbox(batch_id, release_id, exam_id, event_key, event_type, source_version_hash, payload)
  values(p_batch_id, e.release_id, e.id, event_key, 'exam_results_released', p_source_version_hash, jsonb_build_object('exam_id', e.id, 'release_id', e.release_id, 'track_key', e.track_key, 'exam_name', e.name, 'exam_slug', e.slug, 'passers_count', (select count(*) from board_pulse.results where exam_id = e.id), 'top_notchers_count', (select count(*) from board_pulse.top_notchers where exam_id = e.id), 'passers_pdf_url', (select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'passers' limit 1), 'top_notchers_pdf_url', (select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'topnotchers' limit 1), 'performance_of_schools_pdf_url', (select d->>'canonical_url' from jsonb_array_elements(payload->'documents') d where d->>'document_type' = 'performance' limit 1)))
  on conflict(event_key) do update set updated_at = now() returning * into outbox_row;
  update board_pulse.release_batches b set terminal_track_count = (select count(*) from board_pulse.exam_ingestion_states i join board_pulse.prc_releases r on r.id = i.release_id where i.release_id = e.release_id and i.parser_version = r.latest_parser_version and i.is_expected and i.state in ('published', 'unavailable')), search_refresh_status = case when (select count(*) from board_pulse.exam_ingestion_states i join board_pulse.prc_releases r on r.id = i.release_id where i.release_id = e.release_id and i.parser_version = r.latest_parser_version and i.is_expected and i.state not in ('published', 'unavailable')) = 0 then 'pending' else 'open' end, updated_at = now() where b.id = p_batch_id;
  update board_pulse.prc_releases r2 set status = case when (select terminal_track_count from board_pulse.release_batches where id = p_batch_id) >= (select expected_track_count from board_pulse.release_batches where id = p_batch_id) then 'published' when (select terminal_track_count from board_pulse.release_batches where id = p_batch_id) > 0 then 'partial' else r2.status end, updated_at = now() where r2.id = e.release_id;
  return query select e.id, e.release_id, true, outbox_row.id, null::text;
end;
$$;

revoke all on function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb) from public, anon, authenticated;
grant execute on function board_pulse.publish_exam_track(uuid, text, text, uuid, uuid, bigint, jsonb) to service_role;
notify pgrst, 'reload schema';
