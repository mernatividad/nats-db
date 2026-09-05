grant usage on schema board_pulse to service_role;
grant select on board_pulse.passer_search_index to service_role;
notify pgrst, 'reload schema';
