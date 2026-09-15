-- Deterministic schema contract checks for 20260925002200.
begin;
do $$
declare expected text[] := array[
  'set_prc_release_official_date(uuid,date,text,text,jsonb,text,text,uuid,text,text)',
  'resolve_or_create_prc_exam(text,text,text,date,text,text,text,text)',
  'publish_legacy_exam(uuid,text,date,text,text,jsonb,text,text,uuid,text,text)',
  'backfill_official_release_date(uuid,uuid,date,jsonb,text,uuid,text,text,text)',
  'audit_notification_release_date_conflict(uuid,uuid,date,date,text)'
]; item text;
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
  if has_table_privilege('anon', 'board_pulse.official_release_date_audit', 'select') then raise exception 'audit table exposed to anon'; end if;
  if has_function_privilege('anon', 'board_pulse.set_prc_release_official_date(uuid,date,text,text,jsonb,text,text,uuid,text,text)', 'execute') then raise exception 'setter exposed to anon'; end if;
  if position('claim_release_outbox' in pg_get_functiondef('board_pulse.claim_release_outbox(uuid,integer,integer)'::regprocedure)) = 0 then raise exception 'outbox function missing'; end if;
end
$$;
rollback;
