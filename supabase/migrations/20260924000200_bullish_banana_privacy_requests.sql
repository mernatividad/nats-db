create table bullish_banana.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references bullish_banana.users(id) on delete cascade,
  request_type text not null check (request_type in ('account_deletion', 'content_erasure')),
  message text not null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'rejected')),
  resolved_by text references bullish_banana.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index privacy_requests_user_time_idx
  on bullish_banana.privacy_requests (user_id, created_at desc);
create index privacy_requests_status_time_idx
  on bullish_banana.privacy_requests (status, created_at desc);

alter table bullish_banana.privacy_requests enable row level security;
grant all on bullish_banana.privacy_requests to service_role;
