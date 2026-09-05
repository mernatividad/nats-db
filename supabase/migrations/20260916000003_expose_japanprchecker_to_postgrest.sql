-- Expose the Japan PR Checker application schema through PostgREST.
-- The tables and RPC retain the explicit grants and RLS policies from the
-- preceding migration; this only updates the PostgREST schema allowlist.
alter role authenticator set pgrst.db_schemas = 'public, graphql_public, board_pulse, wheretayo, japanprchecker';
notify pgrst, 'reload config';
