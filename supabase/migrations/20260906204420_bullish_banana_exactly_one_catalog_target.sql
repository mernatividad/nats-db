alter table bullish_banana.sources
  add constraint sources_exactly_one_target_check
  check ((firm_id is not null) <> (program_id is not null));

alter table bullish_banana.data_verifications
  add constraint data_verifications_exactly_one_target_check
  check ((firm_id is not null) <> (program_id is not null));

alter table bullish_banana.data_reports
  add constraint data_reports_exactly_one_target_check
  check ((firm_id is not null) <> (program_id is not null));
