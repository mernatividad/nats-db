-- Forward-only dependency repair for the feedback-board migration.
-- The feedback migration at 20260918000100 references this identity table,
-- while the complete Better Auth migration is timestamped later.
-- Keep the table definition compatible so the later migration can extend it.

create schema if not exists japanprchecker;

set search_path = japanprchecker, extensions, public;

create table if not exists japanprchecker."user" (
  "id" text primary key,
  "name" text not null,
  "email" text not null unique,
  "emailVerified" boolean not null default false,
  "image" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);
