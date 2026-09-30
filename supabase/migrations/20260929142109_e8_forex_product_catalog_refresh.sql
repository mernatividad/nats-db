-- Correct E8's market membership and add its current Forex SimFi challenge offers.
-- First-party Help Center, price and platform pages reviewed 2026-09-29.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set name='E8 Markets',
    description='A simulated trading provider offering single-phase Forex challenges through its E8 One, E8 Pro and E8 Signature programs.',
    website_url='https://e8markets.com/',status='published',market_type='forex',
    published_at=coalesce(published_at,now()),updated_at=now()
where slug='e8-markets';

insert into bullish_banana.firm_markets (firm_id,market_type)
select f.id,m.market_type from bullish_banana.firms f
cross join (values ('forex'),('futures'),('crypto')) as m(market_type)
where f.slug='e8-markets'
on conflict (firm_id,market_type) do nothing;

-- E8 One Perpetual is the HyperLiquid perpetual-futures product, not E8 One Forex.
update bullish_banana.programs
set market_type='futures',
    description='A one-step perpetual-futures challenge using E8 Markets’ HyperLiquid feed.',
    updated_at=now()
where firm_id=(select id from bullish_banana.firms where slug='e8-markets')
  and slug='e8-one-perpetual';

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,null,null,array['Forex','Metals','Energies','Indices','Crypto','Stocks']::text[],
  '{"service_model":"E8 describes its SimFi accounts as simulated accounts; capital is not live market capital.","legal_entity_note":"A current legal operator name and incorporation jurisdiction were not stated on the first-party product and Help Center pages reviewed for this record.","platforms":["TradeLocker","MatchTrader","cTrader","MetaTrader 5"],"assets_note":"Forex product instruments include Forex, metals, energies, indices and crypto. Exact instruments, commissions and pricing vary by product, account and platform.","market_memberships":["Classic Markets (includes Forex)","Futures","Perpetual Futures"],"jurisdiction_notes":"US customers cannot purchase/use MT5 or cTrader; TradeLocker and MatchTrader are listed for US users. The accepted-countries page additionally identifies product restrictions for certain countries and E8 One allocation caps for India, Vietnam, Kenya and Indonesia. Profile lists these conditions in prose; program-specific country eligibility must be checked against the current official list.","current_forex_programs":["E8 One Forex","E8 Pro Forex","E8 Signature Forex"],"verification_note":"Official Help Center instruments, platform, accepted-country and program articles reviewed 2026-09-29. E8 One baseline fee table and preset drawdown documentation contain a configuration discrepancy; E8 One remains in_review."}'::jsonb
from bullish_banana.firms where slug='e8-markets'
on conflict (firm_id) do update
set country_code=coalesce(excluded.country_code,bullish_banana.firm_profiles.country_code),
    legal_entity_name=coalesce(excluded.legal_entity_name,bullish_banana.firm_profiles.legal_entity_name),
    supported_assets=excluded.supported_assets,
    profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at=now();

