-- WSFunded public Forex offers captured 2026-09-29.
-- All records remain in_review because first-party Terms/FAQ/selector sources conflict.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('Wall Street Funded', 'wall-street-funded', 'A virtual trading evaluation provider offering multi-asset Forex programs and immediate-access simulated accounts.', 'https://wsfunded.com/en', 'in_review', 'forex', null)
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'in_review', market_type = 'forex', published_at = null,
    archived_at = null, updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'wall-street-funded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'LC', 'WSFmarkets Ltd', array['Forex','Metals','Commodities','Indices','Cryptocurrencies','Stocks']::text[],
  $$ {
    "company_registration": "Saint Lucia company 2025-00117; official terms list Ground Floor, Rodney Court Building, Rodney Bay, Gros Islet, Saint Lucia.",
    "operational_entities": "WSF Technology FZCO is identified at Dubai Digital Park, Dubai, UAE. RENATICA LTD in Cyprus is identified as facilitating payment operations. These entities have different stated roles.",
    "service_model": "WSFmarkets Terms state accounts are demo accounts with fictitious funds and trading is simulated. The instant-account FAQ says real-money account, a material conflict; legal Terms control this provisional description pending clarification.",
    "platforms": "Official site names MetaTrader 5, cTrader, and MatchTrader. Availability by product has not been mapped.",
    "markets": "Forex, metals, commodities, indices, cryptocurrencies, and stocks are listed by official material.",
    "funding_capacity": "FAQ says funded accounts may be combined to $400,000. Separate scaling materials advertise growth up to $2,000,000; they describe different conditions.",
    "jurisdiction_conflict": "Terms list United States, Singapore, Russia, UAE, FATF/sanctioned jurisdictions; FAQ separately lists Cuba, Sudan, Somalia, Iran, Lebanon, Syria, North Korea, Libya, Pakistan, and Vietnam. Confirm complete current checkout eligibility.",
    "operating_status": "Current public challenge selector, purchase links, current Help Center challenge collection, and 2026-dated terms reviewed 2026-09-29.",
    "profile_review": "Resolve simulated-vs-real instant account language, region restrictions, the Classic/Ultra leverage discrepancy, and per-product platforms before publication."
  } $$::jsonb
from bullish_banana.firms where slug = 'wall-street-funded'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details,
  published_at, archived_at
)
select f.id, x.name, x.slug, x.description, x.program_type, 'forex', 'in_review', 'USD',
       x.account_sizes::jsonb, x.max_leverage, x.split, x.payout, x.minimum_days,
       x.news_allowed, null, x.details::jsonb, null, null
