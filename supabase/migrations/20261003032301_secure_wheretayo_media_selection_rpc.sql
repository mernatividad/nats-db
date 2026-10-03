-- Media selection is an administrative operation. The function is SECURITY
-- DEFINER because it updates private media and venue rows, so callers must be
-- limited to trusted server-side service-role code.
revoke all on function wheretayo.set_selected_venue_media(uuid, uuid)
  from public, anon, authenticated;
grant execute on function wheretayo.set_selected_venue_media(uuid, uuid)
  to service_role;
