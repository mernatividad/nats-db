-- The Trading Pit's current Forex CFD offers and complete public selector matrices.
-- Reviewed 2026-09-30. All programs stay in_review while rule/platform/commission conflicts are resolved.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('The Trading Pit','the-trading-pit','A simulated multi-asset CFD and futures provider whose Forex challenge products trade Forex CFDs rather than spot Forex.','https://www.thetradingpit.com/cfds-prop-trading','published','forex',now())
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
 status='published',market_type='forex',published_at=coalesce(bullish_banana.firms.published_at,now()),
 archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='the-trading-pit'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'LI','The Trading Pit Challenge GmbH',array['Forex CFDs','Metals CFDs','Energy CFDs','Index CFDs','Crypto CFDs','Equity CFDs','Futures']::text[],
 '{
   "service_model":"Official disclosure says all accounts use virtual funds and all trading occurs in a simulated environment. CFD Forex exposure is through CFDs; the firm says it does not offer spot Forex.",
   "legal_entity":"The Trading Pit Challenge GmbH, registration FL-0002.693.417-1, Vaduz, Liechtenstein. The site separately identifies The Trading Pit AG as holding company, The Trading Pit Champions GmbH as platform-services company, and The Trading Pit Limited as group business and administration services.",
   "platforms":"Instant CFDs specifically lists TTP MT5 and cTrader. Prime CFD FAQ says cTrader and other platforms can be selected in the Client Area before purchase but does not publish the full current platform list or map choices to individual sizes. No Prime program-platform assignments are inferred.",
   "supported_assets_note":"The current CFD selector lists Forex, metals, energies, cash indices, futures, crypto and equities. Forex instrument list displays 1:50 leverage and $5 per-lot commission; Instant commission help instead says $6 per lot. Preserve the commission discrepancy by source and product.",
   "jurisdiction_notes":"The service-wide FAQ restricts Burundi, Cuba, Iran, North Korea, South Sudan and Sudan. The CFD page additionally names the United States, Canada and Russia as CFD-restricted. Other product and data-provider limits may apply by residence; the Client Area may suppress unavailable offers.",
   "current_programs":["Prime 1-phase CFD Challenge","Prime 2-phase CFD Challenge","Instant CFD Earning Account"],
   "discovery_classification":"PropFirmMatch is a discovery/reference source only. Official pages classify these as simulated Forex CFD offers, not spot-Forex accounts.",
   "publication_note":"Official selector and Help Center refreshed 2026-09-30. Firm profile facts are recorded; all program records remain in_review pending day-rule cohorts, Prime platform mapping, and Forex commission reconciliation."
 }'::jsonb
from bullish_banana.firms where slug='the-trading-pit'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
 supported_assets=excluded.supported_assets,
 profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,updated_at=now();

insert into bullish_banana.restrictions (firm_id,country_code,restriction_type,note)
select f.id,x.country_code,'restricted',x.note
from bullish_banana.firms f
join (values
 ('BI','Service-wide restriction stated by the current official Help Center country FAQ, reviewed 2026-09-30.'),
 ('CU','Service-wide restriction stated by the current official Help Center country FAQ, reviewed 2026-09-30.'),
 ('IR','Service-wide restriction stated by the current official Help Center country FAQ, reviewed 2026-09-30.'),
 ('KP','Service-wide restriction stated by the current official Help Center country FAQ, reviewed 2026-09-30.'),
 ('SS','Service-wide restriction stated by the current official Help Center country FAQ, reviewed 2026-09-30.'),
 ('SD','Service-wide restriction stated by the current official Help Center country FAQ, reviewed 2026-09-30.'),
 ('US','CFD-specific restriction stated by the official CFD website disclosure, reviewed 2026-09-30.'),
 ('CA','CFD-specific restriction stated by the official CFD website disclosure, reviewed 2026-09-30.'),
 ('RU','CFD-specific restriction stated by the official CFD website disclosure, reviewed 2026-09-30.')
) as x(country_code,note) on true
where f.slug='the-trading-pit'
on conflict (firm_id,country_code) do update
set restriction_type=excluded.restriction_type,note=excluded.note,updated_at=now();

