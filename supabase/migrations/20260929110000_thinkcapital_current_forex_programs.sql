-- ThinkCapital current Forex catalog candidates; public selectors captured 2026-09-28.
-- Keep all models in review: current marketing/FAQ selectors conflict with agreement text for key terms.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('ThinkCapital', 'thinkcapital', 'A broker-backed simulated trading provider offering Forex evaluations and instant funding.', 'https://www.thinkcapital.com/', 'published', 'forex', now())
on conflict (slug) do update
set name=excluded.name, description=excluded.description, website_url=excluded.website_url,
    status='published', market_type='forex', published_at=coalesce(bullish_banana.firms.published_at,now()),
    archived_at=null, updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='thinkcapital'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'GB','TFG (PAYMENTS) LIMITED',array['Forex','Commodities','Indices','Cryptocurrencies']::text[],
  '{"service_model":"ThinkCapital states its challenges and Bolt account use simulated/demo trading and that it does not act as a broker or accept deposits.","legal_entity":"Current Terms identify TFG (PAYMENTS) LIMITED as the ThinkCapital service provider, registered office 85 Great Portland Street, First Floor, London W1W 7LT, England.","broker_relationship":"The firm markets itself as broker-backed by ThinkMarkets. Platform services/instruments are subject to separate provider terms.","platforms":"Official platform FAQ names ThinkTrader, including its TradingView integration. Terms add platform-specific constraints for US clients.","current_forex_offers":["Lightning One-Step","Dual Step Intraday","Dual Step Swing","Nexus Three-Step","Bolt Instant Funding"],"restricted_jurisdiction_notes":"Official eligibility FAQ lists restricted countries and separately restricts Malaysia, Pakistan, Cambodia and Indonesia to Bolt only. British Columbia is also named as a region. Apply account-type eligibility per program, not as a firm-wide country ban.","source_conflict":"Official marketing selectors/rules conflict with Demo Agreement values for important challenge targets and drawdown definitions; all models stay in review pending reconciliation with the governing Trader Account Agreement."}'::jsonb
from bullish_banana.firms where slug='thinkcapital'
on conflict (firm_id) do update
set country_code=excluded.country_code, legal_entity_name=excluded.legal_entity_name,
    supported_assets=excluded.supported_assets,
    profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at=now();