insert into bullish_banana.programs (
  firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
  max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,
  news_allowed,weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,'evaluation','forex',x.status,'USD',x.sizes::jsonb,
  30,x.split,x.payout,null,true,x.weekends,x.details::jsonb,
  case when x.status='published' then now() else null end,null
from bullish_banana.firms f
join (values
  ('E8 One Forex','e8-one-forex','One-phase Forex SimFi challenge with configurable profit targets and drawdown options.','in_review','[5000,10000,25000,50000,100000,200000,400000,500000]',80::numeric,'On-demand after payout-on-demand requirements',null::boolean,
   '{"account_size_prices":[{"account_size":5000,"fee":48,"currency":"USD"},{"account_size":10000,"fee":88,"currency":"USD"},{"account_size":25000,"fee":188,"currency":"USD"},{"account_size":50000,"fee":288,"currency":"USD"},{"account_size":100000,"fee":488,"currency":"USD"},{"account_size":200000,"fee":798,"currency":"USD"},{"account_size":400000,"fee":1598,"currency":"USD"},{"account_size":500000,"fee":1998,"currency":"USD"}],"price_configuration":"Official Custom Account article labels these no-discount prices as the standard E8 One checkout configuration: 80% payout, 6% dynamic drawdown and 4% daily drawdown. The E8 One rules article instead labels 6% target, 3% daily drawdown and 4% dynamic drawdown as preset. Prices vary by drawdown, payout and platform; this configuration conflict must be resolved before publishing a single canonical price/rule combination.","challenge_rules":"Official E8 One Forex rules state 6% profit target, 3% daily drawdown from the starting balance of the day, 4% dynamic drawdown based on highest closed balance, no time limit, and at least one opened and closed trade every 60 days. Custom account choices can change the drawdown and target.","performance_rules":"Up to 100% performance payout depending on selected plan; 40% best-day rule. 3% daily drawdown and 4% dynamic drawdown continue in performance. First payout may be available after three performance-stage days when requirements are met. Payout minimum is $100; a buffer may be needed after payouts.","trading_conditions":"News allowed in challenge; performance high-impact news trading prohibited from five minutes before until five minutes after release. Weekend/overnight holding and EAs allowed. Copy trading is allowed only between accounts personally owned by the same trader. Forex leverage 1:30.","platforms_and_region":"TradeLocker, MatchTrader, cTrader and MT5 are listed for Classic Markets. US users cannot use cTrader or MT5. E8 One is unavailable in Bulgaria, Laos, Romania, Bangladesh, Cambodia, Croatia and Taiwan; account size is capped at $200,000 for users verified in India, Vietnam, Kenya and Indonesia.","commission_details":"Forex account may be configured with raw spread or no-commission pricing; exact variant charges are configuration-dependent. cTrader adds $10 when account price is below $100.","open_fields":"Exact active-account rules vary by selected parameters; fee/rule configuration conflict is recorded and status remains in_review."}'),
  ('E8 Pro Forex','e8-pro-forex','One-phase Forex SimFi challenge with static drawdown and daily performance payouts.','published','[5000,10000,25000,50000,100000,150000,200000,400000,500000]',80::numeric,'Daily after at least 1% profit since the prior payout',true,
   '{"account_size_prices":[{"account_size":5000,"fee":32,"currency":"USD"},{"account_size":10000,"fee":68,"currency":"USD"},{"account_size":25000,"fee":148,"currency":"USD"},{"account_size":50000,"fee":228,"currency":"USD"},{"account_size":100000,"fee":488,"currency":"USD"},{"account_size":200000,"fee":998,"currency":"USD"},{"account_size":400000,"fee":2098,"currency":"USD"},{"account_size":500000,"fee":2598,"currency":"USD"}],"unpriced_account_sizes":[150000],"fee_note":"The official base price table does not state a $150K fee although E8 Pro parameters list that account size. All listed prices are no-discount standard configurations at 80% payout, 8% static drawdown and 2.5% daily drawdown; pricing changes with selected parameters/platform. cTrader adds $10 for accounts priced below $100.","challenge_rules":"8% profit target; no time limit but open and close at least one trade every 60 days; daily profit cap of 2% of initial balance counts toward target; 2.5% hard daily drawdown from initial balance; 8% static max drawdown. No consistency rule.","performance_rules":"Daily payout requests after a minimum 1% profit since previous payout; no payout caps or consistency rule. Each payout request allocates 50% of generated profit to the requestable amount and retains 50% in the account as drawdown buffer; selected payout share (80%-100%) applies to the requestable half. First payout moves static drawdown to initial balance.","trading_conditions":"News trading allowed in Challenge and Performance. Weekend/overnight holding and EAs allowed. Copy trading allowed only across accounts owned by the same trader. Forex leverage 1:30.","platforms_and_region":"TradeLocker, MatchTrader, cTrader and MT5 are listed for Classic Markets. US users cannot purchase/use cTrader or MT5; TradeLocker and MatchTrader are listed for US users.","commission_details":"Forex accounts may be configured for raw spread or no-commission pricing; exact charges depend on selection.","minimum_payout":"$100 overall payment minimum; payout-specific E8 Pro rule requires at least 1% profit between requests."}'),
  ('E8 Signature Forex','e8-signature-forex','One-phase Forex SimFi challenge with end-of-day dynamic loss limits and capped performance payouts.','published','[25000,50000,100000,150000]',80::numeric,'On-demand after payout-on-demand requirements',false,
   '{"account_size_prices":[{"account_size":25000,"fee":110,"currency":"USD"},{"account_size":50000,"fee":150,"currency":"USD"},{"account_size":100000,"fee":260,"currency":"USD"},{"account_size":150000,"fee":390,"currency":"USD"}],"fee_note":"Official no-discount preset price table; 80% payout. Custom account prices may vary.","challenge_rules":"6% profit target; EOD dynamic drawdown based on highest end-of-day balance, recalculated once at market close and locking at initial balance. EOD loss limits by size: $1,000/$2,000/$3,000/$4,500 for $25K/$50K/$100K/$150K. No time limit but at least one opened and closed trade every 60 days.","performance_rules":"80% payout share; 2% soft daily pause; same EOD dynamic limits; 35% best-day rule; first payout earliest after three performance-stage days when requirements are met; $100 minimum payment. Five profitable days between payout requests after the first, each day >=0.3% realized closed PnL. Keep a buffer equal to the EOD drawdown. Payout caps per account size and payout number are listed below.","payout_caps":[{"account_size":25000,"buffer":1000,"requests":[1000,1000,1250,1250,1500]},{"account_size":50000,"buffer":2000,"requests":[1250,1250,2250,2250,3250]},{"account_size":100000,"buffer":3000,"requests":[2250,2250,3250,3250,4250]},{"account_size":150000,"buffer":4500,"requests":[3250,3250,4250,4250,5250]}],"maximum_payout_count_note":"The payout-cap article says a maximum of five payouts applies only to E8 Signature Futures accounts purchased after 2026-07-14; no maximum payout count is stated for the Forex variant.","trading_conditions":"News allowed. Positions close at 23:00 server time and trading resumes 00:15; weekend holding is not allowed. EAs allowed on Classic Markets. Copy trading is allowed across accounts personally owned by the same trader. Forex leverage 1:30.","platforms_and_region":"TradeLocker, MatchTrader, cTrader and MT5 are listed for Classic Markets. US users cannot use cTrader or MT5.","commission_details":"Forex accounts may be configured with raw spread or no-commission pricing; exact charges depend on selection."}')
) as x(name,slug,description,status,sizes,split,payout,weekends,details) on true
where f.slug='e8-markets'
on conflict (firm_id,slug) do update
set name=excluded.name,description=excluded.description,program_type=excluded.program_type,
 market_type=excluded.market_type,status=excluded.status,currency=excluded.currency,
 account_sizes=excluded.account_sizes,max_leverage=excluded.max_leverage,
 profit_split_percent=excluded.profit_split_percent,payout_frequency=excluded.payout_frequency,
 minimum_trading_days=excluded.minimum_trading_days,news_allowed=excluded.news_allowed,
 weekend_holding_allowed=excluded.weekend_holding_allowed,
 commercial_details=bullish_banana.programs.commercial_details || excluded.commercial_details,
 published_at=case when excluded.status='published' then coalesce(bullish_banana.programs.published_at,now()) else null end,
 archived_at=null,updated_at=now();

insert into bullish_banana.program_phases (
  program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
  maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,1,x.phase_name,x.target,x.daily,x.maximum,x.drawdown,null,null,x.rules::jsonb
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
join (values
  ('e8-one-forex','SimFi Challenge',6::numeric,3::numeric,4::numeric,'dynamic','{"day_requirement_label":"No time limit; one trade must be opened and closed every 60 days","drawdown_reference":"Dynamic loss limit follows highest closed balance and locks at initial balance","preset_conflict":"Custom Account fee table baseline differs from E8 One rules article; program remains in_review until exact price/rule SKU is reconciled."}'),
  ('e8-pro-forex','SimFi Challenge',8::numeric,2.5::numeric,8::numeric,'static','{"day_requirement_label":"No time limit; one trade must be opened and closed every 60 days","daily_profit_cap_percent":2,"daily_profit_cap_reference":"2% of initial balance per server day counts toward target","drawdown_reference":"Daily loss from initial balance; static max loss moves to initial balance after first payout."}'),
  ('e8-signature-forex','SimFi Challenge',6::numeric,null::numeric,null::numeric,'dynamic','{"day_requirement_label":"No time limit; one trade must be opened and closed every 60 days","drawdown_reference":"End-of-day dynamic loss based on the highest end-of-day balance; locks at initial balance","drawdown_by_account_size":[{"account_size":25000,"max_loss":1000},{"account_size":50000,"max_loss":2000},{"account_size":100000,"max_loss":3000},{"account_size":150000,"max_loss":4500}],"performance_daily_pause_percent":2}')
) as x(program_slug,phase_name,target,daily,maximum,drawdown,rules) on x.program_slug=p.slug
where f.slug='e8-markets'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=excluded.daily_drawdown_percent,
 maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
 time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
 raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug) values
 ('TradeLocker','tradelocker'),('MatchTrader','matchtrader'),('cTrader','ctrader'),('MetaTrader 5','metatrader-5'),('HyperLiquid','hyperliquid')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select p.id,pl.id from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join bullish_banana.platforms pl on pl.slug in ('tradelocker','matchtrader','ctrader','metatrader-5')
where f.slug='e8-markets' and p.slug in ('e8-one-forex','e8-pro-forex','e8-signature-forex')
on conflict (program_id,platform_id) do nothing;

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,s.url,s.label,s.notes from bullish_banana.firms f join (values
 ('https://e8markets.com/','E8 Markets official site','Official provider site checked 2026-09-29 for Classic Markets, Futures and Perpetual Futures market categories and product discovery.'),
 ('https://help.e8markets.com/en/articles/5514977-what-instruments-are-allowed-to-be-traded-spreads','E8 Markets instruments and commissions','Current official article identifies supported Forex product instruments and says instruments/commissions vary by product, account and platform.'),
 ('https://help.e8markets.com/en/articles/9799834-available-trading-platforms','E8 Markets trading platforms','Current platform list for Classic Markets: TradeLocker, MatchTrader, cTrader and MT5, varying by region/account; US users cannot use cTrader or MT5.'),
 ('https://help.e8markets.com/en/articles/5514278-accepted-countries','E8 Markets accepted countries and allocations','Current Help Center article lists E8 One country restrictions and allocation limits for certain verified countries.'),
 ('https://help.e8markets.com/en/articles/8880316-what-is-the-custom-account','E8 Markets configurable accounts and preset prices','Current official price matrix for E8 One, E8 Pro and E8 Signature; describes one-time fees, account customization, platform fee and a discrepancy between E8 One base pricing configuration and its rules article.'),
 ('https://help.e8markets.com/en/articles/13106558-all-product-overviews-e8-one-vs-e8-zero-vs-e8-pro-vs-e8-signature','Current E8 product overview','Current first-party overview describes E8 One, Pro, Signature and Zero market availability and summarizes program rule differences.')
) as s(url,label,notes) on true where f.slug='e8-markets'
and not exists(select 1 from bullish_banana.sources existing where existing.firm_id=f.id and existing.source_url=s.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,s.url,s.label,s.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('e8-one-forex','https://help.e8markets.com/en/articles/11775980-e8-one','E8 One current rules','Current first-party E8 One challenge and performance rules, customization, target, drawdown, activity, payout, news and copy-trading policy.'),
 ('e8-one-forex','https://help.e8markets.com/en/articles/9323884-payout-request-on-e8-one','E8 One payout mechanics','Current E8 One payout request requirements and buffer details.'),
 ('e8-pro-forex','https://help.e8markets.com/en/articles/15274219-e8-pro','E8 Pro current rules','Current first-party E8 Pro challenge/performance rules, 8% target, daily cap, static/daily drawdown, payouts, news, leverage and copy rules.'),
 ('e8-pro-forex','https://help.e8markets.com/en/articles/13653464-payout-request-from-e8-pro','E8 Pro payout mechanics','Current payout mechanism, daily requests, 1% threshold, selected payout share and 50% retained buffer.'),
 ('e8-signature-forex','https://help.e8markets.com/en/articles/11755943-e8-signature-forex','E8 Signature Forex rules','Current official account sizes, challenge limits, funded daily pause, 35% best day, payout conditions, news, activity, weekend and platform-independent leverage.'),
 ('e8-signature-forex','https://help.e8markets.com/en/articles/11940573-payout-caps-and-buffers-for-e8-signature-explained','E8 Signature payout caps and buffers','Current per-size payout cap and buffer tables; source notes that account maximum payout count condition applies to futures accounts purchased after a stated date, not assumed for Forex.'),
 ('e8-signature-forex','https://help.e8markets.com/en/articles/11865587-35-best-day-rule','E8 Signature best-day rule','Current 35% best-day requirement for Signature performance accounts.'),
 ('e8-one-forex','https://help.e8markets.com/en/articles/15272556-everything-about-payouts-when-how-how-fast','E8 payout timing and processors','Current help article describes payout timing, earliest practical first payout, $100 processor minimum and median processing times.')
) as s(program_slug,url,label,notes) on s.program_slug=p.slug
where f.slug='e8-markets'
and not exists(select 1 from bullish_banana.sources existing where existing.program_id=p.id and existing.source_url=s.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'Reviewed current E8 Markets instruments, market taxonomy, platforms, accepted-country/allocations, product overview and pricing pages 2026-09-29. Firm has Forex, Futures and Crypto/Perpetual product coverage. Product-specific legal operator and full country matrix remain unstated in the reviewed sources.'
from bullish_banana.firms f where f.slug='e8-markets'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

update bullish_banana.data_verifications
set verified_at=now(),notes='Reviewed current E8 Markets instruments, market taxonomy, platforms, accepted-country/allocations, product overview and pricing pages 2026-09-29. Firm has Forex, Futures and Crypto/Perpetual product coverage. Product-specific legal operator and full country matrix remain unstated in the reviewed sources.'
where firm_id=(select id from bullish_banana.firms where slug='e8-markets');

update bullish_banana.data_verifications
set verified_at=now(),notes='E8 One Perpetual is classified as Futures, distinct from the Classic Markets Forex version of E8 One. Current E8 instruments and market categories reviewed 2026-09-29.'
where program_id=(select id from bullish_banana.programs where slug='e8-one-perpetual');

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('e8-one-forex','Current E8 One rules and pricing reviewed 2026-09-29. Fee matrix is the official no-discount baseline; fee table and rules article describe different preset drawdown configurations. Keep in_review pending source/checkout reconciliation.'),
 ('e8-pro-forex','Current E8 Pro Forex rules, standard size/price matrix, payout mechanics and platform policy reviewed 2026-09-29.'),
 ('e8-signature-forex','Current E8 Signature Forex rules, fee matrix, payout conditions/caps, platform and trading restrictions reviewed 2026-09-29.')
) as x(program_slug,notes) on x.program_slug=p.slug
where f.slug='e8-markets'
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);

