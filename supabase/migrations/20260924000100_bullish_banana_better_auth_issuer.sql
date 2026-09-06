-- Align Better Auth account identity with provider issuer semantics.
alter table bullish_banana.accounts
  add column if not exists issuer text;

update bullish_banana.accounts
set issuer = provider_id
where issuer is null;

alter table bullish_banana.accounts
  alter column issuer set not null;

alter table bullish_banana.accounts
  drop constraint if exists accounts_provider_id_account_id_key;

alter table bullish_banana.accounts
  add constraint accounts_issuer_account_id_key unique (issuer, account_id);
