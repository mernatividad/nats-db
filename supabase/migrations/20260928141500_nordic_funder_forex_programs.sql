set search_path = bullish_banana, extensions, public;

-- Official Nordic Funder FX & CFDs product pages reviewed 2026-09-28.
-- Keep the firm and offers in review: the official terms page is awaiting counsel sign-off
-- and names conflicting assessment providers in separate legal/footer sections.
insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('Nordic Funder','nordic-funder','A simulated Forex and CFD assessment provider offering five fee-based evaluation tracks.','https://nordicfunder.com/','in_review','forex',null)
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
    status='in_review',market_type='forex',published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='nordic-funder'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,null,null,array['Forex','Metals','Indices','Oil','Cryptocurrencies']::text[],
       '{"service_model":"Nordic Funder says assessments are fee-based simulated trading evaluations against aggregated live pricing; passing is not an offer of employment.","contracting_entity":"Unresolved. Current official Terms & Conditions page says Forest Park FX LTD supplies assessments and signs the trader agreement in its first legal section, but later footer copy and current product pages say Prop Account, LLC supplies assessments and Prop Account LC is the trader-agreement counterparty. Terms page itself says awaiting counsel sign-off and operative clauses remain to be migrated.","current_forex_tracks":["One-Step","Two-Step","Three-Step","One-Step Lite","Two-Step Lite"],"platforms":"Official About page lists DXtrade, Match-Trader, and cTrader via GooeyTrade. Program-specific platform eligibility is not stated in the captured product summary.","trading_conditions":"Raw spreads; round-turn commission USD 7 per lot on FX and metals for standard FX tracks; EAs allowed. Weekend holding is an add-on, and the site says only cryptocurrencies trade over weekends.","restricted_jurisdictions":"Complete current firm- and platform-specific country restrictions are not stated in the reviewed public terms. Do not infer a list or turn platform-specific access into a firm-wide restriction.","age_requirement":"Not stated in the captured official pages.","other_offers":"Instant Funding Lite is listed as a separate top-level category. Its product page does not establish Forex-symbol availability in the material reviewed; excluded from the Forex program set pending confirmation.","publication_blockers":["Resolve signed assessment provider and funded trader counterparty from operative client terms.","Obtain complete restriction, dispute, governing-law, closure and prohibited-practice terms.","Confirm product-specific platform, symbols, Forex availability and add-on rules."],"source_note":"Official Nordic Funder pages checked 2026-09-28. Pricing and rules below reflect current marketing page; all rows remain in_review until contract conflicts are resolved."}'::jsonb
