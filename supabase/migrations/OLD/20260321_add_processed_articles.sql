create table if not exists public.processed_articles (
  article_url text primary key,
  exam_slug text,
  run_id uuid,
  processed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_processed_articles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_processed_articles_updated_at on public.processed_articles;
create trigger trg_processed_articles_updated_at
before update on public.processed_articles
for each row
execute function public.touch_processed_articles_updated_at();
