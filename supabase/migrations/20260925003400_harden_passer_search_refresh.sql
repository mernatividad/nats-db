-- Search-index refreshes can exceed Supabase's short statement timeout as the
-- passer corpus grows. Run the bounded maintenance operation without that
-- client statement timeout and serialize overlapping refreshes from concurrent
-- scraper runs. The non-concurrent form is required because the RPC executes
-- inside a database transaction.

create or replace function board_pulse.refresh_passer_search_index()
returns void
language plpgsql
security definer
set search_path = board_pulse, pg_catalog
set statement_timeout = 0
as $$
begin
  perform pg_advisory_xact_lock(hashtextextended('board_pulse.passer_search_index', 0));
  refresh materialized view board_pulse.passer_search_index;
end;
$$;

revoke all on function board_pulse.refresh_passer_search_index() from public;
revoke all on function board_pulse.refresh_passer_search_index() from anon, authenticated;
grant execute on function board_pulse.refresh_passer_search_index() to service_role;

notify pgrst, 'reload schema';
