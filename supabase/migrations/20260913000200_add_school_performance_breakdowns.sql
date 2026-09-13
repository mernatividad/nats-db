alter table board_pulse.school_performance
  add column if not exists first_timers_passed_count integer,
  add column if not exists first_timers_failed_count integer,
  add column if not exists first_timers_conditioned_count integer,
  add column if not exists first_timers_total_count integer,
  add column if not exists first_timers_passing_percentage numeric,
  add column if not exists repeaters_passed_count integer,
  add column if not exists repeaters_failed_count integer,
  add column if not exists repeaters_conditioned_count integer,
  add column if not exists repeaters_total_count integer,
  add column if not exists repeaters_passing_percentage numeric,
  add column if not exists overall_failed_count integer,
  add column if not exists overall_conditioned_count integer;
