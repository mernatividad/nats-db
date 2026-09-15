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

  function_definition := replace(
    function_definition,
    $$     or exists (select 1 from board_pulse.prc_release_documents d where d.release_id = e.release_id and not exists (select 1 from jsonb_array_elements(payload->'documents') p where p->>'document_type' = d.document_type and p->>'canonical_url' = d.canonical_url))$$,
    '     or false'
  );
  function_definition := replace(
    function_definition,
    '  insert into board_pulse.prc_release_documents',
    '  delete from board_pulse.prc_release_documents where release_id = e.release_id;' || E'\n' || '  insert into board_pulse.prc_release_documents'
  );

  execute function_definition;
end
$do$;

notify pgrst, 'reload schema';
