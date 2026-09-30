-- FundingPips Forex models from first-party pages captured 2026-09-29.
-- Programs stay in_review because material size/fee/add-on and rule conflicts remain.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values (
  'FundingPips', 'fundingpips',
  'A simulated trading provider offering one-step, two-step and no-evaluation account models.',
  'https://fundingpips.com/', 'published', 'forex', now()
)
on conflict (slug) do update
set name=excluded.name, description=excluded.description, website_url=excluded.website_url,
    status='published', market_type='forex',
    published_at=coalesce(bullish_banana.firms.published_at, now()), archived_at=null, updated_at=now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug='fundingpips'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'KM','FundingPips Corp.',array['Forex','Metals','Indices','Energies','Cryptocurrencies']::text[],
  '{
    "service_model":"FundingPips describes its accounts as simulated trading accounts and says it does not provide brokerage or live-market trading services.",
    "legal_entity":"FundingPips Corp., Comoros; official pages state company number HY01223081 and IBC license Bfx2024004.",
    "platforms":"Platform availability should be confirmed for each model/account at selection; not stated consistently across the reviewed model guides.",
    "instruments":"Official Get Started article states 41 instruments across Forex, metals, indices, energies and crypto.",
    "jurisdiction_notes":"Official Get Started material references sanctions-list restrictions and identifies Vietnam and the UAE among restricted jurisdictions. Full current country coverage was not transcribed; do not infer eligibility elsewhere.",
    "current_models":["1 Step Flex","2 Step Standard","2 Step Flex","2 Step Pro Model","FundingPips Zero"],
    "publication_note":"Official homepage, Help Center model guides, comparison article and selected public price widget reviewed 2026-09-29. Models remain in review where variant pricing, supported sizes, daily-loss add-ons or rule displays conflict."
  }'::jsonb
from bullish_banana.firms where slug='fundingpips'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
    supported_assets=excluded.supported_assets,
    profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at=now();

