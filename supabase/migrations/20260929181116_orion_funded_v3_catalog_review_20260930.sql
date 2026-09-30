-- Orion Funded current V3 candidates captured 2026-09-30.
-- Records are review-only because legal/operator, current pricing, and legacy selector conflicts remain open.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('Orion Funded','orion-funded','A simulated Forex and multi-asset trading evaluation provider with instant, one-step, two-step and three-step programs.','https://www.orionfunded.com/','in_review','forex',null)
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
 status='in_review',market_type='forex',published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='orion-funded'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'LC','OGM International Ltd.',
 array['Forex','Indices','Metals','Commodities','Stocks','Cryptocurrencies']::text[],
 '{
  "service_model":"All Orion accounts are simulated demo accounts. The company states trades are not executed in real financial instruments.",
  "legal_entity_note":"Current GTC PDF, updated March 22, 2026, names OGM International Ltd. (Saint Lucia) as Provider and contract counterparty. Current homepage footer names Orion Global FZCO. Reward accounts may be contracted through a third party. Record OGM as GTC provider but keep entity scope in review until a current V3 order agreement resolves the public-footer mismatch.",
  "current_v3_programs":["Orion Zero","Orion Nova","Orion Standard","Orion Swing","Orion Select"],
  "assets_and_platforms":"Current official FAQ lists Forex, indices, metals, commodities, stocks and cryptocurrencies; Forex maximum leverage is 1:100 for Zero/Nova/Standard and 1:30 for Swing/Select; $4/lot Forex commission. MT5 and MatchTrader are listed. Full symbol list appears in trading platforms.",
  "account_sizes":"V3 homepage selector displays USD/EUR currency options and $5K/$10K/$25K/$50K/$100K/$200K size choices. Linked checkout selector remains a generic legacy catalog with different size range, so verify by V3 order path.",
  "jurisdiction_note":"GTC PDF identifies OGM International Ltd. and lists restricted jurisdictions; current website also provides an updated eligibility FAQ. Reconcile the current website list and the V3 order agreement before publishing.",
  "publication_note":"Firm and Forex eligibility confirmed. V3 challenge candidate records are staged in review. Do not promote old generic WooCommerce checkout fees or V2/Lite terms into V3."
 }'::jsonb
