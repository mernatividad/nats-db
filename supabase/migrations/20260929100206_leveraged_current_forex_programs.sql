-- Leveraged Forex catalog draft from first-party sources captured 2026-09-29.
-- Keep candidate programs in review while official pricing/capacity conflicts are unresolved.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('Leveraged', 'leveraged', 'A simulated trading evaluation provider offering Forex challenge and portfolio manager programs.', 'https://getleveraged.com/', 'published', 'forex', now())
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
    status='published',market_type='forex',published_at=coalesce(bullish_banana.firms.published_at,now()),
    archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='leveraged'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'LC','GetLeveraged Ltd.',array['Forex','Cryptocurrencies','Commodities','Metals','Stocks']::text[],
  '{"service_model":"The firm describes its trading programs as simulated. Leveraged states it is not a broker and program balances are not brokerage deposits.","legal_entity":"GetLeveraged Ltd., Saint Lucia registration 2025-00808. Terms state payments are processed by Leveraged Capital Management LTD, Cyprus.","current_forex_offers":["Leveraged ONE","Turbo - Pay After You Pass","Sprint","Jr. Portfolio Manager","Sr. Portfolio Manager","Exec. Portfolio Manager"],"platforms":"Official checkout exposes MT5 and cTrader as platform options. Per-program combinations have not been fully confirmed.","restricted_jurisdiction_notes":"Official Terms list prohibited territories. Country-level restriction records were not staged because product-specific eligibility and the complete current list need review.","publication_note":"Firm identity and Forex eligibility verified from official product/help pages. Candidate program records remain in review due to source conflicts in pricing and allocation limits."}'::jsonb
from bullish_banana.firms where slug='leveraged'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
    supported_assets=excluded.supported_assets,
    profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at=now();

