set search_path = bullish_banana, extensions, public;

-- Current Fintokei USD offer families and rules reviewed 2026-09-28.
-- Keep all staged records in review while localized products, symbol-level conditions,
-- and full eligibility/terms detail receive a final verification pass.
insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('Fintokei','fintokei','A simulated trading evaluation and education company offering multi-phase and one-phase Forex CFD programs.','https://www.fintokei.com/','in_review','forex',null)
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
    status='in_review',market_type='forex',published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='fintokei'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'CZ','Fintokei a.s.',
       array['Forex','Metals','Energies','Indices','Cryptocurrencies']::text[],
       '{"company_id":"09110127","registered_office":"Masarykova 409/26, Brno-město, 602 00 Brno, Czech Republic","service_model":"Trading education and evaluation company. Customer accounts are simulated virtual accounts using market quotes; Fintokei says it does not accept customer deposits or execute customer trades in the real market.","platforms":["TradingView","MetaTrader 5","cTrader"],"supported_instruments":"FX pairs and CFD metals, energies, indices and cryptocurrencies. Official FAQ says no futures or stock trading. Individual symbols have different leverage, spreads, commissions, order-size limits and hours; consult official symbols page.","programs":["StartTrader","SwiftTrader","ProTrader","ProTrader Swing"],"restricted_countries_note":"The official list is dynamic. The current product page refers users to the updated list and names India, Russia, Belarus and North Korea among restricted jurisdictions. Confirm current list before publication.","product_variant_note":"ProTrader Slim was added in July 2026 for Japan-accessed/Japanese-language customers, JPY accounts only, MT5 only, with `z` suffixed symbols and 500 JPY round-turn commission. Its full account size and fee matrix is not staged.","source_note":"Official Programs catalog, StartTrader page, instruments FAQ, product FAQs, and Terms were reviewed 2026-09-28."}'::jsonb
from bullish_banana.firms where slug='fintokei'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
    supported_assets=excluded.supported_assets,
    profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at=now();

