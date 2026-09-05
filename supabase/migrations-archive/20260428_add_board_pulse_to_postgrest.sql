-- Add board_pulse schema to PostgREST exposed schemas
-- This enables the API to access board_pulse tables

-- Grant usage on board_pulse schema to anon and authenticated roles
grant usage on schema board_pulse to anon, authenticated, service_role;

-- Grant necessary permissions on board_pulse tables
grant select on board_pulse.exams to anon, authenticated, service_role;
grant select on board_pulse.results to anon, authenticated, service_role;
grant select on board_pulse.top_notchers to anon, authenticated, service_role;

-- Add board_pulse to PostgREST's schema search path (for local dev)
alter database postgres set search_path to public, board_pulse;

-- Notify PostgREST to reload schema cache
notify pgrst, 'reload schema';