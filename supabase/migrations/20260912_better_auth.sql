create schema if not exists board_pulse;

create table if not exists board_pulse."user" (
  "id" text primary key,
  "name" text not null,
  "email" text not null unique,
  "emailVerified" boolean not null default false,
  "image" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists board_pulse."session" (
  "id" text primary key,
  "expiresAt" timestamptz not null,
  "token" text not null unique,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  "ipAddress" text,
  "userAgent" text,
  "userId" text not null references board_pulse."user" ("id") on delete cascade
);

create index if not exists better_auth_session_user_id_idx on board_pulse."session" ("userId");

create table if not exists board_pulse."account" (
  "id" text primary key,
  "issuer" text not null,
  "accountId" text not null,
  "providerId" text not null,
  "userId" text not null references board_pulse."user" ("id") on delete cascade,
  "accessToken" text,
  "refreshToken" text,
  "idToken" text,
  "accessTokenExpiresAt" timestamptz,
  "refreshTokenExpiresAt" timestamptz,
  "scope" text,
  "password" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint better_auth_account_issuer_account_unique unique ("issuer", "accountId")
);

create index if not exists better_auth_account_user_id_idx on board_pulse."account" ("userId");

create table if not exists board_pulse."verification" (
  "id" text primary key,
  "identifier" text not null,
  "value" text not null,
  "expiresAt" timestamptz not null,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists better_auth_verification_identifier_idx on board_pulse."verification" ("identifier");

alter table board_pulse."user" enable row level security;
alter table board_pulse."session" enable row level security;
alter table board_pulse."account" enable row level security;
alter table board_pulse."verification" enable row level security;

revoke all on board_pulse."user", board_pulse."session", board_pulse."account", board_pulse."verification" from anon, authenticated;
