-- Approval-gated social drafts are intentionally separate from notification
-- delivery and the existing Facebook queue.
create table if not exists board_pulse.social_release_outbox (
  id uuid primary key default extensions.gen_random_uuid(),
  exam_id uuid references board_pulse.exams(id) on delete restrict,
  preseeded_page_id uuid references board_pulse.preseeded_result_pages(id) on delete restrict,
  canonical_slug text not null,
  platform text not null,
  campaign_type text not null,
  content_version text not null default 'v1',
  event_key text not null,
  message text not null,
  link text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'draft',
  approved_by text,
  approved_at timestamptz,
  sent_at timestamptz,
  provider_response_id text,
  last_error text,
  attempt_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint social_release_outbox_owner_check check ((exam_id is not null) <> (preseeded_page_id is not null)),
  constraint social_release_outbox_platform_check check (platform in ('facebook', 'x')),
  constraint social_release_outbox_campaign_check check (campaign_type in ('pre-release-tracker', 'verified-result')),
  constraint social_release_outbox_status_check check (status in ('draft', 'approved', 'sending', 'sent', 'failed', 'cancelled')),
  constraint social_release_outbox_approval_check check ((status in ('approved', 'sending', 'sent') and approved_at is not null) or status not in ('approved', 'sending', 'sent')),
  constraint social_release_outbox_message_check check (btrim(message) <> ''),
  constraint social_release_outbox_link_check check (link ~ '^https://')
);

create unique index if not exists social_release_outbox_event_platform_key
  on board_pulse.social_release_outbox (event_key, platform);

create index if not exists social_release_outbox_review_idx
  on board_pulse.social_release_outbox (status, platform, created_at);

alter table board_pulse.social_release_outbox enable row level security;
drop policy if exists "service role manages social release outbox" on board_pulse.social_release_outbox;
create policy "service role manages social release outbox"
  on board_pulse.social_release_outbox for all to service_role using (true) with check (true);
grant select, insert, update, delete on board_pulse.social_release_outbox to service_role;

create table if not exists board_pulse.social_release_audit_logs (
  id uuid primary key default extensions.gen_random_uuid(),
  draft_id uuid not null references board_pulse.social_release_outbox(id) on delete restrict,
  action text not null,
  actor text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint social_release_audit_action_check check (action in ('created', 'approved', 'cancelled', 'sent', 'failed', 'retried'))
);

create index if not exists social_release_audit_draft_idx
  on board_pulse.social_release_audit_logs (draft_id, created_at desc);

alter table board_pulse.social_release_audit_logs enable row level security;
drop policy if exists "service role manages social release audit" on board_pulse.social_release_audit_logs;
create policy "service role manages social release audit"
  on board_pulse.social_release_audit_logs for all to service_role using (true) with check (true);
grant select, insert on board_pulse.social_release_audit_logs to service_role;

create or replace function board_pulse.audit_social_release_creation()
returns trigger
language plpgsql
security definer
set search_path = board_pulse, pg_catalog
as $$
begin
  insert into board_pulse.social_release_audit_logs (draft_id, action, actor, details)
  values (new.id, 'created', coalesce(current_setting('request.jwt.claim.email', true), 'system'),
          jsonb_build_object('event_key', new.event_key, 'platform', new.platform, 'campaign_type', new.campaign_type));
  return new;
end;
$$;

drop trigger if exists social_release_outbox_created_audit on board_pulse.social_release_outbox;
create trigger social_release_outbox_created_audit
after insert on board_pulse.social_release_outbox
for each row execute function board_pulse.audit_social_release_creation();

create or replace function board_pulse.touch_social_release_outbox()
returns trigger
language plpgsql
set search_path = board_pulse, pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists social_release_outbox_updated_at on board_pulse.social_release_outbox;
create trigger social_release_outbox_updated_at
before update on board_pulse.social_release_outbox
for each row execute function board_pulse.touch_social_release_outbox();

notify pgrst, 'reload schema';
