-- Regression check for the resolver's PL/pgSQL output-column ambiguity.
do $$
declare
  definition text;
begin
  select pg_get_functiondef(p.oid)
    into definition
  from pg_proc p
  where p.oid = 'board_pulse.resolve_or_create_prc_exam(text, text, text, date, text, text, text, text)'::regprocedure;

  if definition is null then
    raise exception 'verification failed: resolver function is missing';
  end if;

  if definition ~* 'and[[:space:]]+release_id[[:space:]]+is[[:space:]]+null' then
    raise exception 'verification failed: resolver contains an unqualified release_id reference';
  end if;

  if definition ~* 'on[[:space:]]+conflict[[:space:]]*\([[:space:]]*release_id' then
    raise exception 'verification failed: resolver contains an ambiguous release_id conflict target';
  end if;
end;
$$;