from bullish_banana.firms where slug='orion-funded'
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
select f.id,x.name,x.slug,x.description,case when x.slug='orion-zero' then 'instant_funding' else 'evaluation' end,'forex','in_review','USD',
 '[]'::jsonb,x.leverage,80,'Not stated',x.minimum_days,
 null,true,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('Orion Zero','orion-zero','Instant simulated Orion Trader Account with a 3% daily loss limit and 6% trailing-lock maximum loss.',100::numeric,null::integer,
  '{"structure":"Instant funded; no evaluation phase or profit target.","rules":"3% daily loss; 6% trailing-lock max loss. No minimum trading days stated.","reward":"All programs start at 80%; payout timing and current Zero conditions require current V3 order agreement verification.","fees":"Current fee matrix not verified. A linked legacy checkout and older Zero landing page expose prices, but the current V3 homepage/order path has not been matched to those prices.","account_sizes":"Not mapped to this specific V3 track in verified public sources.","platforms":["MetaTrader 5","MatchTrader"],"leverage":"Forex maximum 1:100; $4 per lot.","source_conflicts":"Current V3 homepage has an active size/currency selector; linked WooCommerce checkout exposes generic account models/sizes. Keep in review."}'),
 ('Orion Nova','orion-nova','One-step simulated Forex evaluation with a Pay After You Pass registration and activation fee.',100::numeric,null::integer,
  '{"structure":"One evaluation phase; Pay After You Pass.","evaluation_rules":"4% target; 4% daily loss; 8% maximum loss with trailing lock. No time limit; no minimum trading days.","funded_rules":"3% daily loss; 5% maximum loss with trailing lock. Starting reward 80%.","fees":"Registration fee is USD 7 / EUR 7; activation fee due only after passing. Current activation matrix not verified.","account_sizes":"Not mapped to this specific V3 track in verified public sources.","platforms":["MetaTrader 5","MatchTrader"],"leverage":"Forex maximum 1:100; $4 per lot.","source_conflicts":"Current V3 homepage labels this product New; linked generic checkout does not map Nova to its 1-Step selector. Keep in review."}'),
 ('Orion Standard','orion-standard','Two-step simulated Forex evaluation in Standard mode.',100::numeric,4::integer,
  '{"structure":"Two phases; Standard account mode.","evaluation_rules":"6% target per phase; 3% daily loss; 6% static maximum loss. Minimum four evaluation trading days.","funded_rules":"Starting reward 80%; full V3 Trader Account terms and payout timing require current agreement verification.","fees":"Current V3 size/fee matrix not verified. Older page captures and generic checkout data are not assumed current.","platforms":["MetaTrader 5","MatchTrader"],"leverage":"Forex maximum 1:100; $4 per lot.","source_conflicts":"Current Help Center calls this Standard/Swing modes under a two-step family; legacy page paths and generic checkout use older product naming. Keep in review."}'),
 ('Orion Swing','orion-swing','Two-step simulated Forex evaluation in Swing mode.',30::numeric,4::integer,
  '{"structure":"Two phases; Swing account mode.","evaluation_rules":"8% then 5% phase targets; 5% daily loss; 10% static maximum loss. Minimum four evaluation trading days.","funded_rules":"Starting reward 80%; full V3 Trader Account terms and payout timing require current agreement verification.","fees":"Current V3 size/fee matrix not verified. Older page captures and generic checkout data are not assumed current.","platforms":["MetaTrader 5","MatchTrader"],"leverage":"Forex maximum 1:30; $4 per lot.","source_conflicts":"Swing is a mode under the two-step family in Help Center, while former pages/selector do not map current V3 mode pricing. Keep in review."}'),
 ('Orion Select','orion-select','Three-step simulated Forex evaluation.',30::numeric,4::integer,
  '{"structure":"Three evaluation phases.","evaluation_rules":"5% target in each phase; 5% daily loss; 5% static maximum loss. Minimum four evaluation trading days; no time limit stated in current Help Center.","funded_rules":"Starting reward 80%; full V3 Trader Account terms and payout timing require current agreement verification.","fees":"Current V3 size/fee matrix not verified. Homepage currently displays a promotional $100K amount with a struck-through regular price; do not treat it as base pricing.","platforms":["MetaTrader 5","MatchTrader"],"leverage":"Forex maximum 1:30; $4 per lot.","source_conflicts":"Current homepage V3 selector includes dynamic offers; linked generic checkout is not confirmed to represent V3. Keep in review."}')
) as x(name,slug,description,leverage,minimum_days,details) on true
where f.slug='orion-funded'
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
select p.id,x.phase,x.name,x.target,x.daily,x.maximum,x.drawdown,x.time_limit,x.minimum_days,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('orion-nova',1,'Evaluation',4::numeric,4::numeric,8::numeric,'trailing',null::integer,null::integer,'{"funded_daily_loss_percent":3,"funded_maximum_loss_percent":5,"funded_drawdown_type":"Trailing Lock","no_time_limit":true,"no_minimum_trading_days":true}'),
 ('orion-standard',1,'Phase 1',6::numeric,3::numeric,6::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}'),
 ('orion-standard',2,'Phase 2',6::numeric,3::numeric,6::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}'),
 ('orion-swing',1,'Phase 1',8::numeric,5::numeric,10::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}'),
 ('orion-swing',2,'Phase 2',5::numeric,5::numeric,10::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}'),
 ('orion-select',1,'Phase 1',5::numeric,5::numeric,5::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}'),
 ('orion-select',2,'Phase 2',5::numeric,5::numeric,5::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}'),
 ('orion-select',3,'Phase 3',5::numeric,5::numeric,5::numeric,'static',null::integer,4::integer,'{"minimum_trading_days":4,"no_time_limit":true}')
) as x(program_slug,phase,name,target,daily,maximum,drawdown,time_limit,minimum_days,rules) on x.program_slug=p.slug
where f.slug='orion-funded'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=excluded.daily_drawdown_percent,
 maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
 time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
 raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug) values ('MatchTrader','matchtrader')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f
