-- FXIFY current Forex products staged from official pages and selector, reviewed 2026-09-29.
-- All programs remain in_review while model variants, live price matrices and contract terms are reconciled.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('FXIFY','fxify','A simulated trading evaluation and funding provider offering multi-phase challenges and instant-funded accounts.','https://fxify.com/','published','forex',now())
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
 status='published',market_type='forex',published_at=coalesce(bullish_banana.firms.published_at,now()),
 archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='fxify'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'MU','Prime Intermarket Group Eurasia Ltd',array['Forex','Metals','Indices','Stocks']::text[],
 '{"service_model":"Programs describe simulated evaluation and funded accounts; specific client contract wording requires full Terms review.","legal_entity":"Prime Intermarket Group Eurasia Ltd, Mauritius, Investment Dealer license GB24204066. FXIFY Solutions Limited (UK company 14451720) is identified as a payment agent.","platforms":["MetaTrader 4","MetaTrader 5","DXtrade","TradingView"],"supported_assets_note":"FXIFY states access to 100+ instruments including stocks, metals, indices and FX. Instrument availability varies by program and feed and remains unverified.","jurisdiction_notes":"Official programs page lists the United States, Zimbabwe, Iran, Iraq, North Korea, Somalia, Vietnam, Burundi, Central African Republic, Ivory Coast, Liberia, Libya, Sudan, Cuba, Syria, Afghanistan, Yemen, Palestine, Myanmar, Nicaragua, Congo Republic, Crimea, Democratic Republic of Congo, Eritrea, Guinea, Guinea-Bissau, Papua New Guinea, South Sudan, Vanuatu, Venezuela, Algeria, Russia, Belarus, Kenya and Ghana, and any jurisdiction where use would violate local law. Age 18+.","current_programs":["One Phase","Two Phase Classic","Two Phase Standard","Two Phase Pro","Three Phase","Instant Funding Standard","Instant Funding Lite","Lightning Challenge"],"publication_note":"Official programs and product pages reviewed 2026-09-29. Program variants and selector terms remain in review."}'::jsonb
from bullish_banana.firms where slug='fxify'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
 supported_assets=excluded.supported_assets,
 profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,updated_at=now();

insert into bullish_banana.restrictions (firm_id,country_code,restriction_type,note)
select f.id,x.country_code,'restricted','Official FXIFY programs page restriction list reviewed 2026-09-29.'
from bullish_banana.firms f join (values
 ('US'),('ZW'),('IR'),('IQ'),('KP'),('SO'),('VN'),('BI'),('CF'),('CI'),('LR'),('LY'),('SD'),('CU'),('SY'),('AF'),('YE'),('PS'),('MM'),('NI'),('CG'),('CD'),('ER'),('GN'),('GW'),('PG'),('SS'),('VU'),('VE'),('DZ'),('RU'),('BY'),('KE'),('GH')
) as x(country_code) on true
where f.slug='fxify'
on conflict (firm_id,country_code) do update
set restriction_type=excluded.restriction_type,note=excluded.note,updated_at=now();

