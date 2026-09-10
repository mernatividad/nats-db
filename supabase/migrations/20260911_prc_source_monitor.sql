create table if not exists board_pulse.source_observations (
  id uuid primary key default gen_random_uuid(),
  source_key text not null,
  source_type text not null check (source_type in ('website', 'facebook')),
  canonical_url text not null,
  title text not null default '',
  content_excerpt text not null default '',
  previous_version_hash text,
  version_hash text not null,
  raw_hash text,
  change_type text not null check (change_type in ('post_created', 'post_updated', 'post_removed')),
  category text not null default 'unknown' check (category in ('result', 'exam_update', 'unknown')),
  severity text not null default 'info' check (severity in ('info', 'warning', 'critical')),
  is_relevant boolean not null default false,
  verification_status text not null default 'pending' check (verification_status in ('pending', 'verified', 'rejected', 'failed')),
  review_status text not null default 'detected' check (review_status in ('detected', 'needs_review', 'approved', 'rejected')),
  notification_status text not null default 'pending' check (notification_status in ('pending', 'queued', 'sent', 'suppressed', 'failed', 'not_applicable')),
  source_etag text,
  source_last_modified text,
  run_id text not null,
  error_code text,
  observed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (source_key, canonical_url, version_hash)
);

create index if not exists source_observations_latest_idx
  on board_pulse.source_observations (source_key, canonical_url, observed_at desc);

create index if not exists source_observations_review_queue_idx
  on board_pulse.source_observations (review_status, severity, observed_at desc);

alter table board_pulse.source_observations enable row level security;
drop policy if exists "service role manages source observations" on board_pulse.source_observations;
create policy "service role manages source observations"
  on board_pulse.source_observations for all to service_role using (true) with check (true);

grant select, insert, update on board_pulse.source_observations to service_role;

notify pgrst, 'reload schema';
