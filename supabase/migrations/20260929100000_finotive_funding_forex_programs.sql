-- Finotive Funding current Forex offers; fee snapshot captured 2026-09-28.
-- Keep all programs in review pending full rules, restrictions, and payout-source reconciliation.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values ('Finotive Funding', 'finotive-funding', 'A simulated trading provider offering Forex challenges, instant funding and Pro programs.', 'https://finotivefunding.com/', 'published', 'forex', now())
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'published', market_type = 'forex', published_at = coalesce(bullish_banana.firms.published_at, now()),
    archived_at = null, updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'finotive-funding'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'AE', 'Finotive Funding Technologies Limited', array['Forex','Metals','Indices','Energies','Crypto']::text[],
  '{"legal_entity":"Finotive Funding is a trading name of Finotive Funding Technologies Limited, company number 11088, registered in DIFC, Dubai, United Arab Emirates; VAT 105195257800003.","service_model":"Simulated trading evaluation and funding; the company states it does not provide investment services, brokerage accounts, or accept capital deposits.","related_entities":"Trading platforms are powered by Finotive Markets LLC. Finotive Pay (CY) Limited acts as a payment agent for Finotive One group entities.","operating_status":"Current official site has live challenge and account selectors and current rules as of 2026-09-28.","market_offers":"Current selector exposes Forex 1-Step and 2-Step Challenges, Instant Funding Standard and Lite, and Pro 1-Step and 2-Step.","country_restrictions":"Current eligible/restricted country list not captured; verify before publication."}'::jsonb
from bullish_banana.firms where slug = 'finotive-funding'
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
       x.account_sizes::jsonb, 100, x.split, x.payout, x.days,
       null, null, x.details::jsonb, null, null
