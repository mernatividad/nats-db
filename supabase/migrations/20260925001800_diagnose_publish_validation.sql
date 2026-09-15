create or replace function board_pulse.diagnose_publish_exam_track(
  p_exam_id uuid,
  p_batch_id uuid,
  p_source_version_hash text,
  p_validated_payload_json jsonb
)
returns table(error_code text)
language plpgsql
security definer
set search_path = board_pulse, pg_catalog, extensions
as $$
declare
  e board_pulse.exams%rowtype;
  b board_pulse.release_batches%rowtype;
  payload jsonb := coalesce(p_validated_payload_json, '{}'::jsonb);
begin
  select * into e from board_pulse.exams where id = p_exam_id;
  if not found then return query select 'exam_not_found'; return; end if;
  select * into b from board_pulse.release_batches where id = p_batch_id and release_id = e.release_id;
  if not found or b.source_version_hash is distinct from p_source_version_hash
     or b.source_version_hash is distinct from (select source_version_hash from board_pulse.prc_releases where id = e.release_id) then
    return query select 'batch_release_mismatch'; return;
  end if;
  if p_source_version_hash is null or p_source_version_hash !~ '^[0-9a-f]{64}$' then return query select 'invalid_source_hash'; return; end if;
  if payload->>'schema_version' is distinct from '1' then return query select 'schema_version'; return; end if;
  if payload->>'exam_id' is distinct from e.id::text then return query select 'exam_identity'; return; end if;
  if payload->>'release_id' is distinct from e.release_id::text then return query select 'release_identity'; return; end if;
  if payload->>'track_key' is distinct from e.track_key then return query select 'track_identity'; return; end if;
  if payload->>'source_version_hash' is distinct from p_source_version_hash then return query select 'payload_source_hash'; return; end if;
  if coalesce(jsonb_typeof(payload->'documents') <> 'array', true) or coalesce(jsonb_array_length(payload->'documents'), 0) = 0 then return query select 'documents_shape'; return; end if;
  if exists (select 1 from jsonb_array_elements(payload->'documents') d where jsonb_typeof(d) <> 'object' or coalesce(btrim(d->>'document_type'), '') = '' or coalesce(btrim(d->>'canonical_url'), '') = '' or d->>'release_id' is distinct from e.release_id::text or d->>'version_hash' is null or d->>'version_hash' !~ '^[0-9a-f]{64}$') then return query select 'document_identity'; return; end if;
  if exists (select 1 from board_pulse.prc_release_documents d where d.release_id = e.release_id and not exists (select 1 from jsonb_array_elements(payload->'documents') p where p->>'document_type' = d.document_type and p->>'canonical_url' = d.canonical_url)) then return query select 'missing_release_document'; return; end if;
  if coalesce(jsonb_typeof(payload->'results') <> 'array', true) then return query select 'results_shape'; return; end if;
  if coalesce(jsonb_typeof(payload->'top_notchers') <> 'array', true) then return query select 'top_notchers_shape'; return; end if;
  if coalesce((payload->'validation'->>'extraction_complete')::boolean, false) is not true then return query select 'extraction_incomplete'; return; end if;
  if coalesce((payload->'validation'->>'duplicate_count')::integer, 1) <> 0 then return query select 'duplicate_count'; return; end if;
  if ((payload->'validation'->>'count_status') <> 'unavailable' and coalesce((payload->'validation'->>'parsed_count')::integer, -1) <> coalesce((payload->'validation'->>'expected_count')::integer, -2)) then return query select 'count_mismatch'; return; end if;
  if exists (select 1 from jsonb_to_recordset(payload->'results') x(full_name text, school text, rating numeric, remarks text, rank integer) where btrim(coalesce(x.full_name, '')) = '' or x.rank is not null and x.rank < 1) then return query select 'invalid_result'; return; end if;
  if exists (select 1 from (select lower(btrim(x.full_name)) as full_name from jsonb_to_recordset(payload->'results') x(full_name text, school text, rating numeric, remarks text, rank integer) group by lower(btrim(x.full_name)) having count(*) > 1) duplicates) then return query select 'duplicate_result_name'; return; end if;
  if exists (select 1 from jsonb_to_recordset(payload->'top_notchers') x(rank integer, full_name text, school text, rating numeric) where x.rank is null or x.rank < 1 or btrim(coalesce(x.full_name, '')) = '') then return query select 'invalid_top_notcher'; return; end if;
  if exists (select 1 from (select x.rank from jsonb_to_recordset(payload->'top_notchers') x(rank integer, full_name text, school text, rating numeric) group by x.rank having count(*) > 1) duplicates) then return query select 'duplicate_top_notcher_rank'; return; end if;
  if exists (select 1 from board_pulse.prc_release_documents d where d.release_id = e.release_id and d.document_type = 'performance')
     and not (payload->'validation'->>'performance_status' = 'unavailable' or (payload->'validation'->>'performance_status' = 'validated' and coalesce(jsonb_typeof(payload->'performance') <> 'array', true) is not true and coalesce((payload->'validation'->>'performance_reconciled')::boolean, false) is true)) then
    return query select 'performance_validation'; return;
  end if;
  return query select null::text;
end;
$$;

revoke all on function board_pulse.diagnose_publish_exam_track(uuid, uuid, text, jsonb) from public, anon, authenticated;
grant execute on function board_pulse.diagnose_publish_exam_track(uuid, uuid, text, jsonb) to service_role;
notify pgrst, 'reload schema';