from bullish_banana.firms f
join (values
 ('Wall Street Rapid','rapid','Single-phase Forex evaluation with a 10% target and static total loss limit.','evaluation','[2500,5000,10000,25000,50000,100000]',30::numeric,80::numeric,'First payout after 30 days; then every 10 days',4,true,
  $$ {"account_size_prices":[{"account_size":2500,"fee":25,"currency":"USD"},{"account_size":5000,"fee":57,"list_fee":69,"currency":"USD"},{"account_size":10000,"fee":95,"list_fee":105,"currency":"USD"},{"account_size":25000,"fee":199,"list_fee":259,"currency":"USD"},{"account_size":50000,"fee":299,"list_fee":379,"currency":"USD"},{"account_size":100000,"fee":529,"list_fee":589,"currency":"USD"}],"pricing_note":"Official public selector displayed paired amounts on 2026-09-29. Treat lower figures as observed current price, not permanent fee; confirm promotion and final checkout amount.","forex_leverage":"1:30","drawdown_type":"Static maximum loss; daily limit resets each day and uses floating equity with open positions or start-of-day closed balance without open positions.","minimum_trading_days":"4 trading days.","time_limit":"No maximum time limit.","profit_split":"80%.","payout_rules":"First withdrawal after 30 days, subsequent every 10 days from activation.","funded_rules":"30-day inactivity; maximum risk per idea equals 50% of daily drawdown; stop loss must be added within two minutes.","news_rule":"Official help material says the major-news execution restriction applies only to simulated funded accounts, not challenge phases.","platforms":"MT5, cTrader, and MatchTrader are advertised generally; per-account availability not verified.","review_note":"Keep in review until pricing semantics, platform mapping, jurisdiction list, and account-specific terms are confirmed."} $$),
 ('Wall Street Power','power','One-phase Forex evaluation with an initial low payment and a separate payment when moving to the simulated funded stage.','evaluation','[5000,10000,25000,50000,100000]',30::numeric,80::numeric,'First payout after 14 days; then every 14 days',null,true,
  $$ {"account_size_prices":[{"account_size":5000,"fee":9.99,"post_pass_fee":48,"currency":"USD"},{"account_size":10000,"fee":9.99,"post_pass_fee":76,"currency":"USD"},{"account_size":25000,"fee":9.99,"post_pass_fee":180,"currency":"USD"},{"account_size":50000,"fee":9.99,"post_pass_fee":340,"currency":"USD"},{"account_size":100000,"fee":9.99,"post_pass_fee":540,"currency":"USD"}],"pricing_note":"Official Power Help Center labels $9.99 as initial price and the second amount as funded price, billed upon moving to Funded; modelled separately, captured 2026-09-29.","forex_leverage":"1:30","drawdown_type":"Static maximum loss.","funded_requirements":"3 profitable days of at least 0.5% apply only to the funded stage, not the challenge.","consistency_rule":"20%; no trading day's profit may exceed 20% of total profits.","risk_rule":"Maximum risk per trading idea is 1% of account balance.","payout_rules":"First withdrawal after 14 days; subsequent withdrawals every 14 days.","platforms":"MT5 only.","jurisdiction_restriction":"Official product page excludes Spain and Andorra.","review_note":"Firm-level country restrictions, account agreement, and sale availability require reconciliation before publication."} $$),
 ('Wall Street Classic','classic','Two-phase Forex evaluation with 8% and 5% targets and an 8% static total loss limit.','evaluation','[2500,5000,10000,25000,50000,100000]',null::numeric,80::numeric,'First payout after 15 days; then every 10 days',4,true,
  $$ {"account_size_prices":[{"account_size":2500,"fee":27,"list_fee":33,"currency":"USD"},{"account_size":5000,"fee":55,"list_fee":59,"currency":"USD"},{"account_size":10000,"fee":87,"list_fee":99,"currency":"USD"},{"account_size":25000,"fee":193,"list_fee":259,"currency":"USD"},{"account_size":50000,"fee":319,"list_fee":369,"currency":"USD"},{"account_size":100000,"fee":563,"list_fee":579,"currency":"USD"}],"pricing_note":"Official public selector showed paired list/current values on 2026-09-29; verify any promotion and final checkout price.","forex_leverage":"Not stated in this draft: public comparison lists 1:100, official leverage FAQ lists 1:50.","drawdown_type":"Static maximum loss; daily threshold resets each day and uses floating equity with open positions or start-of-day closed balance otherwise.","targets":"Phase 1: 8%; Phase 2: 5%.","minimum_trading_days":"4 trading days.","time_limit":"No maximum time limit.","profit_split":"80%.","payout_rules":"First payout after 15 days; recurring payout every 10 days.","funded_rules":"30-day inactivity; per-idea risk limit is 50% of daily drawdown; stop loss required within two minutes.","news_rule":"Official help material says the major-news execution restriction applies only to simulated funded accounts, not challenge phases.","platforms":"MT5, cTrader, and MatchTrader are advertised generally; per-account availability not verified.","review_note":"Leverage sources conflict; resolve with the current account selector or signed offer before publishing."} $$),
 ('Wall Street Ultra','ultra','Two-phase Forex evaluation with 10% and 5% targets and a 10% static total loss limit.','evaluation','[2500,5000,10000,25000,50000,100000]',null::numeric,80::numeric,'First payout after 15 days; then every 10 days',4,true,
  $$ {"account_size_prices":[{"account_size":2500,"fee":23,"list_fee":33,"currency":"USD"},{"account_size":5000,"fee":49,"list_fee":59,"currency":"USD"},{"account_size":10000,"fee":79,"list_fee":89,"currency":"USD"},{"account_size":25000,"fee":193,"list_fee":209,"currency":"USD"},{"account_size":50000,"fee":299,"list_fee":349,"currency":"USD"},{"account_size":100000,"fee":529,"list_fee":559,"currency":"USD"}],"pricing_note":"Official public selector showed paired list/current values on 2026-09-29; verify any promotion and final checkout price.","forex_leverage":"Not stated in this draft: public comparison lists 1:100, official leverage FAQ lists 1:50.","drawdown_type":"Static maximum loss; daily threshold resets each day and uses floating equity with open positions or start-of-day closed balance otherwise.","targets":"Phase 1: 10%; Phase 2: 5%.","minimum_trading_days":"4 trading days.","time_limit":"No maximum time limit.","profit_split":"80%.","payout_rules":"First payout after 15 days; recurring payout every 10 days.","funded_rules":"30-day inactivity; per-idea risk limit is 50% of daily drawdown; stop loss required within two minutes.","news_rule":"Official help material says the major-news execution restriction applies only to simulated funded accounts, not challenge phases.","platforms":"MT5, cTrader, and MatchTrader are advertised generally; per-account availability not verified.","review_note":"Leverage sources conflict; resolve with the current account selector or signed offer before publishing."} $$),
 ('Wall Street Elite','elite','Two-phase Forex evaluation with 6% targets in both phases and no daily loss limit.','evaluation','[2500,5000,10000,25000,50000,100000]',50::numeric,80::numeric,'First payout after 30 days; then every 10 days',4,true,
  $$ {"account_size_prices":[{"account_size":2500,"fee":23.4,"currency":"USD"},{"account_size":5000,"fee":35.4,"list_fee":59,"currency":"USD"},{"account_size":10000,"fee":65.4,"list_fee":109,"currency":"USD"},{"account_size":25000,"fee":137.4,"list_fee":229,"currency":"USD"},{"account_size":50000,"fee":203.4,"list_fee":339,"currency":"USD"},{"account_size":100000,"fee":377.4,"list_fee":629,"currency":"USD"}],"pricing_note":"Official product page displays discounted and list prices on 2026-09-29; confirm promo eligibility and checkout amount.","forex_leverage":"1:50 according to the official leverage FAQ.","drawdown_type":"Static maximum loss; there is no daily drawdown limit.","targets":"Phase 1: 6%; Phase 2: 6%.","minimum_trading_days":"4 trading days.","time_limit":"No maximum time limit.","profit_split":"80%.","payout_rules":"First withdrawal after 30 days, then every 10 days.","funded_rules":"30-day inactivity; maximum risk per trade idea 2.5%; stop loss required within two minutes.","news_rule":"Official help material says the major-news execution restriction applies only to simulated funded accounts, not challenge phases.","platforms":"MT5, cTrader, and MatchTrader are advertised generally; per-account availability not verified.","review_note":"Current selector and Help Center pages agree on a two-phase 6%/6% model."} $$),
 ('Instant Pro','instant-pro','Immediate-access simulated Forex account with a 5% trailing loss limit and a 15% best-day consistency condition.','instant_funding','[2500,5000,10000,25000,50000,100000]',50::numeric,80::numeric,'First withdrawal after 15 days; then every 10 days',4,false,
  $$ {"account_size_prices":[{"account_size":2500,"fee":49,"list_fee":60,"currency":"USD"},{"account_size":5000,"fee":79,"list_fee":85,"currency":"USD"},{"account_size":10000,"fee":102,"list_fee":115,"currency":"USD"},{"account_size":25000,"fee":199,"list_fee":232,"currency":"USD"},{"account_size":50000,"fee":299,"list_fee":345,"currency":"USD"},{"account_size":100000,"fee":499,"list_fee":562,"currency":"USD"}],"pricing_note":"Official public selector showed paired list/current values on 2026-09-29; verify any promotion and final checkout price.","forex_leverage":"1:50.","drawdown_type":"5% trailing total loss; 3% daily loss calculated at 17:00 New York.","consistency_rule":"15%: largest profitable day must not exceed 15% of total profit before reward.","minimum_profitable_days":"4 days, each at least 0.5% of initial balance, before reward.","risk_rule":"Maximum loss per trade idea is 1% of initial balance.","payout_rules":"First withdrawal after 15 days, subsequent every 10 days; account share is 80% in the official comparison. Minimum amount is conditioned on consistency/best-day rules.","news_rule":"Funded account news restriction: do not open or close instruments affected by major red-folder events from 4 minutes before through 4 minutes after; positions may be held through the window.","simulated_account_conflict":"Help Center calls instant access real money; Terms say all accounts are simulated demo accounts.","platforms":"MT5, cTrader, and MatchTrader are advertised generally; per-account availability not verified.","review_note":"Resolve instant-account nature, pricing semantics, restrictions and product-specific platform before publication."} $$),
 ('Instant Standard','instant-standard','Immediate-access simulated Forex account with a 6% trailing loss limit and a 30% best-day consistency condition.','instant_funding','[2500,5000,10000,25000,50000]',30::numeric,80::numeric,'First withdrawal after 15 days; then every 10 days',4,false,
  $$ {"account_size_prices":[{"account_size":2500,"fee":90,"list_fee":105,"currency":"USD"},{"account_size":5000,"fee":225,"list_fee":250,"currency":"USD"},{"account_size":10000,"fee":440,"list_fee":465,"currency":"USD"},{"account_size":25000,"fee":800,"list_fee":845,"currency":"USD"},{"account_size":50000,"fee":1800,"list_fee":1869,"currency":"USD"}],"pricing_note":"Official public selector showed paired list/current values on 2026-09-29; verify any promotion and final checkout price.","forex_leverage":"1:30.","drawdown_type":"6% trailing total loss; 3% daily loss calculated at 17:00 New York.","consistency_rule":"30%: largest profitable day must not exceed 30% of total profit before reward.","minimum_profitable_days":"4 days, each at least 0.5% of initial balance, before reward.","risk_rule":"Maximum loss per trade idea is 1% of initial balance.","payout_rules":"First withdrawal after 15 days, subsequent every 10 days; account share is 80% in the official comparison. Minimum amount is conditioned on consistency/best-day rules.","news_rule":"Funded account news restriction: do not open or close instruments affected by major red-folder events from 4 minutes before through 4 minutes after; positions may be held through the window.","simulated_account_conflict":"Help Center calls instant access real money; Terms say all accounts are simulated demo accounts.","platforms":"MT5, cTrader, and MatchTrader are advertised generally; per-account availability not verified.","review_note":"Resolve instant-account nature, pricing semantics, restrictions and product-specific platform before publication."} $$)
) as x(name,slug,description,program_type,account_sizes,max_leverage,split,payout,minimum_days,news_allowed,details)
  on true
