-- Add RLS policies for board_pulse schema tables
-- Per CONTEXT.md decision D-05: Add RLS policies for anon/service_role, authenticated for relevant tables

-- Enable RLS on exams table
alter table board_pulse.exams enable row level security;

-- Exams: Policy for anon role (SELECT)
drop policy if exists "exams_select_anon";
create policy "exams_select_anon"
  on board_pulse.exams for select
  to anon
  using (true);

-- Exams: Policy for authenticated role (SELECT)
drop policy if exists "exams_select_authenticated";
create policy "exams_select_authenticated"
  on board_pulse.exams for select
  to authenticated
  using (true);

-- Exams: Policy for service_role (SELECT)
drop policy if exists "exams_select_service_role";
create policy "exams_select_service_role"
  on board_pulse.exams for select
  to service_role
  using (true);

-- Exams: Policy for authenticated role (INSERT)
drop policy if exists "exams_insert_authenticated";
create policy "exams_insert_authenticated"
  on board_pulse.exams for insert
  to authenticated
  with check (true);

-- Exams: Policy for authenticated role (UPDATE)
drop policy if exists "exams_update_authenticated";
create policy "exams_update_authenticated"
  on board_pulse.exams for update
  to authenticated
  using (true)
  with check (true);

-- Exams: Policy for authenticated role (DELETE)
drop policy if exists "exams_delete_authenticated";
create policy "exams_delete_authenticated"
  on board_pulse.exams for delete
  to authenticated
  using (true);

-- Enable RLS on results table
alter table board_pulse.results enable row level security;

-- Results: Policy for anon role (SELECT)
drop policy if exists "results_select_anon";
create policy "results_select_anon"
  on board_pulse.results for select
  to anon
  using (true);

-- Results: Policy for authenticated role (SELECT)
drop policy if exists "results_select_authenticated";
create policy "results_select_authenticated"
  on board_pulse.results for select
  to authenticated
  using (true);

-- Results: Policy for service_role (SELECT)
drop policy if exists "results_select_service_role";
create policy "results_select_service_role"
  on board_pulse.results for select
  to service_role
  using (true);

-- Results: Policy for authenticated role (INSERT)
drop policy if exists "results_insert_authenticated";
create policy "results_insert_authenticated"
  on board_pulse.results for insert
  to authenticated
  with check (true);

-- Results: Policy for authenticated role (UPDATE)
drop policy if exists "results_update_authenticated";
create policy "results_update_authenticated"
  on board_pulse.results for update
  to authenticated
  using (true)
  with check (true);

-- Results: Policy for authenticated role (DELETE)
drop policy if exists "results_delete_authenticated";
create policy "results_delete_authenticated"
  on board_pulse.results for delete
  to authenticated
  using (true);

-- Enable RLS on top_notchers table
alter table board_pulse.top_notchers enable row level security;

-- Top notchers: Policy for anon role (SELECT)
drop policy if exists "top_notchers_select_anon";
create policy "top_notchers_select_anon"
  on board_pulse.top_notchers for select
  to anon
  using (true);

-- Top notchers: Policy for authenticated role (SELECT)
drop policy if exists "top_notchers_select_authenticated";
create policy "top_notchers_select_authenticated"
  on board_pulse.top_notchers for select
  to authenticated
  using (true);

-- Top notchers: Policy for service_role (SELECT)
drop policy if exists "top_notchers_select_service_role";
create policy "top_notchers_select_service_role"
  on board_pulse.top_notchers for select
  to service_role
  using (true);

-- Top notchers: Policy for authenticated role (INSERT)
drop policy if exists "top_notchers_insert_authenticated";
create policy "top_notchers_insert_authenticated"
  on board_pulse.top_notchers for insert
  to authenticated
  with check (true);

-- Top notchers: Policy for authenticated role (UPDATE)
drop policy if exists "top_notchers_update_authenticated";
create policy "top_notchers_update_authenticated"
  on board_pulse.top_notchers for update
  to authenticated
  using (true)
  with check (true);

-- Top notchers: Policy for authenticated role (DELETE)
drop policy if exists "top_notchers_delete_authenticated";
create policy "top_notchers_delete_authenticated"
  on board_pulse.top_notchers for delete
  to authenticated
  using (true);

-- Grant permissions to roles
grant all on board_pulse.exams to anon, authenticated, service_role;
grant all on board_pulse.results to anon, authenticated, service_role;
grant all on board_pulse.top_notchers to anon, authenticated, service_role;