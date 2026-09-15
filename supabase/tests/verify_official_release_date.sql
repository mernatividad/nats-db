-- Deterministic schema contract checks for 20260925002200.
begin;
do $$
declare expected text[] := array[
  'set_prc_release_official_date(uuid,date,text,text,jsonb,text,text,uuid,text,text)',
  'resolve_or_create_prc_exam(text,text,text,date,text,text,text,text)',
  'publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)',
  'backfill_official_release_date(uuid,uuid,date,jsonb,text,uuid,text,text,text)',
  'audit_notification_release_date_conflict(uuid,uuid,date,date,text)'
]; item text; lock_def text;
begin
  foreach item in array expected loop
    if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'board_pulse' and p.oid::regprocedure::text like '%' || item) then
      raise exception 'missing function signature %', item;
    end if;
  end loop;
  if not exists (select 1 from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'board_pulse' and c.relname = 'exams' and a.attname = 'official_release_date' and a.atttypid = 'date'::regtype) then
    raise exception 'exams official_release_date is not date';
  end if;
  if not exists (select 1 from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'board_pulse' and c.relname = 'passer_search_index' and a.attname = 'result_release_date' and a.atttypid = 'date'::regtype) then
    raise exception 'search result_release_date is not date';
  end if;
  foreach item in array array['result_id','exam_id','release_id','track_key','exam_slug','exam_name','full_name','normalized_name','result_release_date','result_status','rank','rating','source_url','official_source_url','is_topnotcher','validation_status','source_coverage_status','normalization_version','normalized_tokens','search_document'] loop
    if not exists (select 1 from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'board_pulse' and c.relname = 'passer_search_index' and a.attname = item and a.attnum > 0 and not a.attisdropped) then
      raise exception 'search index missing column %', item;
    end if;
  end loop;
  if not exists (select 1 from pg_indexes where schemaname = 'board_pulse' and tablename = 'passer_search_index' and indexname = 'passer_search_index_identity_idx' and indexdef ilike '%result_release_date desc nulls last%') then
    raise exception 'search identity index/order is missing';
  end if;
  if not exists (select 1 from pg_indexes where schemaname = 'board_pulse' and tablename = 'passer_search_index' and indexname = 'passer_search_index_exam_scope_idx' and indexdef ilike '%result_release_date desc nulls last%') then
    raise exception 'search exam-scope index/order is missing';
  end if;
  if position('official_release_date' in pg_get_viewdef('board_pulse.passer_search_index_refresh_source'::regclass, true)) = 0 then
    raise exception 'search source does not project official release date';
  end if;
  if has_table_privilege('anon', 'board_pulse.official_release_date_audit', 'select') then raise exception 'audit table exposed to anon'; end if;
  if has_function_privilege('anon', 'board_pulse.set_prc_release_official_date(uuid,date,text,text,jsonb,text,text,uuid,text,text)', 'execute') then raise exception 'setter exposed to anon'; end if;
  if has_function_privilege('anon', 'board_pulse._lock_release_graph(uuid)', 'execute') then raise exception 'lock helper exposed to anon'; end if;
  if position('_lock_release_graph' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0 then raise exception 'legacy publisher does not use parent-first lock graph'; end if;
  if position('notification_events' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0
     or position('passers_count' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0
     or position('official_passers_count' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0
     or position('total_examinees' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0
     or position('passing_rate' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0
     or position('topnotchers' in pg_get_functiondef('board_pulse.publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)'::regprocedure)) = 0 then
    raise exception 'legacy publisher notification payload is incomplete';
  end if;
  if position('for update' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) = 0 then raise exception 'lock graph does not lock rows'; end if;
  if position('prc_releases' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) > position('release_batches' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) then raise exception 'lock graph release/batch order is inverted'; end if;
  if position('release_batches' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) > position('exam_ingestion_states' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) then raise exception 'lock graph batch/state order is inverted'; end if;
  if position('exam_ingestion_states' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) > position('exams' in lower(pg_get_functiondef('board_pulse._lock_release_graph(uuid)'::regprocedure))) then raise exception 'lock graph state/exam order is inverted'; end if;
  if position('claim_release_outbox' in pg_get_functiondef('board_pulse.claim_release_outbox(uuid,integer,integer)'::regprocedure)) = 0 then raise exception 'outbox function missing'; end if;
  foreach item in array array[
    'resolve_or_create_prc_exam(text,text,text,date,text,text,text,text)',
    'set_prc_release_official_date(uuid,date,text,text,jsonb,text,text,uuid,text,text)',
    'publish_exam_track(uuid,text,text,uuid,uuid,bigint,jsonb)',
    'backfill_official_release_date(uuid,uuid,date,jsonb,text,uuid,text,text,text)'
  ] loop
    lock_def := pg_get_functiondef(('board_pulse.' || item)::regprocedure);
    if position('_lock_release_graph' in lock_def) = 0 and item not like 'resolve_or_create_prc_exam%' then
      raise exception 'function % does not use the canonical lock graph', item;
    end if;
  end loop;
  lock_def := pg_get_functiondef('board_pulse.resolve_or_create_prc_exam(text,text,text,date,text,text,text,text)'::regprocedure);
  if position('for update' in lower(lock_def)) = 0 or position('prc_releases' in lower(lock_def)) > position('release_batches' in lower(lock_def)) then
    raise exception 'resolve_or_create_prc_exam does not lock release before batch';
  end if;
  lock_def := pg_get_functiondef('board_pulse.claim_release_outbox(uuid,integer,integer)'::regprocedure);
  if position('prc_releases' in lower(lock_def)) > 0 or position('exam_ingestion_states' in lower(lock_def)) > 0 or position('board_pulse.exams' in lower(lock_def)) > 0 then
    raise exception 'claim_release_outbox unexpectedly acquires parent locks';
  end if;
end
$$;
rollback;
