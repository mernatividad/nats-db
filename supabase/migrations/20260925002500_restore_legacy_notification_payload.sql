-- Preserve the legacy notification payload fields while retaining the
-- canonical official release date and provenance fields.

do $body$
declare
  definition text;
  old_block text := $q$'passers_count', (select count(*) from board_pulse.results where exam_id = e.id),
      'topnotchers_count', (select count(*) from board_pulse.top_notchers where exam_id = e.id),
      'official_release_date', effective_date$q$;
  new_block text := $q$'passers_count', (select count(*) from board_pulse.results where exam_id = e.id),
      'official_passers_count', (select count(*) from board_pulse.results where exam_id = e.id),
      'total_examinees', (select coalesce(sum(examined_count), 0) from board_pulse.school_performance where exam_id = e.id),
      'passing_rate', (select case when coalesce(sum(examined_count), 0) = 0 then null else round(100.0 * sum(passed_count) / sum(examined_count), 2) end from board_pulse.school_performance where exam_id = e.id),
      'topnotchers_count', (select count(*) from board_pulse.top_notchers where exam_id = e.id),
      'topnotchers', coalesce((select jsonb_agg(jsonb_build_object('full_name', full_name, 'school', school, 'rating', rating) order by rank) from board_pulse.top_notchers where exam_id = e.id and rank = 1), '[]'::jsonb),
      'official_release_date', effective_date,
      'official_release_date_source_url', p_source_url,
      'official_release_date_source_hash', p_source_hash,
      'official_release_date_sources', p_sources,
      'official_release_date_parser_version', p_parser_version,
      'official_release_date_conflict_reason', p_conflict_reason$q$;
begin
  select pg_get_functiondef(p.oid) into definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'board_pulse'
    and p.proname = 'publish_legacy_exam'
    and pg_get_function_identity_arguments(p.oid) = 'p_exam_id uuid, p_validation_status text, p_official_release_date date, p_source_url text, p_source_hash text, p_sources jsonb, p_parser_version text, p_conflict_reason text, p_run_id uuid, p_operator text, p_idempotency_key text';
  if definition is null or position(old_block in definition) = 0 then
    raise exception 'publish_legacy_exam notification payload contract not found';
  end if;
  execute replace(definition, old_block, new_block);
end;
$body$;

notify pgrst, 'reload schema';
