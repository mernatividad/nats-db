# nats-db

Authoritative Supabase database project for PRC Board Pulse.

This repository owns the Supabase CLI configuration, migration history, archived migrations, and database verification SQL used by the `nats22` application. The application repository consumes the remote `board_pulse` schema but does not contain or create migrations.

## Local database

From this repository:

```bash
supabase start
supabase db reset --local --yes
supabase db push --dry-run
```

Use `supabase db push` only when intentionally applying pending migrations to the linked project. Keep credentials outside the repository.

## Verification

Verification SQL lives under `supabase/verification/`. Run it against a representative local, staging, or production-like database after applying the relevant migrations.

The `nats22` scraper and Next.js application connect to Supabase through environment variables. Their Docker/runtime configuration remains in `nats22`; database schema changes belong here.
