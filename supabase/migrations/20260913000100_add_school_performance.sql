alter table board_pulse.exams
  add column if not exists performance_of_schools_pdf_url text;

create table if not exists board_pulse.school_performance (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references board_pulse.exams(id) on delete cascade,
  school_name text not null,
  examined_count integer,
  passed_count integer,
  passing_percentage numeric,
  rank integer,
  qualification_text text,
  source_row_text text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists school_performance_exam_school_key
  on board_pulse.school_performance (exam_id, school_name);

create index if not exists school_performance_exam_rank_idx
  on board_pulse.school_performance (exam_id, rank);

create index if not exists school_performance_exam_percentage_idx
  on board_pulse.school_performance (exam_id, passing_percentage desc);

alter table board_pulse.school_performance enable row level security;

drop policy if exists "public can read school performance" on board_pulse.school_performance;
create policy "public can read school performance"
  on board_pulse.school_performance for select
  to anon, authenticated
  using (true);

grant select on table board_pulse.school_performance to anon, authenticated, service_role;
grant insert, update, delete on table board_pulse.school_performance to service_role;


