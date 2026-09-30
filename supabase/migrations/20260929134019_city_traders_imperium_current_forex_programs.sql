-- City Traders Imperium's current Forex paths from its first-party site, captured 2026-09-29.
-- Programs remain in_review pending a complete pass on refunds, commissions and contract-level terms.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('City Traders Imperium','city-traders-imperium','A simulated Forex evaluation and funding provider offering one-step, two-step and no-evaluation account paths.','https://citytradersimperium.com/','published','forex',now())
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
 status='published',market_type='forex',published_at=coalesce(bullish_banana.firms.published_at,now()),
 archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='city-traders-imperium'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'KM','City Traders Imperium Limited',array['Forex','Commodities','Indices','Crypto']::text[],
 '{
   "service_model":"Current Terms describe skill-assessment programmes and simulated demo trading with virtual capital. The company says it is not a broker and does not accept or manage client deposits or place live market orders.",
   "legal_entity":"City Traders Imperium Limited, Comoros Union, company number 15969, License No. L15969/CTI. CTI FZCO (DSO-FZCO-21340) is separately identified as the provider of CTI Academy educational courses.",
   "platforms":["MetaTrader 5","Match-Trader"],
   "supported_assets_note":"Official homepage lists Forex, commodities, indices and crypto. Product-specific symbol lists and commissions are not stated on the reviewed program pages.",
   "jurisdiction_notes":"Current Terms list North Korea (DPRK), Iran, Syria, Cuba and Russia, and individuals under international sanctions, as restricted. Other local-law limitations may apply.",
   "current_programs":["1-Step Challenge","2-Step Challenge","Instant Funding","Direct Funding"],
   "publication_note":"Official product pages, homepage and current Terms page reviewed 2026-09-29. Program entries remain in review pending a complete refund, commissions and contract-term reconciliation."
 }'::jsonb
from bullish_banana.firms where slug='city-traders-imperium'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
 supported_assets=excluded.supported_assets,
 profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
 updated_at=now();

insert into bullish_banana.restrictions (firm_id,country_code,restriction_type,note)
select f.id,x.country_code,'restricted',x.note
from bullish_banana.firms f
join (values
 ('KP','Official Terms & Conditions reviewed 2026-09-29 list North Korea (DPRK) as a restricted jurisdiction.'),
 ('IR','Official Terms & Conditions reviewed 2026-09-29 list Iran as a restricted jurisdiction.'),
 ('SY','Official Terms & Conditions reviewed 2026-09-29 list Syria as a restricted jurisdiction.'),
 ('CU','Official Terms & Conditions reviewed 2026-09-29 list Cuba as a restricted jurisdiction.'),
 ('RU','Official Terms & Conditions reviewed 2026-09-29 list Russia as a restricted jurisdiction.')
) as x(country_code,note) on true
where f.slug='city-traders-imperium'
on conflict (firm_id,country_code) do update
set restriction_type=excluded.restriction_type,note=excluded.note,updated_at=now();