insert into bullish_banana.programs (
 firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
 max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,news_allowed,
 weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,x.program_type,'forex','in_review','USD',x.sizes::jsonb,
       x.leverage,x.split,x.payout,x.days,x.news,x.weekends,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('1 Step Flex','1-step-flex','One-phase simulated Forex evaluation with a 12% objective and static maximum loss.','evaluation','[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Biweekly; monthly option stated in model comparison',null::integer,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":5000,"fee":74,"currency":"USD"},{"account_size":10000,"fee":111,"currency":"USD"},{"account_size":25000,"fee":255,"currency":"USD"},{"account_size":50000,"fee":353,"currency":"USD"},{"account_size":100000,"fee":666,"currency":"USD"}],"price_capture":"Homepage model/size selector display observed 2026-09-29; homepage separately displayed code FP promotion (10% for new users, 5% for existing users). No code applied; checkout discount semantics are unverified.","evaluation_rules":"One phase; 12% target; 12% static maximum loss; no minimum trading days or time limit stated in model guide.","daily_loss_conflict":"Official comparison display says 2% or 3% daily loss, apparently dependent on an account/add-on variant. Exact selection-to-rule mapping not verified; do not present a single daily limit as universal.","funded_rules":"Biweekly reward option stated at 80%; monthly option at 100% in current model comparison. Eligibility and model-specific payout conditions need review.","verification_note":"Plan-specific guide and current model comparison differ on variant-dependent daily limit details; keep in review."}'),
 ('2 Step Standard','2-step-standard','Two-phase simulated Forex evaluation with 8% and 5% phase objectives.','evaluation','[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Weekly, biweekly, on-demand or monthly options',3::integer,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":5000,"fee":44,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":216,"currency":"USD"},{"account_size":50000,"fee":349,"currency":"USD"},{"account_size":100000,"fee":652,"currency":"USD"}],"price_capture":"Homepage model/size selector display observed 2026-09-29, before any checkout action. Homepage separately displayed code FP promotion; exact application to checkout remains unverified.","evaluation_rules":"Targets 8% then 5%; 10% static maximum loss; minimum 3 trading days per phase unless the 3% daily-loss add-on is selected. Daily-loss display varies by add-on/account option (3% or 5%). Unlimited time stated in general help guidance.","funded_rules":"Reward options listed in current comparison: weekly 60%, biweekly 80%, on-demand 90%, monthly 100%; fourth reward fee refund is stated. Exact plan and eligibility conditions require confirmation.","verification_note":"Store the observed size/price selector matrix as a dated snapshot; daily-loss variant mapping and reward eligibility need review."}'),
 ('2 Step Flex','2-step-flex','Two-phase simulated Forex evaluation with 10% and 8% objectives and flexible reward options.','evaluation','[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Biweekly 80%; optional 95%; monthly 100%',1::integer,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":5000,"fee":39,"currency":"USD"},{"account_size":10000,"fee":70,"currency":"USD"},{"account_size":25000,"fee":188,"currency":"USD"},{"account_size":50000,"fee":299,"currency":"USD"},{"account_size":100000,"fee":555,"currency":"USD"}],"price_capture":"Homepage model/size selector display observed 2026-09-29, before any checkout action. Homepage separately displayed code FP promotion; exact application to checkout remains unverified.","evaluation_rules":"Targets 10% then 8%; 4% daily loss; 12% static maximum loss. Current model guide describes one minimum trading day at the 80% reward option or three profitable days for the 95% option; no time limit stated in general help guidance.","funded_rules":"Biweekly reward share 80%, optional 95% add-on, or monthly 100% according to current comparison. Exact add-on fee and payout eligibility need review.","verification_note":"Shared comparison and dedicated guide should be rechecked together before publication."}'),
 ('2 Step Pro Model','2-step-pro-model','Two-phase simulated Forex evaluation with 6% objectives and tighter static loss limits.','evaluation','[5000,10000,25000,50000,100000,200000]',100::numeric,80::numeric,'Weekly 80% or monthly 100%',2::integer,null::boolean,null::boolean,
  '{"account_size_prices":[{"account_size":5000,"fee":33,"currency":"USD"},{"account_size":10000,"fee":62,"currency":"USD"},{"account_size":25000,"fee":149,"currency":"USD"},{"account_size":50000,"fee":249,"currency":"USD"},{"account_size":100000,"fee":466,"currency":"USD"}],"unpriced_sizes":[200000],"price_capture":"Homepage selector displayed prices through $100K on 2026-09-29. Dedicated official Pro guide lists $200K; its fee was not verified. Promo banner displayed code FP; discount checkout semantics are unverified.","evaluation_rules":"Targets 6% then 6%; 3% daily and 6% static maximum loss. Dedicated Pro guide updated 2026-08-26 states two minimum trading days per phase for new accounts/reset phases; shared comparison table displays one minimum day per phase. Prefer the newer plan-specific guide pending reconciliation.","funded_rules":"Weekly reward share 80% or monthly 100% per current model comparison; detailed eligibility needs review.","verification_note":"Dedicated guide and shared comparison conflict on minimum days; $200K fee absent from observed selector. Keep in review."}'),
 ('FundingPips Zero','fundingpips-zero','No-evaluation simulated Forex account with trailing loss and periodic profitable-day conditions.','instant_funding','[5000,10000,25000,50000,100000,200000]',50::numeric,95::numeric,'Biweekly',7::integer,false,false,
  '{"account_size_prices":[{"account_size":5000,"fee":60,"currency":"USD"},{"account_size":10000,"fee":88,"currency":"USD"},{"account_size":25000,"fee":188,"currency":"USD"},{"account_size":50000,"fee":244,"currency":"USD"},{"account_size":100000,"fee":444,"currency":"USD"},{"account_size":200000,"fee":888,"currency":"USD"}],"price_capture":"Homepage model/size selector display observed 2026-09-29; displayed price treatment relative to code FP promotion and checkout remains unverified.","funded_rules":"No evaluation. 3% daily loss, 5% trailing maximum loss that locks at breakeven, 1% maximum risk per trade idea, at least seven profitable days of 0.25% or more within each 30-day period, 30-day inactivity rule, 95% biweekly reward share. FX leverage 1:50.","trading_conditions":"Official Zero guide states strict news and weekend restrictions; confirm exact event windows and instrument scope before publication.","verification_note":"Plan guide reviewed 2026-09-29. Keep in review until complete reward eligibility, prohibited trading windows, and promotion/selector price handling are reconfirmed."}')
) as x(name,slug,description,program_type,sizes,leverage,split,payout,days,news,weekends,details) on true
where f.slug='fundingpips'
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
 ('1-step-flex',1,'Evaluation',12::numeric,null::numeric,12::numeric,'static',null::integer,'{"daily_loss_variant":"Official comparison displays 2% or 3%; exact variant mapping is unresolved."}'),
 ('2-step-standard',1,'Phase 1',8::numeric,null::numeric,10::numeric,'static',3::integer,'{"daily_loss_variant":"3% or 5% depending on selected account/add-on; exact mapping unresolved.","day_requirement_label":"3 trading days per phase unless the 3% daily-loss add-on is selected."}'),
 ('2-step-standard',2,'Phase 2',5::numeric,null::numeric,10::numeric,'static',3::integer,'{"daily_loss_variant":"3% or 5% depending on selected account/add-on; exact mapping unresolved.","day_requirement_label":"3 trading days per phase unless the 3% daily-loss add-on is selected."}'),
 ('2-step-flex',1,'Phase 1',10::numeric,4::numeric,12::numeric,'static',1::integer,'{"min_days_and_reward_options":"One minimum day for 80% option; three profitable days for 95% option.","day_requirement_label":"1 trading day (80% reward option) or 3 profitable days (95% reward option)."}'),
 ('2-step-flex',2,'Phase 2',8::numeric,4::numeric,12::numeric,'static',1::integer,'{"min_days_and_reward_options":"One minimum day for 80% option; three profitable days for 95% option.","day_requirement_label":"1 trading day (80% reward option) or 3 profitable days (95% reward option)."}'),
 ('2-step-pro-model',1,'Phase 1',6::numeric,3::numeric,6::numeric,'static',2::integer,'{"minimum_days_conflict":"Dedicated 2026-08-26 Pro guide states two minimum trading days per phase for new/reset accounts; shared comparison table says one.","day_requirement_label":"2 trading days per phase for new/reset accounts."}'),
 ('2-step-pro-model',2,'Phase 2',6::numeric,3::numeric,6::numeric,'static',2::integer,'{"minimum_days_conflict":"Dedicated 2026-08-26 Pro guide states two minimum trading days per phase for new/reset accounts; shared comparison table says one.","day_requirement_label":"2 trading days per phase for new/reset accounts."}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,days,rules) on x.program_slug=p.slug
where f.slug='fundingpips'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=excluded.daily_drawdown_percent,
 maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
 time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
 raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://fundingpips.com/','Official FundingPips homepage','Current model/size price selector, promotion banner, model overview and simulated service disclosure reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/44390730743825-Get-Started','Get Started','Account-model overview, sizes, instruments, simulated service, company/licensing and jurisdiction notes; reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/48368490585105-Compare-Account-Models','Compare Account Models','Current cross-model targets, daily/max loss, payout options, leverage and minimum-day summary; reviewed 2026-09-29. Some entries conflict with dedicated model guides.'),
 ('https://fundingpips.com/trading-objectives','Trading objectives','Official interactive plan rules; current model selection changes displayed terms. Read-only selections reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex guide','Plan-specific target, size, payout and drawdown rules; reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34501809112081-2-Step-Standard','2 Step Standard guide','Plan-specific phase targets, daily-loss variants, minimum days, sizes and reward rules; reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex guide','Plan-specific targets, loss limits, minimum-day/reward options and size range; reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34502027344017-2-Step-Pro-Model','2 Step Pro Model guide','Plan-specific rules and account sizes; updated 2026-08-26. Minimum-day count differs from shared comparison.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34502157694865-FundingPips-Zero','FundingPips Zero guide','No-evaluation account rules, risk limits, profitable-day requirements, restrictions, sizes and rewards; reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34505029138449-Trading-Conduct-and-Security-Standards','Trading Conduct and Security Standards','General conduct and account-security restrictions; reviewed 2026-09-29.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34504137479441-News-Trading-and-Holding-Trades-Over-the-Weekend','News Trading and Holding Trades Over the Weekend','General news/weekend policy; account-model-specific exceptions require confirmation.'),
 ('https://help.fundingpips.com/hc/en-us/articles/34504564970385-Your-Rewards-Your-Way','Your Rewards, Your Way','Reward schedules and payout options; model-specific eligibility/add-on treatment needs confirmation.'),
 ('https://help.fundingpips.com/hc/en-us/articles/48174287980177-Risk-Per-Trade-Idea','Risk Per Trade Idea','Risk-per-trade guidance referenced for Zero; reviewed 2026-09-29.')
) as x(url,label,notes) on true
where f.slug='fundingpips'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('1-step-flex','https://help.fundingpips.com/hc/en-us/articles/34501697434385-1-Step-Flex','1 Step Flex official guide','Targets, drawdown, size and payout schedule. Shared comparison daily-loss variant mapping remains unresolved.'),
 ('2-step-standard','https://help.fundingpips.com/hc/en-us/articles/34501809112081-2-Step-Standard','2 Step Standard official guide','Phase rules, minimum days, variant-dependent daily loss, reward options and size range.'),
 ('2-step-flex','https://help.fundingpips.com/hc/en-us/articles/47835196271249-2-Step-Flex','2 Step Flex official guide','Targets, daily/max limits, minimum-day and reward options.'),
 ('2-step-pro-model','https://help.fundingpips.com/hc/en-us/articles/34502027344017-2-Step-Pro-Model','2 Step Pro official guide','Targets, limits, sizes and two minimum days per phase for new/reset accounts per 2026-08-26 update.'),
 ('fundingpips-zero','https://help.fundingpips.com/hc/en-us/articles/34502157694865-FundingPips-Zero','FundingPips Zero official guide','No-evaluation risk and reward terms; payout windows and promotional selector semantics need further review.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='fundingpips'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.affiliate_destinations (firm_id,kind,label,destination_url,is_primary,status)
select id,'official_site','Visit FundingPips','https://fundingpips.com/',true,'active'
from bullish_banana.firms where slug='fundingpips'
and not exists(select 1 from bullish_banana.affiliate_destinations d where d.firm_id=firms.id and d.kind='official_site' and d.program_id is null);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Official FundingPips homepage, model-specific Help Center guides, comparison article, rewards/trading rules and Get Started article reviewed 2026-09-29. Forex operation and five current models confirmed; programs remain in review pending variant/add-on, $200K Pro price, payout eligibility and restriction reconciliations.'
from bullish_banana.firms where slug='fundingpips'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=firms.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Official model guide and selector snapshot reviewed 2026-09-29. See commercial_details and attached first-party source records; model remains in review until documented conflicts and missing variant terms are resolved.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='fundingpips' and p.slug in ('1-step-flex','2-step-standard','2-step-flex','2-step-pro-model','fundingpips-zero')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);
