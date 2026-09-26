set search_path = bullish_banana, extensions, public;

alter table bullish_banana.firms
  add column if not exists market_type text not null default 'forex'
  check (market_type in ('forex', 'futures', 'crypto'));

alter table bullish_banana.programs
  add column if not exists market_type text not null default 'forex'
  check (market_type in ('forex', 'futures', 'crypto'));

update bullish_banana.firms
set market_type = 'futures', updated_at = now()
where slug in ('topstep', 'e8-markets');

update bullish_banana.programs
set market_type = 'futures', updated_at = now()
where slug in ('trading-combine', 'e8-one-perpetual');

create index if not exists firms_market_type_status_idx
  on bullish_banana.firms (market_type, status, ranking_score desc, name);

create index if not exists programs_market_type_status_idx
  on bullish_banana.programs (market_type, status, name);
