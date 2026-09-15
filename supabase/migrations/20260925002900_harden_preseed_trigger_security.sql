-- The release-link trigger only runs from service-role writes. Keep the
-- function invoker-secured and avoid exposing an executable public function.
alter function board_pulse.link_preseeded_alerts()
  security invoker;

revoke all on function board_pulse.link_preseeded_alerts() from public, anon, authenticated;
grant execute on function board_pulse.link_preseeded_alerts() to service_role;

notify pgrst, 'reload schema';