insert into bullish_banana.programs (
 firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
 max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,news_allowed,
 weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,x.program_type,'forex','in_review','USD',x.sizes::jsonb,
 x.leverage,x.split,x.payout,x.days,x.news,x.weekend,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('One Phase','one-phase','Single-phase simulated Forex evaluation with a 10% target and trailing maximum loss.','evaluation','[5000,10000,15000,25000,50000,100000,200000,400000]',50::numeric,90::numeric,'First payout on demand after first funded trade and five funded trading days; USD 50 minimum; monthly default, biweekly add-on',5::integer,true,true,'{"known_default_size":25000,"known_base_fee":199,"fee_capture":"Official page selector showed $199 base for $25K on 2026-09-28; current full size/fee matrix and feed/platform variants not captured.","phase_summary":"10% target; 3% daily loss based on previous-day end balance at 5PM EST; 6% trailing max loss stops trailing after 6% profit or payout; five minimum trading days; unlimited time.","funded_rules":"Up to 90% split; first payout on demand after first funded trade closes, with five minimum funded trading days and $50 minimum; monthly default or biweekly add-on. Exact default split/add-on terms need confirmation.","trading_conditions":"EA, weekend and news trading allowed on page. Up to 50:1 leverage; MT5, DXtrade or TradingView listed. Account-specific feed/platform terms need verification.","fee_refund_policy":"Page states fee is refundable; eligibility and timing need confirmation against current refund terms.","open_items":["Full size and fee matrix","RAW/All-In selection effects","contract/refund terms","platform-by-account mapping"]}'),
 ('Two Phase Classic','two-phase-classic','Two-phase simulated Forex evaluation using static drawdown and a 5% / 10% target structure.','evaluation','[5000,10000,15000,25000,50000,100000]',30::numeric,80::numeric,'First payout on demand after first funded trade and five funded trading days; later every 14 or 30 days',4::integer,true,true,'{"known_default_size":5000,"known_base_fee":59,"price_capture":"Official live selector showed $59 base for $5K on 2026-09-29; full matrix not captured.","phase_summary":"Live selector identifies Classic, static drawdown, phase 1 target 5%, daily loss 4%, maximum static drawdown 10%, four minimum trading days and unlimited time. Official comparison article describes phase targets 5%/10%; phase-specific current selector values remain to be captured.","funded_rules":"Selector says up to 100% split, no payout on demand, payout frequency 14 or 30 days. Shared payout text says first withdrawal can be requested after first funded trade and five minimum funded days; conflict remains.","trading_conditions":"EA, weekend and news trading allowed per live selector. Standard leverage up to 30:1, optional increase; MT5, DXtrade or TradingView.","open_items":["phase-specific targets and day rules","full price matrix","payout cadence conflict","funded consistency requirements","refund and terms"]}'),
 ('Two Phase Standard','two-phase-standard','Two-phase simulated Forex evaluation with a 10% / 5% target structure and trailing drawdown.','evaluation','[5000,10000,15000,25000,50000,100000,150000,200000,250000,400000]',50::numeric,90::numeric,'First payout on demand after first funded trade and five funded trading days; monthly default',5::integer,true,true,'{"phase_summary":"Official FXIFY comparison article describes 10% / 5% targets, 4% daily loss, 10% trailing maximum loss that locks at breakeven, five minimum trading days and no consistency rule. Current live page selector was on Classic; Standard-specific selector capture is pending.","funded_rules":"Up to 90% split and first payout on demand are described in official materials; current Standard funded terms need confirmation.","trading_conditions":"Official shared page lists MT5, DXtrade, TradingView and optional 50:1 leverage; product-specific availability pending.","open_items":["confirm currently purchasable variant","full fee matrix","variant-specific payout and funded terms","platform/feed mapping","refund and terms"]}'),
 ('Two Phase Pro','two-phase-pro','Two-phase simulated Forex evaluation with lower phase targets, static drawdown and a funded profit cap.','evaluation','[10000,25000,50000,100000,150000,200000,250000]',50::numeric,80::numeric,'Every 10 days after three minimum days',3::integer,true,true,'{"phase_summary":"Official Pro article states 4% / 8% targets, 4% daily loss, 8% static max loss and three minimum profitable days per phase; no evaluation consistency rule.","funded_rules":"80% split; $4,000 daily profit cap, above which account becomes read-only. Payout every 10 days after three minimum days. First two withdrawals capped at 5% initial balance or $8,000; third onward uncapped.","account_size_prices":[{"account_size":10000,"fee":129},{"account_size":25000,"fee":225},{"account_size":50000,"fee":375},{"account_size":100000,"fee":599},{"account_size":150000,"fee":849},{"account_size":200000,"fee":1099},{"account_size":250000,"fee":1350}],"price_capture":"Official FXIFY Pro announcement fee table; current selector confirmation pending.","trading_conditions":"Shared official page lists MT5, DXtrade, TradingView and optional 50:1 leverage; product-specific mapping pending.","open_items":["confirm current selector availability","funded day qualifier","platform/feed mapping","refund and current terms"]}'),
 ('Three Phase','three-phase','Three-phase simulated Forex evaluation with a 5% target per phase.','evaluation','[5000,10000,15000,25000,50000,100000,200000,400000]',50::numeric,90::numeric,'First payout on demand after first funded trade and five funded trading days; monthly default, biweekly add-on',5::integer,true,true,'{"known_default_size":25000,"known_base_fee":149,"fee_capture":"Official page selector showed $149 base for $25K on 2026-09-28; full matrix not captured.","phase_summary":"5% target per phase; 5% daily loss; 5% static maximum loss; five minimum trading days; unlimited time.","funded_rules":"Up to 90% split. First payout on demand after first funded trade, five minimum funded trading days and $50 minimum; monthly default or biweekly add-on. Exact default split/add-on arithmetic requires confirmation.","trading_conditions":"EA, weekend and news trading allowed per page; up to 50:1 leverage; MT5, DXtrade or TradingView listed.","fee_refund_policy":"Page states fee refundable; current refund terms need confirmation.","open_items":["full size and fee matrix","RAW/All-In variants","contract/refund terms","platform-by-size mapping"]}'),
 ('Instant Funding Standard','instant-funding-standard','No-evaluation simulated Forex funding account with an 8% trailing maximum loss.','instant_funding','[1000,5000,10000,25000,50000,100000]',50::numeric,80::numeric,'First payout after 14 days; USD 50 minimum',null::integer,true,false,'{"phase_summary":"No profit target or minimum trading days. Official Instant Funding FAQ describes 8% trailing maximum loss, which locks at starting balance after 8% profit or a payout; 60-day inactivity breach.","funded_rules":"First payout after 14 days with $50 minimum per official FAQ. Exact recurring cadence, default split and funded trading conditions need verification.","account_size_prices_note":"Official 2026 Lite-vs-Standard article describes $1K-$100K range and $69 starting fee; full current matrix and selector confirmation pending.","trading_conditions":"Program-specific platform, weekend/news/EA and leverage terms need verification.","open_items":["current size/fee matrix","payout schedule","profit split","trading conditions","refund/terms"]}'),
 ('Instant Funding Lite','instant-funding-lite','No-evaluation simulated Forex account with tighter drawdown and a consistency rule.','instant_funding','[2500,5000,10000,25000,50000,100000]',50::numeric,80::numeric,'After 10 trading days including five active days; USD 50 minimum',null::integer,false,false,'{"account_size_prices":[{"account_size":2500,"fee":19},{"account_size":5000,"fee":39},{"account_size":10000,"fee":79},{"account_size":25000,"fee":149},{"account_size":50000,"fee":249},{"account_size":100000,"fee":399}],"price_capture":"Official Lite launch article price matrix; not yet verified against live selector.","phase_summary":"No target; 3% daily drawdown, 4% trailing maximum drawdown and 20% consistency rule.","funded_rules":"80% default split with 90% upgrade. First payout after 10 trading days including five active days and $50 minimum.","trading_conditions":"No weekend holding, EAs or copy trading; high-impact news restricted within five minutes. 50:1 Forex leverage; RAW feed; MT5, DXtrade and TradingView stated in launch article.","open_items":["current selector confirmation","base fee vs current promotions","terms and refund","precise activity/day semantics"]}'),
 ('Lightning Challenge','lightning-challenge','FXIFY Lightning simulated Forex evaluation; current rules and variant details require selector verification.','evaluation','[]',50::numeric,null::numeric,'Not stated',null::integer,null::boolean,null::boolean,'{"phase_summary":"Current Programs page lists Lightning Challenge. Product-specific phase rules, account sizes and fee matrix were not captured in this review.","open_items":["current purchasable Forex variants","size and fee matrix","phase targets and drawdowns","payout terms","platform/feed and trading conditions","refund and contract terms"]}')
) as x(name,slug,description,program_type,sizes,leverage,split,payout,days,news,weekend,details) on true
where f.slug='fxify'
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
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-phase',1,'Evaluation',10::numeric,3::numeric,6::numeric,'trailing',5::integer,'{"daily_loss_reference":"Previous-day end balance at 5PM EST","trailing_lock":"Stops trailing after 6% profit or a payout","day_requirement_label":"5 trading days"}'),
 ('two-phase-classic',1,'Phase 1',5::numeric,4::numeric,10::numeric,'static',4::integer,'{"target_variant_conflict":"Live selector on 2026-09-29 displayed phase 1 at 5%; official comparison article reports 5% / 10% targets. Phase 2 selector capture pending.","day_requirement_label":"4 trading days"}'),
 ('two-phase-classic',2,'Phase 2',10::numeric,4::numeric,10::numeric,'static',4::integer,'{"target_variant_conflict":"Phase 2 target from official comparison article; current selector capture pending.","day_requirement_label":"4 trading days"}'),
 ('two-phase-standard',1,'Phase 1',10::numeric,4::numeric,10::numeric,'trailing',5::integer,'{"source_note":"Official comparison article; verify live Standard selector before publication.","day_requirement_label":"5 trading days"}'),
 ('two-phase-standard',2,'Phase 2',5::numeric,4::numeric,10::numeric,'trailing',5::integer,'{"source_note":"Official comparison article; verify live Standard selector before publication.","day_requirement_label":"5 trading days"}'),
 ('two-phase-pro',1,'Phase 1',4::numeric,4::numeric,8::numeric,'static',3::integer,'{"minimum_profitable_days":3,"day_requirement_label":"3 profitable trading days"}'),
 ('two-phase-pro',2,'Phase 2',8::numeric,4::numeric,8::numeric,'static',3::integer,'{"minimum_profitable_days":3,"day_requirement_label":"3 profitable trading days"}'),
 ('three-phase',1,'Phase 1',5::numeric,5::numeric,5::numeric,'static',5::integer,'{"day_requirement_label":"5 trading days"}'),
 ('three-phase',2,'Phase 2',5::numeric,5::numeric,5::numeric,'static',5::integer,'{"day_requirement_label":"5 trading days"}'),
 ('three-phase',3,'Phase 3',5::numeric,5::numeric,5::numeric,'static',5::integer,'{"day_requirement_label":"5 trading days"}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,days,rules) on x.program_slug=p.slug
where f.slug='fxify'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=excluded.daily_drawdown_percent,maximum_drawdown_percent=excluded.maximum_drawdown_percent,
 drawdown_type=excluded.drawdown_type,time_limit_days=excluded.time_limit_days,
 minimum_trading_days=excluded.minimum_trading_days,raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug)