where f.slug = 'wall-street-funded'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'in_review', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    commercial_details = excluded.commercial_details, published_at = null,
    archived_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.max_loss,
       x.drawdown_type, x.time_limit_days, x.minimum_days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
 ('rapid',1,'Evaluation',10::numeric,4::numeric,6::numeric,'Static',null::integer,4,'{"source_note":"Official Rapid Help Center, captured 2026-09-29.","time_limit":"No maximum time limit.","loss_calculation":"Daily loss uses floating equity with open trades; otherwise start-of-day closed balance."}'),
 ('power',1,'Evaluation',6::numeric,3::numeric,6::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Power Help Center, captured 2026-09-29.","minimum_days":"No evaluation minimum-day rule stated in the source; three 0.5% days apply only after funding.","daily_loss":"Equity-based with open positions, otherwise start-of-day closed balance."}'),
 ('classic',1,'Phase 1',8::numeric,5::numeric,8::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Classic Help Center, captured 2026-09-29.","time_limit":"No maximum time limit.","minimum_days":"Four minimum trading days for the challenge overall; the source does not require four in each phase.","leverage_conflict":"Official main selector lists 1:100; leverage FAQ lists 1:50."}'),
 ('classic',2,'Phase 2',5::numeric,5::numeric,8::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Classic Help Center, captured 2026-09-29.","time_limit":"No maximum time limit.","minimum_days":"Four minimum trading days for the challenge overall; the source does not require four in each phase.","leverage_conflict":"Official main selector lists 1:100; leverage FAQ lists 1:50."}'),
 ('ultra',1,'Phase 1',10::numeric,5::numeric,10::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Ultra Help Center, captured 2026-09-29.","time_limit":"No maximum time limit.","minimum_days":"Four minimum trading days for the challenge overall; the source does not require four in each phase.","leverage_conflict":"Official main selector lists 1:100; leverage FAQ lists 1:50."}'),
 ('ultra',2,'Phase 2',5::numeric,5::numeric,10::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Ultra Help Center, captured 2026-09-29.","time_limit":"No maximum time limit.","minimum_days":"Four minimum trading days for the challenge overall; the source does not require four in each phase.","leverage_conflict":"Official main selector lists 1:100; leverage FAQ lists 1:50."}'),
 ('elite',1,'Phase 1',6::numeric,null::numeric,6::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Elite Help Center, captured 2026-09-29.","daily_loss":"No daily drawdown limit.","time_limit":"No maximum time limit.","minimum_days":"Four minimum trading days for the challenge overall; the source does not require four in each phase."}'),
 ('elite',2,'Phase 2',6::numeric,null::numeric,6::numeric,'Static',null::integer,null::integer,'{"source_note":"Official Elite Help Center, captured 2026-09-29.","daily_loss":"No daily drawdown limit.","time_limit":"No maximum time limit.","minimum_days":"Four minimum trading days for the challenge overall; the source does not require four in each phase."}')
) as x(program_slug,phase_number,name,target,daily_loss,max_loss,drawdown_type,time_limit_days,minimum_days,rules)
  on x.program_slug = p.slug
where f.slug = 'wall-street-funded'
on conflict (program_id, phase_number) do update
set name = excluded.name, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent,
    maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules,
    updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes from bullish_banana.firms f join (values
 ('https://wsfunded.com/en','Official website and live plan selector','Current product families, account sizes, paired list/current price display, general platform options and promotional banner observed 2026-09-29.'),
 ('https://wsfunded.com/en/terms-conditions','Terms and conditions','WSFmarkets Ltd operator, WSF Technology FZCO and RENATICA LTD roles, simulated account terms, and regional eligibility disclosure.'),
 ('https://faq.wsfunded.com/en/collections/7470136-challenges','Official current challenge collection','Lists Rapid, Power, Classic, Ultra, Stellar, Elite, Instant Standard and Instant Pro Help Center articles.'),
 ('https://faq.wsfunded.com/en/articles/8717472-what-is-leverage-and-what-is-it-in-wsfunded','Official leverage FAQ','Forex leverage by program family; conflicts with main-site leverage comparison for Classic and Ultra.'),
 ('https://faq.wsfunded.com/en/articles/8717138-what-account-sizes-do-we-offer','Official account-size FAQ','General account sizes of $5K to $100K, updated 2024; current live selector is used for product sizes where available.')
) as x(url,label,notes) on true where f.slug = 'wall-street-funded'
and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
join (values
 ('rapid','https://faq.wsfunded.com/en/articles/8717253-1-phase-wall-street-rapid','Rapid rules','One-phase objective, drawdown, duration, payout, trading-day and risk rules.'),
 ('power','https://faq.wsfunded.com/en/articles/16859382-1-phase-wall-street-power','Power rules and fees','Phase objective, size-specific initial and funded-stage fees, daily/maximum loss, consistency, MT5 and Spain/Andorra exclusion.'),
 ('classic','https://faq.wsfunded.com/en/articles/8717270-2-phases-wall-street-classic','Classic rules','Two-phase targets, loss limits, duration, days, payout and risk rules.'),
 ('ultra','https://faq.wsfunded.com/en/articles/8717276-2-phases-wall-street-ultra','Ultra rules','Two-phase targets, loss limits, duration, days, payout and risk rules.'),
 ('elite','https://faq.wsfunded.com/en/articles/14738080-2-phases-wall-street-elite-new','Elite rules','Current two-phase 6%/6% challenge rules and payouts.'),
 ('instant-standard','https://faq.wsfunded.com/en/articles/10719192-instant-standard','Instant Standard rules','Trailing loss, daily loss, consistency, reward eligibility, news restriction and leverage.'),
 ('instant-pro','https://faq.wsfunded.com/en/articles/10719208-instant-pro','Instant Pro rules','Trailing loss, daily loss, consistency, reward eligibility, news restriction and leverage.'),
 ('rapid','https://wsfunded.com/en','Rapid current pricing selector','Size-specific paired current/list price display captured 2026-09-29; verify exact payable price in checkout.'),
 ('classic','https://wsfunded.com/en','Classic current pricing selector','Size-specific paired current/list price display captured 2026-09-29; verify exact payable price in checkout.'),
 ('ultra','https://wsfunded.com/en','Ultra current pricing selector','Size-specific paired current/list price display captured 2026-09-29; verify exact payable price in checkout.'),
 ('elite','https://wsfunded.com/en','Elite current pricing selector','Size-specific paired current/list price display captured 2026-09-29; verify exact payable price in checkout.'),
 ('instant-standard','https://wsfunded.com/en','Instant Standard current pricing selector','Size-specific paired current/list price display captured 2026-09-29; verify exact payable price in checkout.'),
 ('instant-pro','https://wsfunded.com/en','Instant Pro current pricing selector','Size-specific paired current/list price display captured 2026-09-29; verify exact payable price in checkout.')
) as x(slug,url,label,notes) on x.slug = p.slug
where f.slug = 'wall-street-funded'
and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Official website, current product selector, Terms, leverage FAQ, account-size FAQ and Help Center collection reviewed 2026-09-29. Firm remains in_review due simulation-status and jurisdiction conflicts.'
from bullish_banana.firms f where slug = 'wall-street-funded'
and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Current selector and corresponding official Help Center article reviewed 2026-09-29. Program remains in_review pending checkout price confirmation, terms reconciliation and program-specific platform mapping.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'wall-street-funded'
and p.slug in ('rapid','power','classic','ultra','elite','instant-standard','instant-pro')
and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);
