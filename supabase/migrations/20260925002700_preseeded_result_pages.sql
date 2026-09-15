-- Schedule-backed result page identities are separate from release-linked exams.
-- A row may be linked to an exams row only after the scraper verifies a PRC release.
create table if not exists board_pulse.preseeded_result_pages (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique,
  name text not null,
  category text not null,
  scheduled_date date not null,
  scheduled_date_label text not null,
  target_release_date date,
  schedule_source_url text not null,
  schedule_source_title text not null,
  schedule_source_checked_at timestamptz not null default now(),
  status text not null default 'scheduled',
  linked_exam_id uuid references board_pulse.exams(id) on delete set null,
  display_in_directory boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint preseeded_result_pages_status_check check (status in ('scheduled', 'released', 'cancelled', 'superseded')),
  constraint preseeded_result_pages_lifecycle_check check (
    (status = 'scheduled' and linked_exam_id is null)
    or (status = 'released' and linked_exam_id is not null)
    or status in ('cancelled', 'superseded')
  ),
  constraint preseeded_result_pages_source_check check (schedule_source_url ~* '^https://([a-z0-9-]+\.)*prc\.gov\.ph/'),
  constraint preseeded_result_pages_slug_check check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint preseeded_result_pages_name_check check (btrim(name) <> ''),
  constraint preseeded_result_pages_category_check check (btrim(category) <> ''),
  constraint preseeded_result_pages_date_label_check check (btrim(scheduled_date_label) <> '')
);

create index if not exists preseeded_result_pages_directory_idx
  on board_pulse.preseeded_result_pages (display_in_directory, scheduled_date desc);

alter table board_pulse.alert_subscriptions
  add column if not exists preseeded_page_id uuid references board_pulse.preseeded_result_pages(id) on delete cascade;
alter table board_pulse.alert_subscriptions
  alter column exam_id drop not null;
alter table board_pulse.alert_subscriptions
  drop constraint if exists alert_subscriptions_owner_check;
alter table board_pulse.alert_subscriptions
  add constraint alert_subscriptions_owner_check check (exam_id is not null or preseeded_page_id is not null);
create index if not exists alert_subscriptions_preseeded_idx
  on board_pulse.alert_subscriptions (preseeded_page_id, alert_type, status);

alter table board_pulse.preseeded_result_pages enable row level security;
drop policy if exists "public can read preseeded result pages" on board_pulse.preseeded_result_pages;
create policy "public can read preseeded result pages"
  on board_pulse.preseeded_result_pages for select to anon, authenticated using (display_in_directory = true);

grant select on board_pulse.preseeded_result_pages to anon, authenticated, service_role;
grant insert, update, delete on board_pulse.preseeded_result_pages to service_role;

create or replace function board_pulse.touch_preseeded_result_page()
returns trigger
language plpgsql
set search_path = board_pulse, pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists preseeded_result_pages_updated_at on board_pulse.preseeded_result_pages;
create trigger preseeded_result_pages_updated_at
before update on board_pulse.preseeded_result_pages
for each row execute function board_pulse.touch_preseeded_result_page();

create or replace function board_pulse.link_preseeded_alerts()
returns trigger
language plpgsql
security definer
set search_path = board_pulse, pg_catalog
as $$
begin
  if new.status = 'released' and new.linked_exam_id is not null then
    update board_pulse.alert_subscriptions
    set exam_id = new.linked_exam_id, preseeded_page_id = null
    where preseeded_page_id = new.id and exam_id is null;
  end if;
  return new;
end;
$$;

drop trigger if exists preseeded_result_pages_link_alerts on board_pulse.preseeded_result_pages;
create trigger preseeded_result_pages_link_alerts
after update of status, linked_exam_id on board_pulse.preseeded_result_pages
for each row execute function board_pulse.link_preseeded_alerts();

notify pgrst, 'reload schema';