values ('MetaTrader 4','metatrader-4'),('MetaTrader 5','metatrader-5'),('DXtrade','dxtrade'),('TradingView','tradingview')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select p.id,pl.id from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
join bullish_banana.platforms pl on pl.slug in ('metatrader-4','metatrader-5','dxtrade','tradingview')
where f.slug='fxify' and p.slug in ('one-phase','two-phase-classic','two-phase-standard','two-phase-pro','three-phase','instant-funding-standard','instant-funding-lite','lightning-challenge')
on conflict (program_id,platform_id) do nothing;

insert into bullish_banana.affiliate_destinations (firm_id,kind,label,destination_url,is_primary,status)
select id,'official_site','Visit FXIFY','https://fxify.com/',true,'active' from bullish_banana.firms f
where f.slug='fxify' and not exists(select 1 from bullish_banana.affiliate_destinations d where d.firm_id=f.id and d.kind='official_site' and d.program_id is null);

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://fxify.com/programs/','Official Programs overview','Current product lineup, legal entity/payment agent, age and jurisdiction disclosures reviewed 2026-09-29.'),
 ('https://fxify.com/terms-and-conditions/','Terms and Conditions','Current terms landing page recorded; full service, refund and contracting clauses require review.'),
 ('https://fxify.com/programs/one-phase/','One Phase selector','Current $25K selector rules and base price captured 2026-09-28; full price and variant matrix pending.'),
 ('https://fxify.com/programs/two-phase/','Two Phase live selector','Live selector displayed Classic at $5K, $59 base and 5% phase-1 target on 2026-09-29; 4% daily, 10% static max, four days and other selector terms captured. Other variants need confirmation.'),
 ('https://fxify.com/programs/three-phase-challenge/','Three Phase selector','Current $25K selector rules and base price captured 2026-09-28; full price and variant matrix pending.'),
 ('https://fxify.com/programs/instant-funding/','Instant Funding page','Current product page reviewed; complete Standard terms and live fee matrix pending.'),
 ('https://fxify.com/programs/lightning-challenge/','Lightning Challenge page','Current product lineup confirmed; product-specific selector details pending.'),
 ('https://fxify.com/blog/introducing-fxify-2-phase-pro/','Two Phase Pro announcement','Official Pro comparison and account fee table reviewed 2026-09-29.'),
 ('https://fxify.com/blog/introducing-fxify-instant-funding-lite/','Instant Funding Lite launch','Official Lite fee table and program rules; live selector verification pending.'),
 ('https://fxify.com/faqs/all-faqs/instant-funded-faq/whats-the-max-drawdown-limit/','Instant Funding drawdown FAQ','Official Standard Instant Funding drawdown and lock terms.'),
 ('https://fxify.com/faqs/all-faqs/instant-funded-faq/whats-the-max-and-minimum-trading-days-is-there-a-specific-time-window-to-complete-the-profit-targets/','Instant Funding payout FAQ','Official Standard Instant Funding day and payout information.')
) as x(url,label,notes) on true where f.slug='fxify'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-phase','https://fxify.com/programs/one-phase/','One Phase current selector','$25K configuration and current page rules; complete price matrix and terms need capture.'),
 ('two-phase-classic','https://fxify.com/programs/two-phase/','Two Phase Classic current selector','Live selector currently identifies Classic; phase-specific and payout conflicts remain open.'),
 ('two-phase-standard','https://fxify.com/blog/top-prop-firms-with-two-phase-challenges/','Two Phase Standard comparison','Official comparison article for Standard targets and rules; current selector availability and full terms pending.'),
 ('two-phase-pro','https://fxify.com/blog/introducing-fxify-2-phase-pro/','Two Phase Pro rules and prices','Official Pro comparison and fee matrix.'),
 ('three-phase','https://fxify.com/programs/three-phase-challenge/','Three Phase current selector','Current $25K configuration; complete size/price matrix and terms need capture.'),
 ('instant-funding-standard','https://fxify.com/programs/instant-funding/','Instant Funding Standard','Official product page and FAQ. Complete current selector price/platform terms pending.'),
 ('instant-funding-lite','https://fxify.com/blog/introducing-fxify-instant-funding-lite/','Instant Funding Lite rules and prices','Official launch article fee matrix; current selector confirmation pending.'),
 ('lightning-challenge','https://fxify.com/programs/lightning-challenge/','Lightning Challenge','Official product route; detailed offer and selector facts remain uncaptured.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='fxify' and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Official FXIFY Programs, current product pages, Pro announcement, Lite launch article and Instant Funding FAQs reviewed 2026-09-29. Operator, payment agent, restrictions and eight product candidates recorded. Current selector, terms and variant conflicts remain.'
from bullish_banana.firms f where slug='fxify'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'First-party product page/article/FAQ reviewed 2026-09-29. Staged in review; do not publish until offer availability, full account/fee matrix, payout/refund terms and platform/feed mapping are reconciled.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='fxify' and p.slug in ('one-phase','two-phase-classic','two-phase-standard','two-phase-pro','three-phase','instant-funding-standard','instant-funding-lite','lightning-challenge')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);