insert into bullish_banana.programs (
  firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
  max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,
  news_allowed,weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,x.program_type,'forex','in_review','USD',x.sizes::jsonb,
       x.leverage,x.split,x.payout,x.days::integer,x.news,x.weekends,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('Lightning','lightning','Single-phase Forex evaluation with a 10% target and trailing maximum loss.','evaluation','[5000,10000,25000,50000,100000]',30::numeric,80::numeric,'Every 14 days; 7 days with add-on',null,false,true,'{"account_size_prices":[{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":299,"currency":"USD"},{"account_size":100000,"fee":499,"currency":"USD"}],"availability":"Current official selector; Lightning One-Step.","phase_rules":"Web page/selector: 10% target; 3% balance-based daily loss; 6% trailing max, locks at initial balance after 6% account growth.","funded_rules":"Official selector: 3 funded profitable days; news requires add-on; weekend holding allowed; 80% split with up to 90% via add-on/scaling.","eligibility_note":"Malaysia, Pakistan, Cambodia and Indonesia are Bolt-only under current eligibility FAQ.","agreement_conflict":"Official Demo Agreement displays 10% target and 6% trailing max, but says Lightning max loss/daily calculation differently than current product FAQ. Verify the governing account agreement before publication.","pricing_capture":"USD base selector prices, no coupon, captured 2026-09-28.","source_note":"Official Lightning page, FAQ and Demo Agreement; captured 2026-09-28."}'),
 ('Dual Step Intraday','dual-step-intraday','Two-phase evaluation for intraday traders with equity-based daily loss and restrictions on news and weekend trading.','evaluation','[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Every 14 days; 7 days with add-on',null,false,false,'{"account_size_prices":[{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":299,"currency":"USD"},{"account_size":100000,"fee":499,"currency":"USD"}],"availability":"Current official selector; Dual Step Intraday.","phase_rules":"Current marketing and selector: Phase 1 9%, Phase 2 5%; 4% equity-based daily loss; max loss 7% challenge / 8% funded.","funded_rules":"News and weekend holding/trading not allowed; 80% split, with 90% add-on/scaling; 3 minimum profitable days apply to funded payouts.","eligibility_note":"Malaysia, Pakistan, Cambodia and Indonesia are Bolt-only under current eligibility FAQ.","agreement_conflict":"Official Demo Agreement describes Dual Step Phase 1 as 8% rather than the current 9% selector value. It also reports a different max-loss basis for this model. Do not publish until the operative account agreement and selector are reconciled.","pricing_capture":"USD base selector prices, no coupon, captured 2026-09-28.","source_note":"Official Dual Step page, program FAQ, News FAQ, eligibility FAQ and Demo Agreement; captured 2026-09-28."}'),
 ('Dual Step Swing','dual-step-swing','Two-phase evaluation for swing traders with balance-based daily loss and default news and weekend flexibility.','evaluation','[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Every 14 days; 7 days with add-on',null,true,true,'{"account_size_prices":[{"account_size":5000,"fee":82,"currency":"USD"},{"account_size":10000,"fee":138,"currency":"USD"},{"account_size":25000,"fee":278,"currency":"USD"},{"account_size":50000,"fee":418,"currency":"USD"},{"account_size":100000,"fee":698,"currency":"USD"}],"availability":"Current official selector; Dual Step Swing.","phase_rules":"Current marketing and selector: Phase 1 9%, Phase 2 5%; 4% balance-based daily loss; max loss 7% challenge / 8% funded.","funded_rules":"News and weekend trading/holding allowed; 80% split, with 90% add-on/scaling; 3 minimum profitable days apply to funded payouts.","eligibility_note":"Malaysia, Pakistan, Cambodia and Indonesia are Bolt-only under current eligibility FAQ.","agreement_conflict":"Official Demo Agreement describes Dual Step Phase 1 as 8% rather than the current 9% selector value, and an 8% max loss during challenge rather than selector''s 7%. The legal/current account-specific rule must be reconciled before publication.","pricing_capture":"USD base selector prices, no coupon, captured 2026-09-28.","source_note":"Official Dual Step page, program FAQ, eligibility FAQ and Demo Agreement; captured 2026-09-28."}'),
 ('Nexus','nexus','Three-phase Forex evaluation with 7%, 6% and 5% targets and fixed maximum loss.','evaluation','[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Every 14 days; 7 days with add-on',null,false,true,'{"account_size_prices":[{"account_size":5000,"fee":39,"currency":"USD"},{"account_size":10000,"fee":79,"currency":"USD"},{"account_size":25000,"fee":139,"currency":"USD"},{"account_size":50000,"fee":199,"currency":"USD"},{"account_size":100000,"fee":349,"currency":"USD"}],"availability":"Current official selector and Nexus page.","phase_rules":"Current page: targets 7%, 6%, 5%; 4% balance-based daily loss; 8% fixed max loss.","funded_rules":"3 minimum profitable days before payout; news add-on required; weekend and EA trading allowed; 80% split up to 90% with add-on/scaling.","eligibility_note":"Malaysia, Pakistan, Cambodia and Indonesia are Bolt-only under current eligibility FAQ.","agreement_conflict":"The Demo Agreement has a separate rules table and may conflict with current page descriptions; verify governing account agreement before publication.","pricing_capture":"USD base selector prices, no coupon, captured 2026-09-28.","source_note":"Official Nexus page, eligibility FAQ, payout/minimum-day FAQs and Demo Agreement; captured 2026-09-28."}'),
 ('BOLT Instant Funding','bolt-instant-funding','Direct-access simulated Forex account without an evaluation phase.','instant_funding','[2500,5000,10000,25000,50000]',50::numeric,80::numeric,'Every 14 days',null,false,false,'{"account_size_prices":[{"account_size":2500,"fee":49,"currency":"USD"},{"account_size":5000,"fee":89,"currency":"USD"},{"account_size":10000,"fee":159,"currency":"USD"},{"account_size":25000,"fee":349,"currency":"USD"},{"account_size":50000,"fee":599,"currency":"USD"}],"availability":"Current BOLT instant funding page; no evaluation phase.","daily_drawdown":"3% equity-based","maximum_drawdown":"6% trailing equity; published FAQ and page differ on the exact lock condition.","payout_rules":"14-day cycle; at least 5 profitable days are required per payout interval; standard split 80%, up to 90% through scaling/add-ons; no monthly cap advertised.","news_weekend":"Not allowed by default.","consistency_rule":"Selector lists a 20% best-day cap; reconcile the account agreement and current funded FAQ before publication.","market_scope":"Forex, commodities and indices; cryptocurrency is not available on Bolt.","eligibility_note":"Bolt is the only program available to residents of Malaysia, Pakistan, Cambodia and Indonesia under current eligibility FAQ.","agreement_conflict":"Confirm lock timing, best-day rule, payout cycle and scaling against the current Bolt schedule and account agreement.","pricing_capture":"USD base selector prices, no coupon, captured 2026-09-28.","source_note":"Official BOLT page, platform FAQ, eligibility FAQ and Terms; captured 2026-09-28."}')
) as x(name,slug,description,program_type,sizes,leverage,split,payout,days,news,weekends,details) on true
where f.slug='thinkcapital'
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
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,x.kind,null,null,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('lightning',1,'Phase 1',10::numeric,3::numeric,6::numeric,'trailing','{"drawdown_basis":"Balance-based per Lightning program FAQ. It trails and locks at initial balance after 6% growth.","terms_note":"Confirm current reset/lock mechanics against governing account agreement."}'),
 ('dual-step-intraday',1,'Phase 1',9::numeric,4::numeric,7::numeric,'static','{"daily_drawdown_basis":"Equity-based.","funded_max_drawdown_percent":8,"terms_conflict":"Demo Agreement lists an 8% phase-1 target rather than the current selector''s 9%. Hold for reconciliation."}'),
 ('dual-step-intraday',2,'Phase 2',5::numeric,4::numeric,7::numeric,'static','{"daily_drawdown_basis":"Equity-based.","funded_max_drawdown_percent":8,"terms_conflict":"Demo Agreement lists an 8% phase-1 target rather than the current selector''s 9%. Hold for reconciliation."}'),
 ('dual-step-swing',1,'Phase 1',9::numeric,4::numeric,7::numeric,'static','{"daily_drawdown_basis":"Balance-based.","funded_max_drawdown_percent":8,"terms_conflict":"Demo Agreement lists 8% phase-1 target and 8% challenge max loss; current selector says 9% and 7%. Hold for reconciliation."}'),
 ('dual-step-swing',2,'Phase 2',5::numeric,4::numeric,7::numeric,'static','{"daily_drawdown_basis":"Balance-based.","funded_max_drawdown_percent":8,"terms_conflict":"Demo Agreement lists 8% phase-1 target and 8% challenge max loss; current selector says 9% and 7%. Hold for reconciliation."}'),
 ('nexus',1,'Phase 1',7::numeric,4::numeric,8::numeric,'static','{"daily_drawdown_basis":"Balance-based.","source_note":"Current Nexus selector and product page, captured 2026-09-28."}'),
 ('nexus',2,'Phase 2',6::numeric,4::numeric,8::numeric,'static','{"daily_drawdown_basis":"Balance-based","source_note":"Current Nexus selector and product page, captured 2026-09-28."}'),
 ('nexus',3,'Phase 3',5::numeric,4::numeric,8::numeric,'static','{"daily_drawdown_basis":"Balance-based","source_note":"Current Nexus selector and product page, captured 2026-09-28."}')
) as x(program_slug,phase_number,name,target,daily,maximum,kind,rules) on x.program_slug=p.slug
where f.slug='thinkcapital'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
    time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
    raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug) values
 ('ThinkTrader','thinktrader'),('TradingView','tradingview')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select p.id,pl.id from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id and f.slug='thinkcapital'
