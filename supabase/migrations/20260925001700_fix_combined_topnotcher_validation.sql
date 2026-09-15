do $do$
declare
  function_definition text;
begin
  select pg_get_functiondef(p.oid)
    into function_definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'board_pulse'
    and p.proname = 'publish_exam_track'
    and pg_get_function_identity_arguments(p.oid) =
      'p_exam_id uuid, p_parser_version text, p_source_version_hash text, p_batch_id uuid, p_lease_owner uuid, p_lease_fencing_token bigint, p_validated_payload_json jsonb';

  if function_definition is null then
    raise exception 'publish_exam_track function not found';
  end if;

  function_definition := regexp_replace(
    function_definition,
    $pattern$or exists \(select 1 from jsonb_to_recordset\(payload->'top_notchers'\).*?and rr\.rating is not distinct from tn\.rating\)\)\n     or$pattern$,
    'or false' || E'\n     or',
    1,
    1,
    'n'
  );

  if function_definition = pg_get_functiondef((
    select p.oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'board_pulse'
      and p.proname = 'publish_exam_track'
      and pg_get_function_identity_arguments(p.oid) =
        'p_exam_id uuid, p_parser_version text, p_source_version_hash text, p_batch_id uuid, p_lease_owner uuid, p_lease_fencing_token bigint, p_validated_payload_json jsonb'
  )) then
    raise exception 'top-notcher validation clause was not found';
  end if;

  execute function_definition;
end
$do$;

notify pgrst, 'reload schema';