insert into bullish_banana.programs (
  firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
  profit_split_percent,payout_frequency,minimum_trading_days,news_allowed,
  weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,'evaluation','forex','in_review','USD',x.sizes::jsonb,
       x.split,x.payout,x.minimum_days,true,true,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('StartTrader','fintokei-starttrader','Three-phase simulated Forex CFD evaluation with 2%, 3%, and 6% targets. Current official USD fees range from $44 to $419.','[5000,20000,50000,100000]',null::numeric,'Every 14 days',3::integer,
  '{"fee_currency":"USD","base_fees_by_account_size":{"5000":44,"20000":119,"50000":244,"100000":419},"evaluation_rules":"Three phases. Targets: 2%, 3%, 6%. Daily loss 3% (equity-based); maximum loss 6%. Each phase requires at least 3 trading days and has a 180-day maximum. Maximum daily profit is 40% of each phase target. Virtually funded account daily-profit cap: 1% of initial balance per day.","funded_rules":"Performance reward ratio shown as 50-100%; exact conditions vary and require review. Standard withdrawals at least 14 days apart / after first trade. Account requires at least one trade in any 30-day period to remain active.","instruments":"FX pairs plus CFD metals, energies, indices and cryptocurrencies. No futures or stocks.","platforms":["TradingView","MetaTrader 5","cTrader"],"leverage":"Official product page: 1:25 FX, Gold and Silver; 1:20 indices; 1:10 other instruments. Verify per-symbol matrix.","news_weekend_eas":"Homepage advertises news trading, weekend holding and EAs as allowed; consult product-specific terms and prohibited-strategy rules.","payout":"On-demand request subject to 14-day interval, KYC, minimum thresholds and payout-method availability; instant Walletory option requires separate onboarding.","source_note":"Official Programs and StartTrader pages, StartTrader rules FAQ, instruments FAQ and payout FAQ reviewed 2026-09-28."}'),
 ('SwiftTrader','fintokei-swifttrader','One-phase simulated Forex CFD evaluation with a 6% target and a minimum-profit threshold for every payout.','[5000,10000,20000,50000,100000,200000]',90::numeric,'Every 14 days',3::integer,
  '{"fee_currency":"USD","base_fees_by_account_size":{"5000":44,"10000":89,"20000":144,"50000":299,"100000":499,"200000":1099},"evaluation_rules":"One phase with 6% target; minimum 3 trading days, maximum 60 days; daily loss 2%; maximum loss 3%; maximum risk on open trades 3%.","funded_rules":"For accounts purchased after 2026-07-15, performance reward ratio is 90%. Each withdrawal requires at least 3% profit from initial balance (amount varies by size). Legacy purchases may have different conditions.","instruments":"FX pairs plus CFD metals, energies, indices and cryptocurrencies. No futures or stocks.","platforms":["TradingView","MetaTrader 5","cTrader"],"payout":"At least 14 days from the previous successful withdrawal or first trade, plus the 3% minimum profit per payout; KYC and payout-method conditions apply.","news_weekend_eas":"Homepage advertises news trading, weekend holding and EAs as allowed; confirm restrictions in current product terms.","source_note":"Official Programs catalog, SwiftTrader FAQ, SwiftTrader payout-ratio FAQ, instruments FAQ and payout FAQ reviewed 2026-09-28."}'),
 ('ProTrader','fintokei-protrader','Two-phase simulated Forex CFD evaluation with 8% and 6% targets and equity-based daily loss calculations.','[5000,10000,20000,50000,100000,200000,400000]',80::numeric,'Every 14 days',3::integer,
  '{"fee_currency":"USD","base_fees_by_account_size":{"5000":49,"10000":99,"20000":159,"50000":329,"100000":549,"200000":1249,"400000":2599},"evaluation_rules":"Two phases with 8% then 6% targets. Daily loss 5%, calculated from end-of-day equity; maximum loss 10%. At least 3 trading days per phase; no maximum time limit. Open-trade risk and consistency restrictions also apply.","funded_rules":"Initial performance reward ratio 80%. Standard payout interval at least 14 days, subject to KYC, thresholds and payout method. At least one trade every 30 days to remain active.","instruments":"FX pairs plus CFD metals, energies, indices and cryptocurrencies. No futures or stocks.","platforms":["TradingView","MetaTrader 5","cTrader"],"leverage":"Consult instrument-level official symbols matrix; limits vary by symbol.","news_weekend_eas":"Homepage advertises news trading, weekend holding and EAs as allowed, subject to prohibited strategies and any symbol/market restrictions.","source_note":"Official Programs catalog, ProTrader rules FAQ, ProTrader account FAQ, instruments FAQ and payout FAQ reviewed 2026-09-28."}'),
 ('ProTrader Swing','fintokei-protrader-swing','Two-phase simulated Forex CFD evaluation with 8% and 6% targets and balance-based daily loss calculations.','[5000,10000,20000,50000,100000,200000]',80::numeric,'Every 14 days',3::integer,
  '{"fee_currency":"USD","base_fees_by_account_size":{"5000":69,"10000":119,"20000":199,"50000":419,"100000":679,"200000":1499},"evaluation_rules":"Two phases with 8% then 6% targets. Daily loss 5%, calculated from end-of-day balance; maximum loss 10%. At least 3 trading days per phase; no maximum time limit. Maximum risk on open trades is 3%.","funded_rules":"Initial performance reward ratio 80%. Accounts purchased from 2026-07-15 onward are swap-free (no swap charged or credited). Standard payout interval at least 14 days, subject to KYC, thresholds and payout method. At least one trade every 30 days to remain active.","instruments":"FX pairs plus CFD metals, energies, indices and cryptocurrencies. No futures or stocks.","platforms":["TradingView","MetaTrader 5","cTrader"],"leverage":"Consult instrument-level official symbols matrix; limits vary by symbol.","news_weekend_eas":"Homepage advertises news trading, weekend holding and EAs as allowed, subject to prohibited strategies and any symbol/market restrictions.","source_note":"Official Programs catalog, ProTrader Swing rule/difference FAQs, instruments FAQ and payout FAQ reviewed 2026-09-28."}')
) as x(name,slug,description,sizes,split,payout,minimum_days,details) on true
where f.slug='fintokei'
on conflict (firm_id,slug) do update
set name=excluded.name,description=excluded.description,program_type=excluded.program_type,
    market_type=excluded.market_type,status='in_review',currency=excluded.currency,
    account_sizes=excluded.account_sizes,profit_split_percent=excluded.profit_split_percent,
    payout_frequency=excluded.payout_frequency,minimum_trading_days=excluded.minimum_trading_days,
    news_allowed=excluded.news_allowed,weekend_holding_allowed=excluded.weekend_holding_allowed,
    commercial_details=excluded.commercial_details,published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.program_phases (
  program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
  maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,x.drawdown_type,x.time_limit,x.minimum_days,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('fintokei-starttrader',1,'Challenge Phase 1',2::numeric,3::numeric,6::numeric,'static',180::integer,3::integer,'{"daily_loss_basis":"Equity-based.","consistency_cap_percent":40,"consistency_basis":"Maximum share of phase profit target from a single day.","minimum_trading_days":"At least 3 trading days; a day counts when at least one trade is opened."}'),
 ('fintokei-starttrader',2,'Challenge Phase 2',3::numeric,3::numeric,6::numeric,'static',180::integer,3::integer,'{"daily_loss_basis":"Equity-based.","consistency_cap_percent":40,"consistency_basis":"Maximum share of phase profit target from a single day."}'),
 ('fintokei-starttrader',3,'Challenge Phase 3',6::numeric,3::numeric,6::numeric,'static',180::integer,3::integer,'{"daily_loss_basis":"Equity-based.","consistency_cap_percent":40,"consistency_basis":"Maximum share of phase profit target from a single day."}'),
 ('fintokei-swifttrader',1,'Challenge Phase',6::numeric,2::numeric,3::numeric,'static',60::integer,3::integer,'{"daily_loss_basis":"See current program rules for reset calculation.","maximum_open_trade_risk_percent":3,"minimum_profit_per_payout_percent":3,"minimum_profit_per_payout_basis":"Initial account balance; applicable to every funded payout."}'),
 ('fintokei-protrader',1,'Challenge Phase 1',8::numeric,5::numeric,10::numeric,'static',null::integer,3::integer,'{"daily_loss_basis":"End-of-day equity.","minimum_profitable_days":3,"open_trade_risk":"Additional maximum risk on open trades rule applies."}'),
 ('fintokei-protrader',2,'Challenge Phase 2',6::numeric,5::numeric,10::numeric,'static',null::integer,3::integer,'{"daily_loss_basis":"End-of-day equity.","minimum_profitable_days":3,"open_trade_risk":"Additional maximum risk on open trades rule applies."}'),
 ('fintokei-protrader-swing',1,'Challenge Phase 1',8::numeric,5::numeric,10::numeric,'static',null::integer,3::integer,'{"daily_loss_basis":"End-of-day balance; breach monitoring is based on account equity.","maximum_open_trade_risk_percent":3,"minimum_trading_days":3}'),
 ('fintokei-protrader-swing',2,'Challenge Phase 2',6::numeric,5::numeric,10::numeric,'static',null::integer,3::integer,'{"daily_loss_basis":"End-of-day balance; breach monitoring is based on account equity.","maximum_open_trade_risk_percent":3,"minimum_trading_days":3}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,time_limit,minimum_days,rules) on x.program_slug=p.slug
where f.slug='fintokei'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
    time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
    raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f
join (values
 ('https://www.fintokei.com/programs','Official program catalog','Current USD account sizes, base one-time fees and high-level rules for the four standard Forex program families.'),
 ('https://www.fintokei.com/starttrader','Official StartTrader product page','Company identity, simulated account disclosure, listed product/asset support, platform choices, and published leverage examples.'),
 ('https://www.fintokei.com/symbols','Official instrument matrix','Per-symbol trading conditions including leverage, spread, commission, order-size limits and trading hours; check again at publication.'),
 ('https://support.fintokei.com/en/articles/6538848-what-instruments-can-i-trade','Official instruments FAQ','FX/CFD asset support for all four program families and confirmation that stocks/futures are not offered.'),
 ('https://support.fintokei.com/en/articles/9579997-how-does-starttrader-challenge-work-what-are-the-rules','StartTrader rules FAQ','Phase targets, loss limits, consistency, time limit, minimum days and activity conditions.'),
 ('https://support.fintokei.com/en/articles/6538822-how-does-the-protrader-challenge-work-what-are-the-rules','ProTrader challenge rules FAQ','Two phase targets, daily/maximum losses, minimum days and activity conditions.'),
 ('https://support.fintokei.com/en/articles/12058210-what-is-the-difference-between-protrader-and-protrader-swing','ProTrader vs Swing rules FAQ','EOD equity vs balance loss calculation and swap-free purchase date for Swing.'),
 ('https://support.fintokei.com/en/articles/8408932-what-is-swifttrader-program','SwiftTrader product FAQ','One phase, 6% target and current-purchase rules.'),
 ('https://support.fintokei.com/en/articles/8408430-what-is-the-performance-reward-ratio-on-swifttrader-accounts','SwiftTrader payout ratio FAQ','90% ratio for eligible post-2026-07-15 purchases and minimum profit per payout by size/currency.'),
 ('https://support.fintokei.com/en/articles/6538884-how-and-how-often-can-i-withdraw-my-performance-rewards-and-what-is-the-minimum-amount','Official payout FAQ','Payout interval, minimum amount, KYC, payout methods and fees.'),
 ('https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim','ProTrader Slim FAQ','Japan-only JPY variant, plans, platform, symbols and commission; full fee matrix still needs capture.'),
 ('https://support.fintokei.com/en/articles/8408938-what-is-the-difference-between-protrader-starttrader-and-swifttrader','Program structure FAQ','Confirms distinct number of evaluation phases for StartTrader, ProTrader and SwiftTrader.')
) as x(url,label,notes) on true
where f.slug='fintokei'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('fintokei-starttrader','https://www.fintokei.com/programs','StartTrader official catalog pricing','USD sizes $5K/$20K/$50K/$100K; fees $44/$119/$244/$419.'),
 ('fintokei-starttrader','https://support.fintokei.com/en/articles/9579997-how-does-starttrader-challenge-work-what-are-the-rules','StartTrader challenge rules','Three-phase target, drawdown, consistency and time-limit rules.'),
 ('fintokei-swifttrader','https://www.fintokei.com/programs','SwiftTrader official catalog pricing','USD sizes $5K/$10K/$20K/$50K/$100K/$200K; fees $44/$89/$144/$299/$499/$1,099.'),
 ('fintokei-swifttrader','https://support.fintokei.com/en/articles/8408932-what-is-swifttrader-program','SwiftTrader current evaluation rules','One phase and current target; account purchase date affects reward ratio.'),
 ('fintokei-swifttrader','https://support.fintokei.com/en/articles/8408430-what-is-the-performance-reward-ratio-on-swifttrader-accounts','SwiftTrader payout conditions','Current 90% performance ratio and minimum payout profit thresholds.'),
 ('fintokei-protrader','https://www.fintokei.com/programs','ProTrader official catalog pricing','USD sizes $5K/$10K/$20K/$50K/$100K/$200K/$400K; fees $49/$99/$159/$329/$549/$1,249/$2,599.'),
 ('fintokei-protrader','https://support.fintokei.com/en/articles/6538822-how-does-the-protrader-challenge-work-what-are-the-rules','ProTrader challenge rules','Two-phase targets, drawdown and minimum trading days.'),
 ('fintokei-protrader','https://support.fintokei.com/en/articles/12058210-what-is-the-difference-between-protrader-and-protrader-swing','ProTrader daily loss calculation','EOD equity-based daily loss limit.'),
 ('fintokei-protrader-swing','https://www.fintokei.com/programs','ProTrader Swing official catalog pricing','USD sizes $5K/$10K/$20K/$50K/$100K/$200K; fees $69/$119/$199/$419/$679/$1,499.'),
 ('fintokei-protrader-swing','https://support.fintokei.com/en/articles/12058210-what-is-the-difference-between-protrader-and-protrader-swing','ProTrader Swing loss calculation and swap condition','EOD balance-based daily loss; swap-free for purchases from 2026-07-15.'),
 ('fintokei-protrader-swing','https://support.fintokei.com/en/articles/6538822-how-does-the-protrader-challenge-work-what-are-the-rules','ProTrader Swing challenge rules','Shared two-phase 8%/6% targets, 5% daily and 10% max drawdown, minimum days.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='fintokei'
and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);
