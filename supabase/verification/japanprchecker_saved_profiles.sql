begin;

select plan(8);

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, email_confirmed_at)
values
  ('00000000-0000-4000-8000-000000000011', 'authenticated', 'authenticated', 'rls-one@example.test', '{}'::jsonb, '{}'::jsonb, now(), now(), now()),
  ('00000000-0000-4000-8000-000000000022', 'authenticated', 'authenticated', 'rls-two@example.test', '{}'::jsonb, '{}'::jsonb, now(), now(), now());

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000011', true);
select is((select count(*)::integer from japanprchecker.pr_profiles), 0, 'user one starts with no profile');

insert into japanprchecker.pr_profiles (id, user_id)
values ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000011');
select is((select count(*)::integer from japanprchecker.pr_profiles), 1, 'user one can create own profile');

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000022', true);
select is((select count(*)::integer from japanprchecker.pr_profiles), 0, 'user two cannot read user one profile');
select throws_ok(
  $$insert into japanprchecker.pr_profiles (user_id) values ('00000000-0000-4000-8000-000000000011')$$,
  '42501', null, 'user two cannot create user one profile'
);

insert into japanprchecker.pr_profiles (id, user_id)
values ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000022');
select ok(japanprchecker.save_pr_profile_snapshot(1, '2027-01-01', array['hsp-test'], array['isa-test'], '{}'::jsonb, '{"resultFamily":"cannot_determine"}'::jsonb) is not null, 'authenticated user can save through the transaction function');

set local role postgres;
select is((select count(*)::integer from japanprchecker.pr_profile_snapshots where user_id = '00000000-0000-4000-8000-000000000022'), 1, 'transaction function creates one immutable snapshot');
select is((select count(*)::integer from japanprchecker.pr_assessment_runs where user_id = '00000000-0000-4000-8000-000000000022'), 1, 'transaction function stores the recomputed assessment');

select * from finish();
rollback;
