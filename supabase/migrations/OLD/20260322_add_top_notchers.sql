create table if not exists public.top_notchers (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  rank integer not null,
  full_name text not null,
  school text not null default '',
  rating numeric null,
  created_at timestamptz not null default now()
);

create unique index if not exists top_notchers_exam_rank_key
  on public.top_notchers (exam_id, rank);

create unique index if not exists top_notchers_exam_full_name_key
  on public.top_notchers (exam_id, full_name);