from bullish_banana.firms where slug='nordic-funder'
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
select f.id,x.name,x.slug,x.description,'evaluation','forex','in_review','USD',x.sizes::jsonb,
       x.leverage,80,'First withdrawal with no delay; then every 14 days',x.minimum_days,
       null,null,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('One-Step','one-step','Single-phase Forex assessment with a 10% target and 6% trailing maximum drawdown.',
  '[5000,10000,25000,50000,100000,200000,250000,500000]',20::numeric,null::integer,
  '{"account_size_prices":[{"account_size":5000,"fee":42.5,"currency":"USD"},{"account_size":10000,"fee":85,"currency":"USD"},{"account_size":25000,"fee":212.5,"currency":"USD"},{"account_size":50000,"fee":425,"currency":"USD"},{"account_size":100000,"fee":850,"currency":"USD"},{"account_size":200000,"fee":1700,"currency":"USD"},{"account_size":250000,"fee":2125,"currency":"USD"},{"account_size":500000,"fee":4887.5,"currency":"USD"}],"evaluation_rules":"One phase; 10% target; 5% maximum daily loss based on end-of-day balance; 6% trailing maximum drawdown.","funded_rules":"80% standard split; 90% with add-on. First withdrawal has no delay; then 14-day cycle. 30-day inactivity limit.","fee_terms":"One-time; non-refundable; no subscription or recurring charges.","trading_conditions":"Raw spreads; USD 7 round-turn commission per FX or metals lot; EAs allowed. Weekend holding add-on advertised; exact Forex funded conditions need operative terms.","leverage":"20:1 on Forex and metals; 10:1 indices; 5:1 oil; up to 2:1 crypto.","platforms":"DXtrade, Match-Trader and cTrader are listed generally; plan mapping not verified.","review_note":"Marketing page is complete for target/drawdown/prices but current legal terms are awaiting counsel sign-off and state conflicting service counterparties. Confirm trailing HWM/lock mechanic and signed terms before publication.","source_note":"Official FX & CFDs page, captured 2026-09-28."}'),
 ('Two-Step','two-step','Two-phase Forex assessment with 10% and 5% targets and an 8% static maximum drawdown.',
  '[5000,10000,25000,50000,100000,200000,250000,500000]',20::numeric,null::integer,
  '{"account_size_prices":[{"account_size":5000,"fee":60,"currency":"USD"},{"account_size":10000,"fee":110,"currency":"USD"},{"account_size":25000,"fee":250,"currency":"USD"},{"account_size":50000,"fee":345,"currency":"USD"},{"account_size":100000,"fee":525,"currency":"USD"},{"account_size":200000,"fee":1000,"currency":"USD"},{"account_size":250000,"fee":1225,"currency":"USD"},{"account_size":500000,"fee":2760,"currency":"USD"}],"evaluation_rules":"Phase 1 target 10%; Phase 2 target 5%; both phases share an 8% static maximum drawdown and 4% daily loss based on end-of-day balance.","funded_rules":"80% standard split; 90% with add-on. First withdrawal has no delay; then 14-day cycle. 30-day inactivity limit.","fee_terms":"One-time; non-refundable; no subscription or recurring charges.","trading_conditions":"Raw spreads; USD 7 round-turn commission per FX or metals lot; EAs allowed. Weekend holding add-on advertised; exact Forex funded conditions need operative terms.","leverage":"20:1 on Forex and metals; 10:1 indices; 5:1 oil; up to 2:1 crypto.","platforms":"DXtrade, Match-Trader and cTrader are listed generally; plan mapping not verified.","review_note":"Official marketing rules/prices captured. Verify end-of-day calculation, trading-day/inactivity terms and signed legal agreement before publication.","source_note":"Official FX & CFDs page, captured 2026-09-28."}'),
 ('Three-Step','three-step','Three-phase Forex assessment with a 5% target at each phase and a 5% static maximum drawdown.',
  '[5000,10000,25000,50000,100000,200000,250000,500000]',20::numeric,null::integer,
  '{"account_size_prices":[{"account_size":5000,"fee":42,"currency":"USD"},{"account_size":10000,"fee":77,"currency":"USD"},{"account_size":25000,"fee":175,"currency":"USD"},{"account_size":50000,"fee":241.5,"currency":"USD"},{"account_size":100000,"fee":367.5,"currency":"USD"},{"account_size":200000,"fee":700,"currency":"USD"},{"account_size":250000,"fee":857.5,"currency":"USD"},{"account_size":500000,"fee":1932,"currency":"USD"}],"evaluation_rules":"Three phases; 5% target per phase; 5% static maximum drawdown and 5% daily loss based on end-of-day balance.","funded_rules":"80% standard split; 90% with add-on. First withdrawal has no delay; then 14-day cycle. 30-day inactivity limit.","fee_terms":"One-time; non-refundable; no subscription or recurring charges.","trading_conditions":"Raw spreads; USD 7 round-turn commission per FX or metals lot; EAs allowed. Weekend holding add-on advertised; exact Forex funded conditions need operative terms.","leverage":"20:1 on Forex and metals; 10:1 indices; 5:1 oil; up to 2:1 crypto.","platforms":"DXtrade, Match-Trader and cTrader are listed generally; plan mapping not verified.","review_note":"Official marketing rules/prices captured. Confirm signed legal agreement and drawdown reset mechanics before publication.","source_note":"Official FX & CFDs page, captured 2026-09-28."}'),
 ('One-Step Lite','one-step-lite','Single-phase lower-size Forex assessment with 10% target, 5% static maximum loss and funded consistency limits.',
  '[2500,5000,10000,25000,50000,100000]',30::numeric,3::integer,
  '{"account_size_prices":[{"account_size":2500,"fee":25,"currency":"USD"},{"account_size":5000,"fee":45,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":215,"currency":"USD"},{"account_size":50000,"fee":400,"currency":"USD"},{"account_size":100000,"fee":750,"currency":"USD"}],"evaluation_rules":"One phase; 10% target; 2.5% intraday trailing daily loss; 5% static maximum drawdown; no evaluation consistency rule. Site lists three profitable trading days of at least 1%; exact stage application should be confirmed.","funded_rules":"80% standard split; 90% with add-on; 50% funded consistency; first withdrawal no delay then every 14 days.","minimum_day_rule":"At least 3 profitable days of 1%; applicability per evaluation/funded stage needs confirmation.","fee_terms":"One-time and non-refundable.","trading_conditions":"Raw spreads; EAs allowed. Commission not stated in the track table. Weekend holding add-on advertised; exact FX funded conditions need operative terms.","leverage":"30:1; 60:1 with Double Leverage add-on.","platforms":"DXtrade, Match-Trader and cTrader are listed generally; plan mapping not verified.","review_note":"Official marketing page provides full sizes/fees and headline rules. Verify intraday-loss calculation, profitable-day stage, signed legal terms and full restrictions before publication.","source_note":"Official FX & CFDs page, captured 2026-09-28."}'),
 ('Two-Step Lite','two-step-lite','Two-phase lower-size Forex assessment with 12% and 6% targets, 6% static maximum loss and funded consistency limits.',
  '[2500,5000,10000,25000,50000,100000]',100::numeric,3::integer,
  '{"account_size_prices":[{"account_size":2500,"fee":25,"currency":"USD"},{"account_size":5000,"fee":45,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":185,"currency":"USD"},{"account_size":50000,"fee":350,"currency":"USD"},{"account_size":100000,"fee":600,"currency":"USD"}],"evaluation_rules":"Phase 1 target 12%; Phase 2 target 6%; 3% intraday trailing daily loss; 6% static maximum drawdown; no evaluation consistency rule. Site lists three profitable trading days of at least 1%; exact stage application should be confirmed.","funded_rules":"80% standard split; 90% with add-on; 50% funded consistency; first withdrawal no delay then every 14 days.","minimum_day_rule":"At least 3 profitable days of 1%; applicability per evaluation phase or total needs confirmation.","fee_terms":"One-time and non-refundable.","trading_conditions":"Raw spreads; EAs allowed. Commission not stated in the track table. Weekend holding add-on advertised; exact Forex funded conditions need operative terms.","leverage":"100:1; 200:1 with Double Leverage add-on.","platforms":"DXtrade, Match-Trader and cTrader are listed generally; plan mapping not verified.","review_note":"Official marketing page provides full sizes/fees and headline rules. Verify intraday-loss calculation, profitable-day stage, signed legal terms and full restrictions before publication.","source_note":"Official FX & CFDs page, captured 2026-09-28."}')
) as x(name,slug,description,sizes,leverage,minimum_days,details) on true
where f.slug='nordic-funder'
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
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,x.drawdown_type,null,x.minimum_days,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-step',1,'Evaluation',10::numeric,5::numeric,6::numeric,'trailing',null::integer,'{"daily_limit_basis":"End-of-day balance; exact reset time and calculation are not stated in the captured page.","max_drawdown_mechanic":"Trailing; high-water mark and lock mechanics need operative-term verification."}'),
 ('two-step',1,'Phase 1',10::numeric,4::numeric,8::numeric,'static',null::integer,'{"daily_limit_basis":"End-of-day balance; exact reset time and calculation are not stated in the captured page."}'),
 ('two-step',2,'Phase 2',5::numeric,4::numeric,8::numeric,'static',null::integer,'{"daily_limit_basis":"End-of-day balance; exact reset time and calculation are not stated in the captured page."}'),
 ('three-step',1,'Phase 1',5::numeric,5::numeric,5::numeric,'static',null::integer,'{"daily_limit_basis":"End-of-day balance; exact reset time and calculation are not stated in the captured page."}'),
 ('three-step',2,'Phase 2',5::numeric,5::numeric,5::numeric,'static',null::integer,'{"daily_limit_basis":"End-of-day balance; exact reset time and calculation are not stated in the captured page."}'),
 ('three-step',3,'Phase 3',5::numeric,5::numeric,5::numeric,'static',null::integer,'{"daily_limit_basis":"End-of-day balance; exact reset time and calculation are not stated in the captured page."}'),
 ('one-step-lite',1,'Evaluation',10::numeric,2.5::numeric,5::numeric,'static',null::integer,'{"daily_limit_basis":"Intraday trailing; exact reference balance/equity and reset mechanics are not stated in the captured page.","profitable_day_rule":"Three profitable days of at least 1%; exact phase applicability needs confirmation.","funded_consistency_percent":50}'),
 ('two-step-lite',1,'Phase 1',12::numeric,3::numeric,6::numeric,'static',null::integer,'{"daily_limit_basis":"Intraday trailing; exact reference balance/equity and reset mechanics are not stated in the captured page.","profitable_day_rule":"Three profitable days of at least 1%; exact phase applicability needs confirmation.","funded_consistency_percent":50}'),
 ('two-step-lite',2,'Phase 2',6::numeric,3::numeric,6::numeric,'static',null::integer,'{"daily_limit_basis":"Intraday trailing; exact reference balance/equity and reset mechanics are not stated in the captured page.","profitable_day_rule":"Three profitable days of at least 1%; exact phase applicability needs confirmation.","funded_consistency_percent":50}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,minimum_days,rules) on x.program_slug=p.slug
where f.slug='nordic-funder'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
    time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
    raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes
from bullish_banana.firms f
join (values
 ('https://nordicfunder.com/','Official homepage and current configurator','Current offer selector, firm-wide disclosures, platform choices and legal footer; reviewed 2026-09-28.'),
 ('https://nordicfunder.com/programs/fx-cfd/','FX & CFDs programs, fees and rules','Official current five Forex track matrix, full account-size/base-fee schedules, marketing rules and stated conditions.'),
 ('https://www.nordicfunder.com/how-it-works/','How it works: FX track overview','One/two/three-step and Lite targets, drawdowns, daily loss, payout and no-time-limit overview.'),
 ('https://nordicfunder.com/about/','About and platform information','Simulated assessments, aggregated pricing, DXtrade, Match-Trader, cTrader via GooeyTrade and public legal relationship statement.'),
 ('https://nordicfunder.com/legal/terms/','Terms & Conditions - awaiting counsel sign-off','The page states operative clauses remain incomplete and contains conflicting Forest Park FX LTD vs Prop Account, LLC assessment-provider/counterparty statements.'),
 ('https://www.nordicfunder.com/faq/','Official FAQ','Rules, platform and payout FAQ; used as secondary clarification, not substituted for the current signed agreement.')
) as x(url,label,notes) on true
where f.slug='nordic-funder'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-step','https://nordicfunder.com/programs/fx-cfd/','One-Step price and rules source','Official fee matrix and One-Step target, drawdown, daily loss, inactivity, leverage, costs and trading conditions.'),
 ('two-step','https://nordicfunder.com/programs/fx-cfd/','Two-Step price and rules source','Official fee matrix and Two-Step target, drawdown, daily loss, inactivity, leverage, costs and trading conditions.'),
 ('three-step','https://nordicfunder.com/programs/fx-cfd/','Three-Step price and rules source','Official fee matrix and Three-Step target, drawdown, daily loss, inactivity, leverage, costs and trading conditions.'),
 ('one-step-lite','https://nordicfunder.com/programs/fx-cfd/','One-Step Lite price and rules source','Official fee matrix and Lite target, drawdown, profitable-day, funded consistency, leverage and trading conditions.'),
 ('two-step-lite','https://nordicfunder.com/programs/fx-cfd/','Two-Step Lite price and rules source','Official fee matrix and Lite phase targets, drawdown, profitable-day, funded consistency, leverage and trading conditions.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='nordic-funder'
and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);
