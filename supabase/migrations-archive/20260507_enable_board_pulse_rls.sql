-- Enable RLS on board_pulse tables exposed through PostgREST.
-- Public-facing exam data remains readable; scraper state remains private.

alter table board_pulse.exams enable row level security;
alter table board_pulse.results enable row level security;
alter table board_pulse.top_notchers enable row level security;
alter table board_pulse.processed_articles enable row level security;

drop policy if exists "public can read exams" on board_pulse.exams;
create policy "public can read exams"
  on board_pulse.exams for select
  to anon, authenticated
  using (true);

drop policy if exists "public can read results" on board_pulse.results;
create policy "public can read results"
  on board_pulse.results for select
  to anon, authenticated
  using (true);

drop policy if exists "public can read top notchers" on board_pulse.top_notchers;
create policy "public can read top notchers"
  on board_pulse.top_notchers for select
  to anon, authenticated
  using (true);

notify pgrst, 'reload schema';