cross join bullish_banana.platforms pl
where p.slug in ('lightning','dual-step-intraday','dual-step-swing','nexus','bolt-instant-funding')
and pl.slug in ('thinktrader','tradingview')
on conflict do nothing;

insert into bullish_banana.restrictions (firm_id,country_code,restriction_type,note)
select f.id,x.code,'restricted','ThinkCapital current eligibility FAQ, captured 2026-09-28; see profile for regional limitations and account-type eligibility.'
from bullish_banana.firms f
cross join (values ('AF'),('AL'),('AU'),('MM'),('BI'),('CF'),('CU'),('CY'),('IR'),('XK'),('LB'),('LY'),('ML'),('KP'),('CG'),('WS'),('SO'),('SD'),('SY'),('VA'),('YE'),('ZM'),('UA'),('RU'),('VN'),('VE')) as x(code)
where f.slug='thinkcapital'
on conflict (firm_id,country_code) do update set restriction_type=excluded.restriction_type,note=excluded.note,updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://www.thinkcapital.com/','Official Homepage','Firm service disclosure, current product selector, markets and general company information.'),
 ('https://www.thinkcapital.com/lightning/','Lightning program page','Current Lightning size/fee selector, objectives, trading terms and funded rules.'),
 ('https://www.thinkcapital.com/dual-step/','Dual Step program page','Current Intraday/Swing model selector, size/fee matrix and current offer terms.'),
 ('https://www.thinkcapital.com/nexus/','Nexus program page','Current three-phase offer, sizes, fees and model rules.'),
 ('https://www.thinkcapital.com/instant-funding/','BOLT Instant Funding page','Current Bolt sizes, fee selector, instant funding rules and payouts.'),
 ('https://www.thinkcapital.com/terms-of-services/','Terms of Service','Current named service provider, simulated service and contract/legal conditions.'),
 ('https://www.thinkcapital.com/demo-agreement/','Demo Agreement','Agreement source contains different Dual Step objective/max-loss values from current program pages; this conflict blocks program publication.'),
 ('https://www.thinkcapital.com/tc-faqs/general-faqs/what-trading-platforms-does-thinkcapital-offer-and-what-instruments-can-i-trade-there/','Platform and instruments FAQ','Names ThinkTrader and TradingView integration; identifies markets and Bolt crypto exclusion.'),
 ('https://www.thinkcapital.com/tc-faqs/general-faqs/client-eligibility-and-restricted-countries/','Client eligibility and restricted countries','Current country restrictions and regional account-type availability.'),
 ('https://www.thinkcapital.com/tc-faqs/funded-accounts/news-trading-policy-rule-and-restriction/','News trading policy','Model-specific major-news restriction and add-on conditions.'),
 ('https://www.thinkcapital.com/tc-faqs/general-faqs/am-i-allowed-to-hold-trades-overnight-and-over-the-weekend/','Overnight/weekend holding FAQ','Model-specific weekend holding permissions and close deadline.'),
 ('https://www.thinkcapital.com/tc-faqs/general-faqs/how-does-the-minimum-profitable-trading-days-rule-work/','Minimum profitable days FAQ','Distinguishes funded payout profitable-day requirements from challenge requirements and Bolt days per interval.')
) as x(url,label,notes) on true where f.slug='thinkcapital'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('lightning','https://www.thinkcapital.com/lightning/','Lightning selector and rules','USD size/fee schedule and current marketing rules captured 2026-09-28; agreement reconciliation remains.'),
 ('dual-step-intraday','https://www.thinkcapital.com/dual-step/','Dual Step selector and rules','Intraday USD size/fee schedule captured 2026-09-28; objective/max-loss conflict with Demo Agreement.'),
 ('dual-step-intraday','https://www.thinkcapital.com/demo-agreement/','Dual Step agreement conflict','Official agreement gives an 8% Phase 1 target and different max-loss wording than selector. Review status required.'),
 ('dual-step-swing','https://www.thinkcapital.com/dual-step/','Dual Step selector and rules','Swing USD size/fee schedule captured 2026-09-28; objective/max-loss conflict with Demo Agreement.'),
 ('dual-step-swing','https://www.thinkcapital.com/demo-agreement/','Dual Step agreement conflict','Official agreement gives an 8% Phase 1 target and 8% challenge max-loss wording rather than selector 9%/7%.'),
 ('nexus','https://www.thinkcapital.com/nexus/','Nexus selector and rules','USD size/fee schedule and current three-stage model captured 2026-09-28.'),
 ('bolt-instant-funding','https://www.thinkcapital.com/instant-funding/','Bolt selector and rules','USD size/fee schedule and current direct-funded rules captured 2026-09-28.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='thinkcapital'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'ThinkCapital official homepage, five live Forex model pages/selectors, Terms, Demo Agreement, platform and eligibility FAQs reviewed 2026-09-28. Firm current; model terms have unresolved agreement/selector conflicts.'
from bullish_banana.firms f where slug='thinkcapital'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Current official selector fee schedule and model page captured 2026-09-28. Record remains in review until current account agreement and model-specific rule conflicts, funded conditions, and add-ons are reconciled.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='thinkcapital' and p.slug in ('lightning','dual-step-intraday','dual-step-swing','nexus','bolt-instant-funding')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);

