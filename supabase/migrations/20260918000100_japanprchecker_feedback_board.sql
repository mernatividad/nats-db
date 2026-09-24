create schema if not exists japanprchecker;

set search_path = japanprchecker, extensions;

create table if not exists japanprchecker.feedback_posts (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references japanprchecker."user" ("id") on delete cascade,
  title varchar(120) not null,
  description varchar(2000) not null,
  category text not null check (category in ('feature', 'bug', 'content', 'other')),
  display_name varchar(40) not null,
  status text not null default 'under_review' check (status in ('under_review', 'planned', 'in_progress', 'shipped', 'declined', 'duplicate')),
  vote_count integer not null default 0 check (vote_count >= 0),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists feedback_posts_public_idx
  on japanprchecker.feedback_posts (status, vote_count desc, created_at desc)
  where archived_at is null;

create table if not exists japanprchecker.feedback_votes (
  post_id uuid not null references japanprchecker.feedback_posts (id) on delete cascade,
  user_id text not null references japanprchecker."user" ("id") on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists japanprchecker.feedback_subscriptions (
  post_id uuid not null references japanprchecker.feedback_posts (id) on delete cascade,
  user_id text not null references japanprchecker."user" ("id") on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists japanprchecker.feedback_audit_log (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references japanprchecker.feedback_posts (id) on delete set null,
  actor_user_id text references japanprchecker."user" ("id") on delete set null,
  action text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table japanprchecker.feedback_posts enable row level security;
alter table japanprchecker.feedback_votes enable row level security;
alter table japanprchecker.feedback_subscriptions enable row level security;
alter table japanprchecker.feedback_audit_log enable row level security;

revoke all on table japanprchecker.feedback_posts from anon, authenticated;
revoke all on table japanprchecker.feedback_votes from anon, authenticated;
revoke all on table japanprchecker.feedback_subscriptions from anon, authenticated;
revoke all on table japanprchecker.feedback_audit_log from anon, authenticated;

create or replace function japanprchecker.touch_feedback_post_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists feedback_posts_touch_updated_at on japanprchecker.feedback_posts;
create trigger feedback_posts_touch_updated_at
before update on japanprchecker.feedback_posts
for each row execute function japanprchecker.touch_feedback_post_updated_at();