update bullish_banana.data_verifications v
set verified_at=now(),notes=x.notes
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('e8-one-forex','Current E8 One rules and pricing reviewed 2026-09-29. Fee matrix is the official no-discount baseline; fee table and rules article describe different preset drawdown configurations. Keep in_review pending source/checkout reconciliation.'),
 ('e8-pro-forex','Current E8 Pro Forex rules, standard size/price matrix, payout mechanics and platform policy reviewed 2026-09-29.'),
 ('e8-signature-forex','Current E8 Signature Forex rules, fee matrix, payout conditions/caps, platform and trading restrictions reviewed 2026-09-29.')
) as x(program_slug,notes) on x.program_slug=p.slug
where f.slug='e8-markets' and v.program_id=p.id;

insert into bullish_banana.affiliate_destinations (firm_id,program_id,kind,label,destination_url,is_primary,status)
select f.id,p.id,'official_site','Visit '||p.name,s.url,true,'active'
from bullish_banana.firms f join bullish_banana.programs p on p.firm_id=f.id
join (values
 ('e8-one-forex','https://e8markets.com/e8-one'),
 ('e8-pro-forex','https://help.e8markets.com/en/articles/15274219-e8-pro'),
 ('e8-signature-forex','https://help.e8markets.com/en/articles/11755943-e8-signature-forex')
) as s(program_slug,url) on s.program_slug=p.slug
where f.slug='e8-markets'
and not exists(select 1 from bullish_banana.affiliate_destinations d where d.program_id=p.id and d.kind='official_site');