join (values
 ('https://www.orionfunded.com/','Official V3 homepage, refreshed 2026-09-30','Current V3 Available banner; visible Zero/Nova/Standard/Select navigation, USD/EUR choice, $5K-$200K size selector, account modes, simulated-account disclosure, homepage footer legal entity and a campaign-priced Select example. The price is promotional and not used as base fee.'),
 ('https://www.orionfunded.com/faq/new-to-orion/programs-overview','Official current programs overview','Five V3 programs: Zero instant, Nova one-step Pay After You Pass, Standard/Swing two-step modes, Select three-step. All start at 80%; overnight/weekend holds allowed.'),
 ('https://www.orionfunded.com/faq/programs/challenge-phases','Official current challenge comparison','Current V3 targets/drawdown overview, phase counts, minimum trading days and Nova $7/€7 registration fee.'),
 ('https://www.orionfunded.com/faq/trading/instruments','Official asset/leverage/commission matrix','Forex and other markets; Forex leverage tiers and $4/lot commission; MT5 and MatchTrader platform support appears on linked trading FAQ.'),
 ('https://www.orionfunded.com/faq/billing/challenge-fees','Official current billing FAQ','Fee depends on program/size; current order shows EUR/USD. Single upfront fee except Nova $7 registration then activation after passing.'),
 ('https://checkout.orionfunded.com/product/orion-challenges/','Linked generic checkout selector, rechecked 2026-09-30','Read-only selector lists generic 1-Step, 2-Step, 3-Step, Orion Zero; sizes include $2.5K-$200K and platforms MatchTrader/MT5. Not confirmed to correspond to V3 programs, so no fees are used.'),
 ('https://www.orionfunded.com/docs/terms-and-conditions.pdf','General Terms and Conditions PDF','Updated March 22, 2026; OGM International Ltd. named Provider; older Orion Lite/Standard/Select vocabulary and restricted-jurisdiction list. Homepage footer currently says Orion Global FZCO; V3 order agreement/entity mapping remains unresolved.')
) as x(url,label,notes) on true
where f.slug='orion-funded'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('orion-zero','https://www.orionfunded.com/faq/programs/challenge-phases','Orion Zero current rules','Instant; no target; 3% daily loss; 6% trailing lock; no minimum trading days. Current fee matrix remains unverified.'),
 ('orion-nova','https://www.orionfunded.com/faq/programs/challenge-phases','Orion Nova current rules','One-step Pay After You Pass; 4% target; 4%/8% evaluation and 3%/5% funded loss limits; no time or minimum-day limit; $7/$7 registration.'),
 ('orion-standard','https://www.orionfunded.com/faq/programs/challenge-phases','Orion Standard current rules','Two-step; 6%/6% targets; 3% daily/6% static loss; four minimum evaluation trading days. V3 fee map unverified.'),
 ('orion-swing','https://www.orionfunded.com/faq/programs/challenge-phases','Orion Swing current rules','Two-step Swing mode; 8%/5% targets; 5% daily/10% static loss; four minimum evaluation days. V3 fee map unverified.'),
 ('orion-select','https://www.orionfunded.com/faq/programs/challenge-phases','Orion Select current rules','Three-step; 5% each phase; 5% daily/5% static max; four minimum evaluation days. Current campaign price is not treated as a base fee.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='orion-funded'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Current V3 homepage, three current Help Center pages, asset/leverage matrix, generic checkout and linked GTC PDF reviewed 2026-09-30. Five V3 tracks are staged in review. Homepage footer vs GTC Provider identity differs; linked selector appears legacy and is not used for pricing.'
from bullish_banana.firms where slug='orion-funded';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Official V3 Help Center current rules captured 2026-09-30. Program remains in review pending V3 order-path fee confirmation, terms/entity reconciliation and product-specific restrictions.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='orion-funded' and p.slug in ('orion-zero','orion-nova','orion-standard','orion-swing','orion-select');
