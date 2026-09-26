set search_path = bullish_banana, extensions, public;

-- The application maps Better Auth's provider identity to provider_id.
-- Keep issuer for OAuth provenance, but do not make it a required write for
-- the adapter; Better Auth rejects schemas with required columns it does not
-- populate.
alter table bullish_banana.accounts
  alter column issuer drop not null;