from bullish_banana.firms f
join (values
 ('1-Step Challenge','one-step','Single-phase evaluation with a 10% target and static drawdown.','evaluation','[2500,5000,10000,25000,50000,100000,200000]','[{"account_size":2500,"fee":35,"currency":"USD"},{"account_size":5000,"fee":50,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":200,"currency":"USD"},{"account_size":50000,"fee":355,"currency":"USD"},{"account_size":100000,"fee":580,"currency":"USD"},{"account_size":200000,"fee":1160,"currency":"USD"}]',80::numeric,'On demand, then every 7 days',3,'{"pricing_capture":"Official USD selector, no coupon, 2026-09-28.","account_size_prices":[{"account_size":2500,"fee":35,"currency":"USD"},{"account_size":5000,"fee":50,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":200,"currency":"USD"},{"account_size":50000,"fee":355,"currency":"USD"},{"account_size":100000,"fee":580,"currency":"USD"},{"account_size":200000,"fee":1160,"currency":"USD"}],"minimum_profitable_days":"3 days at 0.5% profit per day.","profit_split":"80%; Help Center says up to 95% through scaling.","source_note":"Official Challenge page, Accounts selector, Trading Rules and reward FAQ, captured 2026-09-28."}'),
 ('2-Step Challenge','two-step','Two-phase evaluation with 7.5% and 5% targets and static drawdown.','evaluation','[2500,5000,10000,25000,50000,100000,200000]','[{"account_size":2500,"fee":25,"currency":"USD"},{"account_size":5000,"fee":45,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":205,"currency":"USD"},{"account_size":50000,"fee":400,"currency":"USD"},{"account_size":100000,"fee":555,"currency":"USD"},{"account_size":200000,"fee":895,"currency":"USD"}]',80::numeric,'On demand, then every 7 days',2,'{"pricing_capture":"Official USD selector, no coupon, 2026-09-28.","account_size_prices":[{"account_size":2500,"fee":25,"currency":"USD"},{"account_size":5000,"fee":45,"currency":"USD"},{"account_size":10000,"fee":80,"currency":"USD"},{"account_size":25000,"fee":205,"currency":"USD"},{"account_size":50000,"fee":400,"currency":"USD"},{"account_size":100000,"fee":555,"currency":"USD"},{"account_size":200000,"fee":895,"currency":"USD"}],"minimum_profitable_days":"2 days at 0.5% in each phase and before each payout.","profit_split":"80%; Help Center says up to 95% through scaling.","source_note":"Official Challenge page, Accounts selector, Trading Rules and reward FAQ, captured 2026-09-28."}'),
 ('Instant Funding Standard','instant-standard','Immediate-access simulated account with model-specific payout and trading conditions.','instant_funding','[2500,5000,10000,25000,50000,100000]','[{"account_size":2500,"fee":105,"currency":"USD"},{"account_size":5000,"fee":205,"currency":"USD"},{"account_size":10000,"fee":399,"currency":"USD"},{"account_size":25000,"fee":949,"currency":"USD"},{"account_size":50000,"fee":1399,"currency":"USD"},{"account_size":100000,"fee":2699,"currency":"USD"}]',75::numeric,'On demand, then every 7 days',0,'{"pricing_capture":"Official USD Accounts selector, no coupon, 2026-09-28.","account_size_prices":[{"account_size":2500,"fee":105,"currency":"USD"},{"account_size":5000,"fee":205,"currency":"USD"},{"account_size":10000,"fee":399,"currency":"USD"},{"account_size":25000,"fee":949,"currency":"USD"},{"account_size":50000,"fee":1399,"currency":"USD"},{"account_size":100000,"fee":2699,"currency":"USD"}],"drawdown_type":"Static","maximum_drawdown":"7%","daily_drawdown":"3.5%","profit_split":"75%; 90% through scaling per reward FAQ.","payout_rules":"Selector displays a 14-day cycle. Minimum reward request is 1% of initial balance per Help Center.","weekend_holding":"Weekend positions require the Weekend Holding add-on.","source_note":"Official Accounts selector, Trading Rules and reward FAQs, captured 2026-09-28."}'),
 ('Instant Funding Lite','instant-lite','Immediate-access Lite simulated account with stricter drawdown and profitable-day requirements.','instant_funding','[2500,5000,10000,25000,50000,100000]','[{"account_size":2500,"fee":55,"currency":"USD"},{"account_size":5000,"fee":95,"currency":"USD"},{"account_size":10000,"fee":189,"currency":"USD"},{"account_size":25000,"fee":449,"currency":"USD"},{"account_size":50000,"fee":699,"currency":"USD"},{"account_size":100000,"fee":1199,"currency":"USD"}]',70::numeric,'On demand, then every 14 days',5,'{"pricing_capture":"Official USD Accounts selector, no coupon, 2026-09-28.","account_size_prices":[{"account_size":2500,"fee":55,"currency":"USD"},{"account_size":5000,"fee":95,"currency":"USD"},{"account_size":10000,"fee":189,"currency":"USD"},{"account_size":25000,"fee":449,"currency":"USD"},{"account_size":50000,"fee":699,"currency":"USD"},{"account_size":100000,"fee":1199,"currency":"USD"}],"drawdown_type":"Static","maximum_drawdown":"6%","daily_drawdown":"3%","minimum_profitable_days":"5 days at 0.5% per day.","source_note":"Official Accounts selector and Trading Rules, captured 2026-09-28."}'),
 ('Pro 1-Step','pro-one-step','Single-phase professional challenge with salary-style rewards and a trading-consistency rule.','evaluation','[50000,100000,200000]','[{"account_size":50000,"fee":514,"currency":"USD"},{"account_size":100000,"fee":914,"currency":"USD"},{"account_size":200000,"fee":1799,"currency":"USD"}]',80::numeric,'On demand, then every 7 days',3,'{"pricing_capture":"Official USD Accounts selector, no coupon, 2026-09-28.","account_size_prices":[{"account_size":50000,"fee":514,"currency":"USD"},{"account_size":100000,"fee":914,"currency":"USD"},{"account_size":200000,"fee":1799,"currency":"USD"}],"consistency_rule":"Weekly trade count and instrument volume must stay within ±25% of averages; quarterly 5% profit target applies to Pro funded status.","minimum_profitable_days":"3 days at 0.5%.","drawdown_type":"Static","source_note":"Official Accounts selector and Trading Rules, captured 2026-09-28."}'),
 ('Pro 2-Step','pro-two-step','Two-phase professional challenge with salary-style rewards and a trading-consistency rule.','evaluation','[50000,100000,200000]','[{"account_size":50000,"fee":469,"currency":"USD"},{"account_size":100000,"fee":744,"currency":"USD"},{"account_size":200000,"fee":1484,"currency":"USD"}]',80::numeric,'On demand, then every 7 days',2,'{"pricing_capture":"Official USD Accounts selector, no coupon, 2026-09-28.","account_size_prices":[{"account_size":50000,"fee":469,"currency":"USD"},{"account_size":100000,"fee":744,"currency":"USD"},{"account_size":200000,"fee":1484,"currency":"USD"}],"consistency_rule":"Weekly trade count and instrument volume must stay within ±25% of averages; quarterly 5% profit target applies to Pro funded status.","minimum_profitable_days":"2 days at 0.5% per stage and before payout.","drawdown_type":"Static","source_note":"Official Accounts selector and Trading Rules, captured 2026-09-28."}')
) as x(name,slug,description,program_type,account_sizes,prices,split,payout,days,details) on true
where f.slug='finotive-funding'
on conflict (firm_id, slug) do update
set name=excluded.name, description=excluded.description, program_type=excluded.program_type,
    market_type=excluded.market_type, status='in_review', currency=excluded.currency,
    account_sizes=excluded.account_sizes, max_leverage=excluded.max_leverage,
    profit_split_percent=excluded.profit_split_percent, payout_frequency=excluded.payout_frequency,
    minimum_trading_days=excluded.minimum_trading_days, commercial_details=excluded.commercial_details,
    published_at=null, archived_at=null, updated_at=now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.max_loss,
       'static', null, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-step',1,'Evaluation',10::numeric,4::numeric,7.5::numeric,3,'{"trading_day":"At least 0.5% profit","source_note":"Official Rules page, captured 2026-09-28."}'),
 ('two-step',1,'Phase 1',7.5::numeric,4.5::numeric,9::numeric,2,'{"trading_day":"At least 0.5% profit","source_note":"Official Rules page, captured 2026-09-28."}'),
 ('two-step',2,'Phase 2',5::numeric,4.5::numeric,9::numeric,2,'{"trading_day":"At least 0.5% profit","source_note":"Official Rules page, captured 2026-09-28."}'),
 ('pro-one-step',1,'Pro Evaluation',10::numeric,4::numeric,8::numeric,3,'{"consistency_rule":"Weekly volume/trade-count band and quarterly target apply in funded status; confirm challenge-stage application in Terms.","source_note":"Official Accounts selector and Trading Rules, captured 2026-09-28."}'),
 ('pro-two-step',1,'Pro Phase 1',7.5::numeric,5::numeric,10::numeric,2,'{"consistency_rule":"Weekly volume/trade-count band and quarterly target apply in funded status; confirm challenge-stage application in Terms.","source_note":"Official Accounts selector and Trading Rules, captured 2026-09-28."}'),
 ('pro-two-step',2,'Pro Phase 2',5::numeric,5::numeric,10::numeric,2,'{"consistency_rule":"Weekly volume/trade-count band and quarterly target apply in funded status; confirm challenge-stage application in Terms.","source_note":"Official Accounts selector and Trading Rules, captured 2026-09-28."}')
) as x(program_slug,phase_number,name,target,daily_loss,max_loss,days,rules) on x.program_slug=p.slug
where f.slug='finotive-funding'
on conflict (program_id,phase_number) do update
set name=excluded.name, profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,
    drawdown_type=excluded.drawdown_type, time_limit_days=excluded.time_limit_days,
    minimum_trading_days=excluded.minimum_trading_days, raw_rules=excluded.raw_rules, updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f join (values
 ('https://finotivefunding.com/','Official Homepage','Active operations, simulated trading disclosure, legal entity, payment agent and relationship to Finotive Markets LLC.'),
 ('https://finotivefunding.com/accounts','Official Accounts selector','Current USD sizes, fees and selector rules for Challenge, Instant Funding Standard/Lite and Pro account families, captured 2026-09-28; no coupon applied.'),
 ('https://finotivefunding.com/challenge','Challenge comparison','Current 1-Step and 2-Step targets, drawdowns, payout information and product identities.'),
 ('https://finotivefunding.com/rules','Trading Rules & Objectives','Product-specific drawdown, trading days, exposure, weekend and consistency rules. Reconcile conflicting or tier-specific descriptions before publication.'),
 ('https://help.finotivefunding.com/en/articles/987-what-reward-split-applies-to-each-account','Reward split FAQ','Split and scaling terms by account family.'),
 ('https://help.finotivefunding.com/en/articles/980-when-can-i-request-my-first-reward-payment','First reward request FAQ','Eligibility and payment conditions by account family.'),
 ('https://help.finotivefunding.com/en/articles/982-what-are-the-minimum-reward-payment-request-amounts','Minimum reward request FAQ','Minimum payout thresholds by challenge/account family.'),
 ('https://finotivefunding.com/terms-and-conditions','Terms and Conditions','Official current user agreement; review entity roles, restrictions and model-specific commercial terms before publishing.')
) as x(url,label,notes) on true where f.slug='finotive-funding'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-step','https://finotivefunding.com/challenge','1-Step selector and rules','Current selector size/fee matrix and published phase objective.'),
 ('two-step','https://finotivefunding.com/challenge','2-Step selector and rules','Current selector size/fee matrix and published phase objectives.'),
 ('instant-standard','https://finotivefunding.com/accounts','Instant Standard selector','Current USD size/fee matrix; payout/risk terms still require account-specific rule reconciliation.'),
 ('instant-lite','https://finotivefunding.com/accounts','Instant Lite selector','Current USD size/fee matrix; payout/risk terms still require account-specific rule reconciliation.'),
 ('pro-one-step','https://finotivefunding.com/accounts','Pro 1-Step selector','Current USD size/fee matrix; Pro funded consistency/salary terms need agreement review.'),
 ('pro-two-step','https://finotivefunding.com/accounts','Pro 2-Step selector','Current USD size/fee matrix; Pro funded consistency/salary terms need agreement review.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug where f.slug='finotive-funding'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select id,now(),'Current official website, selector, rules, Help Center reward FAQs and legal disclosures reviewed 2026-09-28. Operating status confirmed; country restrictions and precise entity scope require follow-up.'
from bullish_banana.firms f where slug='finotive-funding'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Current selector availability and USD size/fee schedule observed 2026-09-28. Remains in review pending official account-specific rule, reward, restricted-country, and terms reconciliation.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id where f.slug='finotive-funding'
and p.slug in ('one-step','two-step','instant-standard','instant-lite','pro-one-step','pro-two-step')
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);
