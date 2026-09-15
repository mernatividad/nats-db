-- Regression check for the ambiguous release_id reference in the RPC.
do $$
declare
  definition text := pg_get_functiondef(
    'board_pulse.resolve_or_create_prc_exam(text,text,text,date,text,text,text,text)'::regprocedure
  );
begin
  if position('ex.release_id is null' in lower(definition)) = 0 then
    raise exception 'resolve_or_create_prc_exam does not qualify exams.release_id';
  end if;

  foreach definition in array array[
    'on conflict on constraint release_batches_release_hash_key',
    'on conflict on constraint exams_track_identity_key',
    'on conflict on constraint exam_ingestion_states_pkey'
  ] loop
    if position(definition in lower(pg_get_functiondef(
      'board_pulse.resolve_or_create_prc_exam(text,text,text,date,text,text,text,text)'::regprocedure
    ))) = 0 then
      raise exception 'resolve_or_create_prc_exam is missing conflict constraint %', definition;
    end if;
  end loop;
end
$$;
