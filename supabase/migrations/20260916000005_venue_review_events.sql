-- Private audit trail for human review decisions.
create table wheretayo.venue_review_events (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references wheretayo.venues(id) on delete cascade,
  previous_status text not null check (previous_status in ('draft', 'review', 'published', 'archived')),
  new_status text not null check (new_status in ('draft', 'review', 'published', 'archived')),
  reviewer text not null check (char_length(trim(reviewer)) between 2 and 120),
  notes text,
  created_at timestamptz not null default now()
);

create index venue_review_events_venue_id_idx on wheretayo.venue_review_events (venue_id, created_at desc);

alter table wheretayo.venue_review_events enable row level security;
revoke all on wheretayo.venue_review_events from public, anon, authenticated;
grant all on wheretayo.venue_review_events to service_role;
