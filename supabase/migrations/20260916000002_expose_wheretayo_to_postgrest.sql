-- Expose the application schema through Supabase's Data API.
alter role authenticator set pgrst.db_schemas = 'public, board_pulse, wheretayo';
notify pgrst, 'reload config';
