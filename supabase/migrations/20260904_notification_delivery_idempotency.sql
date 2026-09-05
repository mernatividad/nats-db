-- Prevent concurrent notification workers from creating duplicate deliveries.
create unique index if not exists notification_deliveries_identity_key
  on board_pulse.notification_deliveries (event_id, subscription_id, channel, destination_id)
  where event_id is not null;

notify pgrst, 'reload schema';
