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
end
$$;
