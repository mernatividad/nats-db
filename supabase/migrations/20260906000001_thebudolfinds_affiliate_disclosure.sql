alter table thebudolfinds.affiliate_clicks
  add column if not exists disclosure_shown boolean not null default false;
