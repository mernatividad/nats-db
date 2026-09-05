-- Expose board_pulse through PostgREST and grant API access.

alter role authenticator set pgrst.db_schemas = 'public, board_pulse';

grant usage on schema board_pulse to anon, authenticated, service_role;
grant all on all tables in schema board_pulse to anon, authenticated, service_role;
grant all on all routines in schema board_pulse to anon, authenticated, service_role;
grant all on all sequences in schema board_pulse to anon, authenticated, service_role;

alter default privileges for role postgres in schema board_pulse
grant all on tables to anon, authenticated, service_role;

alter default privileges for role postgres in schema board_pulse
grant all on routines to anon, authenticated, service_role;

alter default privileges for role postgres in schema board_pulse
grant all on sequences to anon, authenticated, service_role;

notify pgrst, 'reload schema';