insert into bullish_banana.programs (
  firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
  max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,
  news_allowed,weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,x.program_type,'forex','in_review','USD',x.sizes::jsonb,
       x.leverage,x.split,x.payout,x.days,x.news,x.weekends,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('Leveraged ONE','leveraged-one','One-phase simulated Forex evaluation with a 6% objective and trailing maximum loss.','evaluation','[10000,25000,50000,100000]',30::numeric,80::numeric,'Every 14 days',3::integer,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":10000,"fee":29,"currency":"USD"},{"account_size":25000,"fee":29,"currency":"USD"},{"account_size":50000,"fee":49,"currency":"USD"},{"account_size":100000,"fee":99,"currency":"USD"}],"price_conflict":"Official checkout variation SKUs on MT5 selected and verified 2026-09-29 displayed 10K $29, 25K $29, 50K $49, 100K $99. Official FAQ states 100K $188. Values are left in review; discount/promotion semantics are not stated.","evaluation_rules":"One phase; 6% target; 3% daily loss; 6% trailing max loss; no time limit.","funded_rules":"80% split; three profitable trading days at 0.5% each; payout every 14 days; 20% consistency condition.","trading_conditions":"Official ONE page lists Forex, crypto, commodities, metals and stocks. FX leverage 1:30. Per-platform offer availability not fully verified.","price_capture":"Official checkout variation SKU confirmed after selection; MT5; captured 2026-09-29."}'),
 ('Turbo - Pay After You Pass','turbo','One-phase simulated Forex evaluation with separate initial and post-pass activation charges.','evaluation','[10000,25000,50000,100000,150000,200000]',30::numeric,80::numeric,'Not stated',null,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":10000,"initial_fee":8.88,"activation_fee":76.12,"currency":"USD"},{"account_size":25000,"initial_fee":8.88,"activation_fee":180.12,"currency":"USD"},{"account_size":50000,"initial_fee":8.88,"activation_fee":340.12,"currency":"USD"},{"account_size":100000,"initial_fee":8.88,"activation_fee":540.12,"currency":"USD"},{"account_size":150000,"initial_fee":8.88,"activation_fee":816.12,"currency":"USD"},{"account_size":200000,"initial_fee":8.88,"activation_fee":1089.12,"currency":"USD"}],"availability":"Official FAQ confirms Forex eligibility; one-time initial charge and activation due within 30 days after passing.","evaluation_rules":"One phase; 6% target; 3% daily loss; 6% trailing maximum loss; no time limit.","funded_rules":"80% split; 20% consistency rule.","pricing_note":"FAQ says the initial charge is credited toward activation, but related wording is ambiguous. Do not calculate an all-in price until confirmed.","allocation_conflict":"Official FAQ and size selector show up to 200K; Terms cap aggregate active Turbo balance at 150K.","promotion_note":"TRYTURBO offer observed on official page; discounted checkout amounts are not included.","platform_note":"Official checkout lists MT5 and cTrader globally; Turbo-specific platform support needs confirmation."}'),
 ('Sprint','sprint','Single-phase simulated Forex evaluation with a 2% objective and static loss limits.','evaluation','[10000,25000,50000,100000]',30::numeric,80::numeric,'First payout instant, then every 14 days',null,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":10000,"fee":49,"currency":"USD"},{"account_size":100000,"fee":439,"currency":"USD"}],"availability":"Official FAQ confirms Forex eligibility. Sizes 10K, 25K, 50K and 100K listed; observed price data covers the 10K starting price and 100K selector example only.","evaluation_rules":"One phase; 2% target; 1% daily loss; 1% static max loss; unlimited time.","funded_rules":"Funded account has 1% daily and 1% static maximum loss; 80% split; first payout is instant, then every 14 days.","pricing_note":"Full 25K/50K price variants not captured; values are not interpolated.","allocation_conflict":"Official product page and maximum allocation FAQ state up to 100K, while Terms state a 10K user maximum.","platform_note":"Official checkout lists MT5 and cTrader globally; Sprint-specific platform support needs confirmation."}'),
 ('Jr. Portfolio Manager','jr-portfolio-manager','Single-phase simulated Forex portfolio manager evaluation with a 10% target.','evaluation','[]'::jsonb,30::numeric,80::numeric,'Not stated',3::integer,null::boolean,null::boolean,
  '{"size_and_pricing":"Product-specific account sizes and fees not stated in the reviewed official sources. Generic Classic family range is not treated as the Jr. product selector matrix.","evaluation_rules":"One phase; 10% target; 3% daily loss; 6% static max loss; unlimited time; three profitable trading days at 0.5% of initial balance.","funded_rules":"80% split; three successful profitable trading days required for payouts.","leverage":"FX leverage 1:30.","allocation_conflict":"Maximum-allocation FAQ and Terms state a 5K Junior maximum; generic Classic FAQ describes a 10K–1M family range. Verify actual Jr. offer sizes before publication."}'),
 ('Sr. Portfolio Manager','sr-portfolio-manager','Two-phase simulated Forex portfolio manager evaluation with 5% and 8% targets.','evaluation','[]'::jsonb,100::numeric,80::numeric,'Not stated',3::integer,null::boolean,null::boolean,
  '{"size_and_pricing":"Product-specific account sizes and fees not stated in the reviewed official sources. Generic Classic family range is not treated as the Sr. product selector matrix.","evaluation_rules":"Two phases with 5% then 8% targets; each phase has 5% daily loss and 10% static max loss; unlimited time; three profitable trading days at 0.5% of initial balance.","funded_rules":"80% split; three successful profitable trading days required for payouts.","leverage":"FX leverage 1:100."}'),
 ('Exec. Portfolio Manager','exec-portfolio-manager','Three-phase simulated Forex portfolio manager evaluation with 6%, 8% and 10% targets.','evaluation','[]'::jsonb,30::numeric,80::numeric,'Not stated',3::integer,null::boolean,null::boolean,
  '{"size_and_pricing":"Product-specific account sizes and fees not stated in the reviewed official sources. Generic Classic family range is not treated as the Executive product selector matrix.","evaluation_rules":"Three phases with 6%, 8% and 10% targets; each phase has 3% daily loss and 6% static max loss; unlimited time; three profitable trading days at 0.5% of initial balance.","funded_rules":"80% split; three successful profitable trading days required for payouts.","leverage":"FX leverage 1:30."}')
) as x(name,slug,description,program_type,sizes,leverage,split,payout,days,news,weekends,details) on true
where f.slug='leveraged'
on conflict (firm_id,slug) do update
set name=excluded.name,description=excluded.description,program_type=excluded.program_type,
    market_type=excluded.market_type,status='in_review',currency=excluded.currency,
    account_sizes=excluded.account_sizes,max_leverage=excluded.max_leverage,
    profit_split_percent=excluded.profit_split_percent,payout_frequency=excluded.payout_frequency,
    minimum_trading_days=excluded.minimum_trading_days,news_allowed=excluded.news_allowed,
    weekend_holding_allowed=excluded.weekend_holding_allowed,commercial_details=excluded.commercial_details,
    published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.program_phases (
  program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
  maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,
       case when x.program_slug in ('leveraged-one','turbo') then 'trailing' else 'static' end,
       null,x.days,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('leveraged-one',1,'Evaluation',6::numeric,3::numeric,6::numeric,null,'{"maximum_drawdown_type":"Trailing","no_time_limit":true,"consistency_percent":20}'),
 ('turbo',1,'Evaluation',6::numeric,3::numeric,6::numeric,null,'{"maximum_drawdown_type":"Trailing","no_time_limit":true,"consistency_percent":20,"activation_due_days":30}'),
 ('sprint',1,'Evaluation',2::numeric,1::numeric,1::numeric,null,'{"maximum_drawdown_type":"Static","no_time_limit":true,"allocation_conflict":"Terms 10K vs official product/FAQ 100K"}'),
 ('jr-portfolio-manager',1,'Evaluation',10::numeric,3::numeric,6::numeric,3::integer,'{"maximum_drawdown_type":"Static","no_time_limit":true,"profitable_day_minimum_percent":0.5,"account_size_conflict":"Verify 5K cap vs generic Classic family size range"}'),
 ('sr-portfolio-manager',1,'Phase 1',5::numeric,5::numeric,10::numeric,3::integer,'{"maximum_drawdown_type":"Static","no_time_limit":true,"profitable_day_minimum_percent":0.5}'),
 ('sr-portfolio-manager',2,'Phase 2',8::numeric,5::numeric,10::numeric,3::integer,'{"maximum_drawdown_type":"Static","no_time_limit":true,"profitable_day_minimum_percent":0.5}'),
 ('exec-portfolio-manager',1,'Phase 1',6::numeric,3::numeric,6::numeric,3::integer,'{"maximum_drawdown_type":"Static","no_time_limit":true,"profitable_day_minimum_percent":0.5}'),
 ('exec-portfolio-manager',2,'Phase 2',8::numeric,3::numeric,6::numeric,3::integer,'{"maximum_drawdown_type":"Static","no_time_limit":true,"profitable_day_minimum_percent":0.5}'),
 ('exec-portfolio-manager',3,'Phase 3',10::numeric,3::numeric,6::numeric,3::integer,'{"maximum_drawdown_type":"Static","no_time_limit":true,"profitable_day_minimum_percent":0.5}')
) as x(program_slug,phase_number,name,target,daily,maximum,days,rules) on x.program_slug=p.slug
where f.slug='leveraged'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
    time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
    raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug) values ('MetaTrader 5','metatrader-5'),('cTrader','ctrader')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://getleveraged.com/','Official homepage','Current firm/product family and marketing details, reviewed 2026-09-29.'),
 ('https://getleveraged.com/terms/','Terms of Use','Legal entity, simulated service, payment processor, territory terms, Turbo/Sprint capacity conflicts.'),
 ('https://getleveraged.com/one/','Leveraged ONE product and FAQ','Forex eligibility, ONE rules, leverage, payout cadence and FAQ pricing.'),
 ('https://getleveraged.com/faq/what-is-the-turbo-program/','Turbo program FAQ','Forex eligibility, evaluation/funded rules, sizes and activation fee matrix.'),
 ('https://getleveraged.com/faq/what-is-the-sprint-program/','Sprint program FAQ','Forex eligibility, targets, loss limits, payout rules and sizes.'),
 ('https://getleveraged.com/sprint/','Sprint product page','Current offer sizes and displayed price examples.'),
 ('https://getleveraged.com/faq/junior-portfolio-manager-program/','Junior Portfolio Manager FAQ','Junior phase and funded rules.'),
 ('https://getleveraged.com/faq/senior-portfolio-manager-program/','Senior Portfolio Manager FAQ','Senior phase and funded rules.'),
 ('https://getleveraged.com/faq/executive-portfolio-manager-program/','Executive Portfolio Manager FAQ','Executive phase and funded rules.'),
 ('https://getleveraged.com/faq/what-is-the-maximum-capital-allocation/','Maximum capital allocation FAQ','Official size/allocation statements that conflict with Terms for Junior, Turbo and Sprint.'),
 ('https://getleveraged.com/faq/leverage/','Leverage FAQ','Track-specific Forex leverage values.')
) as x(url,label,notes) on true where f.slug='leveraged'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,'https://checkout.getleveraged.com/product/leveraged/','Official Leveraged checkout selector',
 'On 2026-09-29 selected Leveraged ONE + MT5. Captured a price only after the SKU matched each selected account size: 10K $29, 25K $29, 50K $49, 100K $99. ONE FAQ separately states 100K $188. Checkout interaction was read-only; no cart action.'
from bullish_banana.firms f where f.slug='leveraged'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url='https://checkout.getleveraged.com/product/leveraged/');

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('leveraged-one','https://getleveraged.com/one/','ONE official rules and FAQ','Forex-eligible; 6% target, 3% daily, 6% trailing max, funded rules and conflicting $100K FAQ price.'),
 ('turbo','https://getleveraged.com/faq/what-is-the-turbo-program/','Turbo rules and fee schedule','Six size/activation-fee pairs; 200K cap conflicts with Terms; initial fee credit language unclear.'),
 ('sprint','https://getleveraged.com/faq/what-is-the-sprint-program/','Sprint rules and size range','2% target and 1% static limits; $10K terms cap conflicts with official $100K product/FAQ capacity.'),
 ('sprint','https://getleveraged.com/sprint/','Sprint offer page and price examples','Official size and price examples; incomplete size-by-size fee matrix.'),
 ('jr-portfolio-manager','https://getleveraged.com/faq/junior-portfolio-manager-program/','Junior program rules','Phase and funded terms; product-specific fee matrix remains unverified.'),
 ('sr-portfolio-manager','https://getleveraged.com/faq/senior-portfolio-manager-program/','Senior program rules','Two-phase and funded terms; product-specific fee matrix remains unverified.'),
 ('exec-portfolio-manager','https://getleveraged.com/faq/executive-portfolio-manager-program/','Executive program rules','Three-phase and funded terms; product-specific fee matrix remains unverified.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='leveraged'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Official homepage, Terms, six Forex product/help pages, maximum-allocation FAQ, leverage FAQ and read-only checkout selector reviewed 2026-09-29. Firm and Forex eligibility confirmed; program records remain in review pending resolution of explicit commercial conflicts and missing track-specific matrices.'
from bullish_banana.firms f where slug='leveraged'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'First-party product/FAQ evidence captured 2026-09-29. Program remains in review: see commercial_details and attached official source records for missing matrix values and/or current Terms conflicts.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='leveraged' and p.slug in ('leveraged-one','turbo','sprint','jr-portfolio-manager','sr-portfolio-manager','exec-portfolio-manager')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);
