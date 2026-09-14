-- Corrective deployment after the broad board_pulse routine grant in 20260909.
-- The broad grant also grants EXECUTE on
-- this expensive maintenance function. Keep refresh access service-role-only.
revoke all on function board_pulse.refresh_passer_search_index() from public;
revoke all on function board_pulse.refresh_passer_search_index() from anon, authenticated;
grant execute on function board_pulse.refresh_passer_search_index() to service_role;
