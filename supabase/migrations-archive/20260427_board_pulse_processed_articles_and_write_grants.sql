-- Create processed_articles table in board_pulse schema
-- Mirrors the public.processed_articles structure (OLD migration) but in board_pulse.
-- Also grants write permissions that the scraper service_role key needs.

create table if not exists board_pulse.processed_articles (
  article_url text primary key,
  exam_slug text,
  run_id uuid,
  processed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function board_pulse.touch_processed_articles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_processed_articles_updated_at on board_pulse.processed_articles;
create trigger trg_processed_articles_updated_at
before update on board_pulse.processed_articles
for each row
execute function board_pulse.touch_processed_articles_updated_at();

-- Grant write permissions to service_role for scraper ingest operations.
-- (The 20260428 migration only granted SELECT.)
grant insert, update, delete on board_pulse.exams to service_role;
grant insert, update, delete on board_pulse.results to service_role;
grant insert, update, delete on board_pulse.top_notchers to service_role;
grant select, insert, update, delete on board_pulse.processed_articles to service_role;
