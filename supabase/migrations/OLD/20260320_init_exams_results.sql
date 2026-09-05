create extension if not exists pgcrypto;

create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  category text not null,
  scheduled_date date not null,
  results_released_at timestamptz null,
  created_at timestamptz not null default now()
);

create table if not exists public.results (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  full_name text not null,
  school text not null default '',
  rating numeric null,
  remarks text not null,
  rank integer null
);

create unique index if not exists results_exam_full_name_school_key
  on public.results (exam_id, full_name, school);