insert into bullish_banana.programs (
 firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
 max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,news_allowed,
 weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,x.program_type,'forex','in_review','USD',x.sizes::jsonb,
 null,x.split,x.payout,x.days,true,true,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('1-Step Challenge','1-step-challenge','One-phase simulated Forex evaluation with an 8% target and balance-based trailing drawdown.','evaluation','[2500,5000,10000,25000,50000,100000]',80::numeric,'First withdrawal from day 7; VIP can unlock weekly/anytime terms',3::integer,
  '{"account_size_prices":[{"account_size":2500,"fee":29,"currency":"USD"},{"account_size":5000,"fee":49,"currency":"USD"},{"account_size":10000,"fee":79,"currency":"USD"},{"account_size":25000,"fee":159,"currency":"USD"},{"account_size":50000,"fee":299,"currency":"USD"},{"account_size":100000,"fee":449,"currency":"USD"}],"price_capture":"One-time prices displayed on official 1-Step product page on 2026-09-29. A CTI editorial article published 2025-12-12 and updated 2026-09-03 displays different historical prices for some sizes; the current product page selector is the captured price source and the discrepancy remains noted for review.","evaluation_rules":"One phase; 8% target; 5% balance-based trailing maximum drawdown; no daily drawdown; three profitable trading days; unlimited time.","funded_rules":"Starts at 80% profit share, can progress through CTI VIP to 90% and 100%; first withdrawal after 7 days per product page. Scaling per account up to $200,000 and total funding up to $400,000.","trading_conditions":"News, overnight and weekend trading allowed. Official 1-Step page permits third-party EAs and martingale. MT5 and Match-Trader listed.","payout_rules":"Starts at 80%; first payout after 7 days; later payout cadence depends on CTI VIP tier and exact tier requirements need confirmation.","ea_rule":"Own and third-party EAs are allowed.","prohibited_strategies":"Martingale is allowed on this product; review current conduct terms for the full prohibited-method list.","commission_details":"Not stated in the reviewed official program page.","fee_refund_policy":"Current Terms state service fees are non-refundable except as outlined in the Refund Policy; program-specific exceptions still need verification.","fee_and_refund":"Current product page identifies one-time fee. Exact refund eligibility and conditions should be checked against the current refund policy before publication."}'),
 ('2-Step Challenge','2-step-challenge','Two-phase simulated Forex evaluation with 10% and 5% targets and static loss limits.','evaluation','[2500,5000,10000,25000,50000,100000]',80::numeric,'First withdrawal from day 7; VIP can unlock weekly/anytime terms',3::integer,
  '{"account_size_prices":[{"account_size":2500,"fee":39,"currency":"USD"},{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":25000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":329,"currency":"USD"},{"account_size":100000,"fee":549,"currency":"USD"}],"price_capture":"One-time prices displayed on official 2-Step product page on 2026-09-29.","evaluation_rules":"Phase targets are 10% then 5%; 10% static maximum drawdown; 5% daily drawdown, measured from the day starting balance; three profitable trading days per phase; no time limit.","funded_rules":"Starts at 80% profit share and can progress through CTI VIP to 90% or 100%. The official page states first withdrawal in 7 days and describes weekly/anytime schedules at later VIP tiers. Scaling per account up to $200,000 and total funding up to $400,000.","trading_conditions":"News, overnight and weekend holding allowed. Personal EAs permitted; third-party EAs and martingale prohibited. MT5 and Match-Trader listed.","payout_rules":"Starts at 80%; first payout after 7 days; weekly and anytime options are available through later CTI VIP tiers, subject to eligibility.","ea_rule":"Personal EAs only; third-party EAs are not allowed.","prohibited_strategies":"Martingale is not allowed; review current conduct terms for the full prohibited-method list.","commission_details":"Not stated in the reviewed official program page.","fee_refund_policy":"Current Terms state service fees are non-refundable except as outlined in the Refund Policy; program-specific exceptions still need verification.","fee_and_refund":"Current product page identifies one-time fee. Exact refund eligibility and conditions should be checked against the current refund policy before publication."}'),
 ('Instant Funding','instant-funding','No-evaluation simulated funded account that starts at half of the selected balance and scales at profit milestones.','instant_funding','[2500,5000,10000,20000,40000,80000]',50::numeric,'First withdrawal from day 5; thereafter milestone and VIP-dependent',null::integer,
  '{"account_size_prices":[{"account_size":2500,"fee":79,"currency":"USD","starting_balance":1250,"fully_funded_balance":2500},{"account_size":5000,"fee":139,"currency":"USD","starting_balance":2500,"fully_funded_balance":5000},{"account_size":10000,"fee":259,"currency":"USD","starting_balance":5000,"fully_funded_balance":10000},{"account_size":20000,"fee":449,"currency":"USD","starting_balance":10000,"fully_funded_balance":20000},{"account_size":40000,"fee":849,"currency":"USD","starting_balance":20000,"fully_funded_balance":40000},{"account_size":80000,"fee":1599,"currency":"USD","starting_balance":40000,"fully_funded_balance":80000}],"price_capture":"One-time prices displayed on official Instant Funding product page on 2026-09-29.","funded_rules":"No evaluation or daily drawdown. 6% static maximum loss from starting balance. Select size begins with 50% of the selected balance; a 10% milestone doubles to the full selected balance and subsequent 10% milestones continue scaling. Starting reward share is 50%, later levels show 70% and 80%, with CTI VIP progression up to 100%. First payout after 5 days per page; further payout conditions depend on milestone and tier.","trading_conditions":"News, overnight and weekend trading allowed; personal EAs allowed; martingale prohibited. MT5 and Match-Trader listed.","payout_rules":"Starts at 50%; first payout after 5 days. Reward share progresses by funded level and VIP tier; detailed milestone-based payout eligibility needs confirmation.","ea_rule":"Personal EAs only; third-party EA use is not indicated as permitted on the official program page.","prohibited_strategies":"Martingale is not allowed; review current conduct terms for the full prohibited-method list.","commission_details":"Not stated in the reviewed official program page.","fee_refund_policy":"Current Terms state service fees are non-refundable except as outlined in the Refund Policy; program-specific exceptions still need verification.","fee_and_refund":"Current product page identifies a one-time fee. Exact refund eligibility and conditions should be checked against the current refund policy before publication."}'),
 ('Direct Funding','direct-funding','No-evaluation simulated funded account with full balance available from the start.','instant_funding','[5000,10000,20000,40000,80000]',70::numeric,'On demand from day 5; thereafter milestone and VIP-dependent',null::integer,
  '{"account_size_prices":[{"account_size":5000,"fee":229,"currency":"USD"},{"account_size":10000,"fee":399,"currency":"USD"},{"account_size":20000,"fee":999,"currency":"USD"},{"account_size":40000,"fee":1999,"currency":"USD"},{"account_size":80000,"fee":3999,"currency":"USD"}],"price_capture":"One-time prices displayed on official Direct Funding product page on 2026-09-29.","funded_rules":"No evaluation. Begins at 70% profit share. First withdrawal can be requested on demand from day 5; 10% profit milestones drive further account scaling. 6% static maximum drawdown and no daily drawdown. Scaling up to $2,000,000 per account and $4,000,000 total.","trading_conditions":"News, overnight and weekend trading allowed. Personal EAs allowed; third-party EAs and martingale prohibited. MT5 and Match-Trader listed.","payout_rules":"70% starting share; first payout is on demand from day 5. Later VIP tiers can increase the share; exact eligibility and cadence need confirmation.","ea_rule":"Personal EAs only; third-party EAs are not allowed.","prohibited_strategies":"Martingale is not allowed; review current conduct terms for the full prohibited-method list.","commission_details":"Not stated in the reviewed official program page.","fee_refund_policy":"Current Terms state service fees are non-refundable except as outlined in the Refund Policy; program-specific exceptions still need verification.","fee_and_refund":"Current product page identifies a one-time fee. Exact refund eligibility and conditions should be checked against the current refund policy before publication."}')
) as x(name,slug,description,program_type,sizes,split,payout,days,details) on true
where f.slug='city-traders-imperium'
on conflict (firm_id,slug) do update
set name=excluded.name,description=excluded.description,program_type=excluded.program_type,
 market_type=excluded.market_type,status='in_review',currency=excluded.currency,
 account_sizes=excluded.account_sizes,max_leverage=excluded.max_leverage,
 profit_split_percent=excluded.profit_split_percent,payout_frequency=excluded.payout_frequency,
 minimum_trading_days=excluded.minimum_trading_days,news_allowed=excluded.news_allowed,
 weekend_holding_allowed=excluded.weekend_holding_allowed,
 commercial_details=bullish_banana.programs.commercial_details || excluded.commercial_details,
 published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.program_phases (
 program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
 maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,x.drawdown_type,null,x.days,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('1-step-challenge',1,'Evaluation',8::numeric,null::numeric,5::numeric,'trailing',3::integer,'{"drawdown_reference":"Balance based; maximum loss trails the balance per current official 1-Step rules.","minimum_profitable_days":3,"day_requirement_label":"3 profitable trading days"}'),
 ('2-step-challenge',1,'Phase 1',10::numeric,5::numeric,10::numeric,'static',3::integer,'{"daily_loss_reference":"5% of initial balance, reset from the start of each day.","minimum_profitable_days":3,"day_requirement_label":"3 profitable trading days"}'),
 ('2-step-challenge',2,'Phase 2',5::numeric,5::numeric,10::numeric,'static',3::integer,'{"daily_loss_reference":"5% of initial balance, reset from the start of each day.","minimum_profitable_days":3,"day_requirement_label":"3 profitable trading days"}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,days,rules) on x.program_slug=p.slug
where f.slug='city-traders-imperium'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=excluded.daily_drawdown_percent,
 maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
 time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
 raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug)
values ('MetaTrader 5','metatrader-5'),('Match-Trader','match-trader')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select p.id,pl.id from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join bullish_banana.platforms pl on pl.slug in ('metatrader-5','match-trader')
where f.slug='city-traders-imperium'
and p.slug in ('1-step-challenge','2-step-challenge','instant-funding','direct-funding')
on conflict (program_id,platform_id) do nothing;

insert into bullish_banana.affiliate_destinations (firm_id,kind,label,destination_url,is_primary,status)
select id,'official_site','Visit City Traders Imperium','https://citytradersimperium.com/',true,'active'
from bullish_banana.firms f where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.affiliate_destinations d where d.firm_id=f.id and d.kind='official_site' and d.program_id is null);

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://citytradersimperium.com/','Official homepage','Current product selector lists 1-Step, 2-Step, Instant Funding and Direct Funding with Forex among supported markets; platforms, simulated-service/legal disclosures and pricing snapshots reviewed 2026-09-29.'),
 ('https://citytradersimperium.com/1-step-challenge/','1-Step Challenge','Current product page: one phase, 8% objective, 5% balance-based trailing maximum loss, no daily limit, three profitable days, time limit, trading conditions, platform and six size/fee options; reviewed 2026-09-29.'),
 ('https://citytradersimperium.com/2-step-challenge/','2-Step Challenge','Current product page: 10%/5% phase objectives, 10% static maximum, 5% daily, three profitable days per phase, no time limit, permitted strategies, payout overview, platform and six size/fee options; reviewed 2026-09-29.'),
 ('https://citytradersimperium.com/instant-funding/','Instant Funding','Current product page: no evaluation, starting/fully funded sizes, 6% static max loss, payout and scaling model, trading conditions, platform and six size/fee options; reviewed 2026-09-29.'),
 ('https://citytradersimperium.com/direct-funding/','Direct Funding','Current product page: no evaluation, full balance from start, 6% static max loss, payout and scaling model, trading conditions, platform and five size/fee options; reviewed 2026-09-29.'),
 ('https://citytradersimperium.com/terms-conditions-of-service/','Terms & Conditions of Service','Current official Terms landing page and disclosure reviewed 2026-09-29: Comoros legal entity, simulated/demo service, no client funds or live trading, country restrictions and fee/refund pointer.')
) as x(url,label,notes) on true
where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('1-step-challenge','https://citytradersimperium.com/1-step-challenge/','1-Step rules and fee matrix','Current product-specific evaluation, trailing drawdown, profitable-day, trading-condition and price evidence.'),
 ('2-step-challenge','https://citytradersimperium.com/2-step-challenge/','2-Step rules and fee matrix','Current product-specific phase targets, drawdown, min days, payout and price evidence.'),
 ('instant-funding','https://citytradersimperium.com/instant-funding/','Instant Funding rules and fee matrix','Current no-evaluation program, starting balance, scale milestones, reward share and price evidence.'),
 ('direct-funding','https://citytradersimperium.com/direct-funding/','Direct Funding rules and fee matrix','Current no-evaluation program, full starting balance, scale milestones, reward share and price evidence.'),
 ('1-step-challenge','https://citytradersimperium.com/terms-conditions-of-service/','Current Terms and legal disclosures','Official current terms landing page. Refund details are linked separately and still require program-specific reconciliation.'),
 ('2-step-challenge','https://citytradersimperium.com/terms-conditions-of-service/','Current Terms and legal disclosures','Official current terms landing page. Refund details are linked separately and still require program-specific reconciliation.'),
 ('instant-funding','https://citytradersimperium.com/terms-conditions-of-service/','Current Terms and legal disclosures','Official current terms landing page. Refund details are linked separately and still require program-specific reconciliation.'),
 ('direct-funding','https://citytradersimperium.com/terms-conditions-of-service/','Current Terms and legal disclosures','Official current terms landing page. Refund details are linked separately and still require program-specific reconciliation.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Official CTI homepage, all four product pages and current Terms landing page reviewed 2026-09-29. Current Forex programs, legal operator, simulated-service model, platforms and listed restricted jurisdictions recorded; full fee/refund and commission review remains.'
from bullish_banana.firms f where slug='city-traders-imperium'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Official product page and current Terms landing page reviewed 2026-09-29. Program is staged in review pending current refund policy, commission and remaining contract-term review.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='city-traders-imperium' and p.slug in ('1-step-challenge','2-step-challenge','instant-funding','direct-funding')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);
