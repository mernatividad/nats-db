-- Better Auth 1.7.3+ identifies accounts by providerId and accountId and does
-- not write issuer. Remove the legacy required column and uniqueness key that
-- were introduced by Better Auth 1.7.0 through 1.7.2.
alter table board_pulse."account"
  alter column "issuer" drop not null;

alter table board_pulse."account"
  drop constraint if exists better_auth_account_issuer_account_unique;

alter table board_pulse."account"
  add constraint better_auth_account_provider_account_unique
  unique ("providerId", "accountId");