insert into bullish_banana.programs (
 firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
 max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,news_allowed,
 weekend_holding_allowed,commercial_details,published_at,archived_at
)
select f.id,x.name,x.slug,x.description,x.program_type,'forex','in_review','USD',x.sizes::jsonb,
 50::numeric,80::numeric,x.payout,null::integer,null::boolean,null::boolean,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('Prime 1-phase CFD Challenge','prime-1-phase-cfd','One-phase simulated Forex CFD evaluation with a 10% target and balance-dependent loss rules.','evaluation','[2500,5000,10000,20000,50000,100000,200000]','Every 14 days after the earning-account eligibility conditions are met',
  '{
    "account_size_prices":[{"account_size":2500,"fee":29,"currency":"USD"},{"account_size":5000,"fee":49,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":20000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":349,"currency":"USD"},{"account_size":100000,"fee":569,"currency":"USD"},{"account_size":200000,"fee":1139,"currency":"USD"}],
    "size_rule_variants":[{"account_size":2500,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"static","selector_day_label":"3 minimum profitable trading days"},{"account_size":5000,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"not labeled in current selector","selector_day_label":"3 minimum trading days"},{"account_size":10000,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"not labeled in current selector","selector_day_label":"3 minimum trading days"},{"account_size":20000,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"not labeled in current selector","selector_day_label":"3 minimum trading days"},{"account_size":50000,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"static per prior selector capture","selector_day_label":"3 minimum trading days"},{"account_size":100000,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"trailing on end-of-day balance","selector_day_label":"3 minimum trading days"},{"account_size":200000,"profit_target_percent":10,"daily_drawdown_percent":3,"maximum_drawdown_percent":6,"maximum_drawdown_method":"trailing on end-of-day balance","selector_day_label":"3 minimum trading days"}],
    "evaluation_rules":"Every selector size shows a 10% target, 3% balance-based daily drawdown and three days. Current reward-policy cohorts differ: 1-phase $100K/$200K accounts created from 2026-07-06 require three trading days, profitable or not, plus a 50% consistency rule based on Positive Days Profit; the public policy describes three qualifying profitable days for other purchase-date cohorts. Confirm terms by purchase date.",
    "funded_rules":"80% share. Current Prime policy sets a 14-day reward cadence and $100 minimum, with purchase-date-specific day/consistency requirements. Exact scaling eligibility remains subject to official terms.",
    "forex_scope":"Forex CFDs; official source says spot Forex is not offered.",
    "platform_details":"CFD platform FAQ requires a platform choice in Client Area before purchase but does not identify the exhaustive current Prime choices or account-level mapping. Not stated for this specific selector configuration.",
    "commission_details":"Current selector instrument list displays $5 per lot for Forex instruments; confirm whether this applies to each Prime platform/account.",
    "price_capture":"Base USD prices displayed by live official CFD selector on 2026-09-30; the page remains dynamic.",
    "open_items":["Resolve selector day-label and purchase-date reward policy distinctions","Confirm maximum-loss method where selector omitted it","Verify current Prime platform choices and per-account assignment","Confirm Forex commissions by platform"]
  }'),
 ('Prime 2-phase CFD Challenge','prime-2-phase-cfd','Two-phase simulated Forex CFD evaluation with 10% and 5% targets and size-dependent loss limits.','evaluation','[2500,5000,10000,20000,50000,100000]','Every 14 days after the earning-account eligibility conditions are met',
  '{
    "account_size_prices":[{"account_size":2500,"fee":29,"currency":"USD"},{"account_size":5000,"fee":49,"currency":"USD"},{"account_size":10000,"fee":99,"currency":"USD"},{"account_size":20000,"fee":199,"currency":"USD"},{"account_size":50000,"fee":349,"currency":"USD"},{"account_size":100000,"fee":569,"currency":"USD"}],
    "size_rule_variants":[{"account_size":2500,"phase_targets_percent":[10,5],"daily_drawdown_percent":5,"maximum_drawdown_percent":10,"maximum_drawdown_method":"static","selector_day_label":"3 minimum profitable trading days"},{"account_size":5000,"phase_targets_percent":[10,5],"daily_drawdown_percent":5,"maximum_drawdown_percent":10,"maximum_drawdown_method":"static","selector_day_label":"3 minimum trading days"},{"account_size":10000,"phase_targets_percent":[10,5],"daily_drawdown_percent":5,"maximum_drawdown_percent":10,"maximum_drawdown_method":"static","selector_day_label":"3 minimum trading days"},{"account_size":20000,"phase_targets_percent":[10,5],"daily_drawdown_percent":5,"maximum_drawdown_percent":10,"maximum_drawdown_method":"static","selector_day_label":"3 minimum trading days"},{"account_size":50000,"phase_targets_percent":[10,5],"daily_drawdown_percent":4,"maximum_drawdown_percent":8,"maximum_drawdown_method":"static","selector_day_label":"3 minimum trading days"},{"account_size":100000,"phase_targets_percent":[10,5],"daily_drawdown_percent":4,"maximum_drawdown_percent":8,"maximum_drawdown_method":"trailing on end-of-day balance","selector_day_label":"3 minimum trading days"}],
    "evaluation_rules":"The current selector shows 10% then 5% targets for every available size. Daily and max loss limits vary by size as captured in size_rule_variants. Selector day labels vary; current public reward policy is purchase-date sensitive. Confirm evaluation and funded-stage day rules against current account terms.",
    "funded_rules":"80% share. Current Prime policy sets a 14-day reward cadence and $100 minimum; reward eligibility is date and account dependent.",
    "forex_scope":"Forex CFDs; official source says spot Forex is not offered.",
    "platform_details":"CFD platform FAQ requires a platform choice in Client Area before purchase but does not identify the exhaustive current Prime choices or account-level mapping. Not stated for this specific selector configuration.",
    "commission_details":"Current selector instrument list displays $5 per lot for Forex instruments; confirm whether this applies to each Prime platform/account.",
    "price_capture":"Base USD prices displayed by live official CFD selector on 2026-09-30; the page remains dynamic.",
    "open_items":["Resolve selector day-label and purchase-date reward policy distinctions","Confirm current Prime platform choices and per-account assignment","Confirm Forex commissions by platform"]
  }'),
 ('Instant CFD Earning Account','instant-cfd-earning-account','No-evaluation simulated Forex CFD account with size-specific loss, position-risk and reward limits.','instant_funding','[5000,10000,20000,50000,100000]','Every 14 days for requests above $200 after applicable requirements',
  '{
    "account_size_prices":[{"account_size":5000,"fee":139,"currency":"USD"},{"account_size":10000,"fee":279,"currency":"USD"},{"account_size":20000,"fee":549,"currency":"USD"},{"account_size":50000,"fee":999,"currency":"USD"},{"account_size":100000,"fee":1799,"currency":"USD"}],
    "size_rule_variants":[{"account_size":5000,"maximum_drawdown_percent":6,"max_position_loss_percent":1,"consistency_percent":30,"reward_cap":2500,"reward_cap_rule":"lower of 50% of realized profit or cap"},{"account_size":10000,"maximum_drawdown_percent":6,"max_position_loss_percent":1,"consistency_percent":30,"reward_cap":2500,"reward_cap_rule":"lower of 50% of realized profit or cap"},{"account_size":20000,"maximum_drawdown_percent":6,"max_position_loss_percent":1,"consistency_percent":30,"reward_cap":2500,"reward_cap_rule":"lower of 50% of realized profit or cap"},{"account_size":50000,"maximum_drawdown_percent":6,"max_position_loss_percent":0.5,"consistency_percent":25,"reward_cap":3500,"reward_cap_rule":"lower of 50% of realized profit or cap"},{"account_size":100000,"maximum_drawdown_percent":6,"max_position_loss_percent":0.5,"consistency_percent":20,"reward_cap":4500,"reward_cap_rule":"lower of 50% of realized profit or cap"}],
    "funded_rules":"No challenge phase. Current selector shows 80% share, two-account maximum, limited weekend holding, 6% maximum drawdown, and size-specific max-position-loss and consistency values. Reward policy: first request after 14 days; later requests every 14 days; request must exceed $200; after first reward, any positive profit since previous request qualifies; cap is the lower of 50% of realized profit or the account-size amount above.",
    "forex_scope":"Forex CFDs; official source says spot Forex is not offered.",
    "platforms":["TTP MT5","cTrader"],
    "commission_details":"Selector Forex instrument list displays $5 per lot. Dedicated CFDs Instant commission FAQ says $6 per Forex lot. Preserve this official-source conflict pending confirmation.",
    "fee_refund_policy":"Official CFDs Instant FAQ states that the Instant fee is non-refundable.",
    "price_capture":"Base USD prices displayed by live official CFD selector on 2026-09-30; no checkout submitted.",
    "open_items":["Reconcile $5 selector commission and $6 Instant FAQ commission","Confirm if 6% loss method is static or otherwise defined in current Instant rules"]
  }')
) as x(name,slug,description,program_type,sizes,payout,details) on true
where f.slug='the-trading-pit'
on conflict (firm_id,slug) do update
set firm_id=excluded.firm_id,name=excluded.name,description=excluded.description,
 program_type=excluded.program_type,market_type=excluded.market_type,status='in_review',currency=excluded.currency,
 account_sizes=excluded.account_sizes,max_leverage=excluded.max_leverage,
 profit_split_percent=excluded.profit_split_percent,payout_frequency=excluded.payout_frequency,
 minimum_trading_days=null,news_allowed=null,weekend_holding_allowed=null,
 commercial_details=bullish_banana.programs.commercial_details || excluded.commercial_details,
 published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.program_phases (
 program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
 maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,x.drawdown_type,null,null,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('prime-1-phase-cfd',1,'Prime Evaluation',10::numeric,3::numeric,6::numeric,null::text,
  '{"size_rules":"See program commercial_details.size_rule_variants for the current selector matrix. Method is static at some sizes and EOD-trailing at $100K/$200K; selector does not label every size method.","selector_day_labels":"Selector label varies by selected size. Current Prime reward policy adds purchase-date-specific conditions; do not interpret a single day count as universal.","loss_reference":"Daily drawdown is balance based. Account-level maximum drawdown method is size-dependent."}'),
 ('prime-2-phase-cfd',1,'Prime Phase 1',10::numeric,5::numeric,10::numeric,'static',
  '{"base_configuration_size":2500,"size_rules":"See program commercial_details.size_rule_variants. $2.5K-$20K show 5% daily/10% static max; $50K shows 4% daily/8% static max; $100K shows 4% daily/8% trailing on EOD balance.","selector_day_labels":"Current selector reports 3 profitable days at $2.5K and 3 trading days for larger choices; verify challenge versus earning requirements in current account terms."}'),
 ('prime-2-phase-cfd',2,'Prime Phase 2',5::numeric,5::numeric,10::numeric,'static',
  '{"base_configuration_size":2500,"size_rules":"See program commercial_details.size_rule_variants for account-size differences; larger-size daily and max-loss fields differ from this base phase row.","selector_day_labels":"Current selector reports 3 profitable days at $2.5K and 3 trading days for larger choices; verify challenge versus earning requirements in current account terms."}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,rules) on x.program_slug=p.slug
where f.slug='the-trading-pit'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=excluded.daily_drawdown_percent,
 maximum_drawdown_percent=excluded.maximum_drawdown_percent,drawdown_type=excluded.drawdown_type,
 time_limit_days=excluded.time_limit_days,minimum_trading_days=excluded.minimum_trading_days,
 raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug)
values ('MetaTrader 5','metatrader-5'),('cTrader','ctrader')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select p.id,pl.id from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join bullish_banana.platforms pl on pl.slug in ('metatrader-5','ctrader')
where f.slug='the-trading-pit' and p.slug='instant-cfd-earning-account'
on conflict (program_id,platform_id) do nothing;

insert into bullish_banana.affiliate_destinations (firm_id,kind,label,destination_url,is_primary,status)
select id,'official_site','Visit The Trading Pit','https://www.thetradingpit.com/cfds-prop-trading',true,'active'
from bullish_banana.firms f where f.slug='the-trading-pit'
and not exists(select 1 from bullish_banana.affiliate_destinations d where d.firm_id=f.id and d.kind='official_site' and d.program_id is null);

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://www.thetradingpit.com/cfds-prop-trading','Current CFD selector and legal disclosure','Live Prime 1-phase, Prime 2-phase, and Instant selectors, size prices/rules, Forex instrument table, CFD restrictions, virtual-account disclosure and operator name reviewed 2026-09-30.'),
 ('https://support.thetradingpit.com/which-countries-are-not-supported-by-the-trading-pit-0','Service-wide country restrictions','Current Help Center lists service-wide restrictions and notes product eligibility can further vary by country; reviewed 2026-09-30.'),
 ('https://support.thetradingpit.com/what-is-the-prime-cfd-challenge','Prime challenge and payout overview','Current Prime challenge overview; reward eligibility and cadence remain attributed to official guide pending cohort reconciliation.'),
 ('https://support.thetradingpit.com/prime-cfd-payout-policy','Current Prime reward policy','Current purchase-date-dependent profitable-day and 1-phase $100K/$200K consistency terms reviewed 2026-09-30.'),
 ('https://support.thetradingpit.com/what-is-the-minimum-profitable-days-requirement-for-the-cfds-prime-challenge','Prime profitable-day calculation','Help Center describes 0.5% initial-balance profitable-day calculation and 16:15 CT cutoff; compare with cohort policy before publication.'),
 ('https://support.thetradingpit.com/what-is-the-payout-policy-for-cfds-instant','Instant reward policy','Current payout interval, threshold, consistency, cap and post-first-request profit requirements.'),
 ('https://support.thetradingpit.com/which-platforms-can-i-use-for-forex-trading','CFD challenge platform selection','FAQ says platforms are selected before purchase but does not provide exhaustive current Prime options or size-specific mapping.'),
 ('https://support.thetradingpit.com/which-platforms-are-available-for-cfds-instant','Instant platform availability','Current Instant offer lists TTP MT5 and cTrader.'),
 ('https://support.thetradingpit.com/what-are-the-commissions-for-cfds-instant','Instant Forex commission','Current Help Center says CFD Instant Forex commission is $6 per lot; selector table displays $5 per lot, so discrepancy remains.'),
 ('https://support.thetradingpit.com/is-the-cfds-instant-fee-refundable','Instant fee refund','Current Help Center says Instant fee is non-refundable.')
) as x(url,label,notes) on true where f.slug='the-trading-pit'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('prime-1-phase-cfd','https://www.thetradingpit.com/cfds-prop-trading','Prime 1-phase live selector','2026-09-30 size/fee/rule matrix; selector day wording varies by size.'),
 ('prime-1-phase-cfd','https://support.thetradingpit.com/prime-cfd-payout-policy','Prime reward policy by purchase cohort','Official date-specific payout/day/consistency rules.'),
 ('prime-1-phase-cfd','https://support.thetradingpit.com/which-platforms-can-i-use-for-forex-trading','Prime platform selection','Platform list and account mapping remain unstated in this FAQ.'),
 ('prime-2-phase-cfd','https://www.thetradingpit.com/cfds-prop-trading','Prime 2-phase live selector','2026-09-30 size/fee/rule matrix; phase targets and loss limits vary by account size.'),
 ('prime-2-phase-cfd','https://support.thetradingpit.com/prime-cfd-payout-policy','Prime reward policy by purchase cohort','Official date-specific payout/day requirements.'),
 ('prime-2-phase-cfd','https://support.thetradingpit.com/which-platforms-can-i-use-for-forex-trading','Prime platform selection','Platform list and account mapping remain unstated in this FAQ.'),
 ('instant-cfd-earning-account','https://www.thetradingpit.com/cfds-prop-trading','Instant live selector','2026-09-30 all current balance/fee options and selector terms.'),
 ('instant-cfd-earning-account','https://support.thetradingpit.com/what-is-the-payout-policy-for-cfds-instant','Instant rewards policy','Current reward interval, request threshold, account-size cap, consistency and subsequent request requirements.'),
 ('instant-cfd-earning-account','https://support.thetradingpit.com/which-platforms-are-available-for-cfds-instant','Instant platform availability','TTP MT5 and cTrader.'),
 ('instant-cfd-earning-account','https://support.thetradingpit.com/what-are-the-commissions-for-cfds-instant','Instant Forex commission','Help Center states $6 per Forex lot; selector instrument table displays $5.'),
 ('instant-cfd-earning-account','https://support.thetradingpit.com/is-the-cfds-instant-fee-refundable','Instant fee refund','Help Center states fee is non-refundable.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='the-trading-pit'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Official live CFD selector, platform and country Help Center sources reviewed 2026-09-30. Current Forex CFD classification, legal operator, virtual-account service model, market coverage and scoped country restrictions recorded. Program conflicts remain under review.'
from bullish_banana.firms f where slug='the-trading-pit'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Current official selector matrix reviewed 2026-09-30. Program remains in_review because Prime purchase-date day requirements/platform mapping and Forex commissions require reconciliation; Instant commission sources conflict.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='the-trading-pit' and p.slug in ('prime-1-phase-cfd','prime-2-phase-cfd','instant-cfd-earning-account')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);
