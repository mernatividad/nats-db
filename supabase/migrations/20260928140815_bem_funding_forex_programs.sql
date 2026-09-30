set search_path = bullish_banana, extensions, public;

-- Current official BEM Funding product terms and homepage selector reviewed 2026-09-28.
-- Keep the firm and offers in review: the selector's selected-size/price display was inconsistent,
-- so fees are intentionally omitted and must be re-captured before these records are published.
insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('BEM Funding','bem-funding','A simulated trading evaluation service offering one-step and two-step Forex challenges.','https://bemfunding.com/','in_review','forex',null)
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
    status='in_review',market_type='forex',published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='bem-funding'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'AE','BEX Software Development L.L.C-FZ',
       array['Forex','Metals','Energies','Indices','Cryptocurrencies']::text[],
       '{"service_model":"BEM Funding describes its evaluations and trader accounts as simulated trading environments for education and evaluation. Users do not deposit investment capital.","service_operator":"BEX Software Development L.L.C-FZ, a UAE technology and education company, Meydan Grandstand, 6th Floor, Meydan Road, Nad Al Sheba, Dubai, UAE.","platform_entities":"BEM Funding states that BEX Software Development L.L.C-FZ operates DXtrade and cTrader. Separate BEM Ltd., Saint Lucia registration 2026-00240, operates MetaTrader 5. Map platforms to each program only after confirming product-specific selector access.","current_forex_offers":["BEM ONE","BEM ONE ONLY","BEM Classic Normal","BEM Classic Swing"],"homepage_selector_sizes":{"one_step":[5000,10000,25000,50000,100000,200000],"two_step":[5000,10000,25000,50000,100000]},"age_requirement":"At least 18 or the age of majority in the user jurisdiction.","restricted_jurisdictions":"The current website lists Afghanistan, Kiribati, Seychelles, Antigua and Barbuda, Lesotho, Sierra Leone, Belize, Liberia, Solomon Islands, Bhutan, Malawi, Somalia, Bouvet Island, Mali, South Sudan, Burundi, Marshall Islands, Syria, Cape Verde, Myanmar, Timor-Leste, Central African Republic, Niue, Tokelau, Chad, North Korea, Tonga, Comoros, Qatar, Tuvalu, Cook Islands, Belarus, UAE, Cuba, Republic of the Congo, United States, Djibouti, Saint Barthelemy, Vanuatu, Eritrea, Saint Kitts and Nevis, Venezuela, Eswatini, Saint Lucia, Western Sahara, Fiji, Saint Vincent and the Grenadines, Iran, Sao Tome and Principe, Iraq, and Saudi Arabia. The footer also says MT5 access is restricted to US citizens and use contrary to local law. Preserve platform-specific eligibility.","content_note":"Product-specific account-size buttons were visible, but sequential selector interaction caused the active size and displayed price card to disagree. Fees are deliberately not included in this draft. Homepage showed a live MT5LIVE promotion; promo fees are not base fees."}'::jsonb
from bullish_banana.firms where slug='bem-funding'
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
       x.leverage,x.split,x.payout,x.minimum_days,x.news_allowed,x.weekends_allowed,x.details::jsonb,null,null
from bullish_banana.firms f
join (values
 ('BEM ONE','bem-one','Single-phase simulated Forex evaluation with a 9% target, 3% daily loss and 6% balance-trailing maximum loss.',
  '[5000,10000,25000,50000,100000,200000]',30::numeric,80::numeric,'On demand',null::integer,null::boolean,null::boolean,
  '{"availability":"Listed on current homepage selector as the One-Step BEM ONE offer.","account_sizes":"Selector displayed $5K, $10K, $25K, $50K, $100K, and $200K one-step options. Selector selected-size and price card became inconsistent during capture; verify before publication.","fees":"Not staged. Current selector states/promotional display were inconsistent; do not infer or store fees from a mismatched card.","evaluation_rules":"One phase; target 9%; daily loss 3%; maximum trailing drawdown 6%. No minimum trading days according to current selector page.","funded_rules":"80% reward share. Reward on Demand. Funded reward best-day cap is 35% of lifetime realized profits. Minimum reward USD 150 and a buffer applies. See official Terms of Use for the exact risk/payout conditions.","leverage_forex":"30:1.","news_and_weekend":"The product page advertises news trading and weekend holding during evaluation; funded asset-specific terms and prohibited strategies still apply. Not flattened into one boolean.","eligibility":"Official site has a firm restricted-jurisdiction list and separate MT5 access restrictions. Verify actual platform/program country eligibility.","source_note":"Official homepage selector, BEM ONE Terms of Use, evaluation FAQ, and reward FAQ reviewed 2026-09-28."}'),
 ('BEM ONE ONLY','bem-one-only','Single-phase simulated Forex evaluation with a 6% target, 3% daily loss, 6% maximum loss and a 30% best-day cap.',
  '[5000,10000,25000,50000,100000,200000]',50::numeric,80::numeric,'On demand',null::integer,null::boolean,null::boolean,
  '{"availability":"Listed on current official one-step selector as BEM ONE ONLY.","account_sizes":"Selector displayed $5K, $10K, $25K, $50K, $100K, and $200K one-step options. Selector selected-size and price card became inconsistent during capture; verify before publication.","fees":"Not staged. Current selector states/promotional display were inconsistent; do not infer or store fees from a mismatched card.","evaluation_rules":"One phase; 6% target; 3% daily loss recalculated at 22:00 UTC as balance at reset minus 3% of initial balance; 6% balance-trailing maximum drawdown, locks at initial balance; 30% maximum best-day share of total realized evaluation profits.","funded_rules":"80% reward share; on-demand reward requests; 30% lifetime best-day cap; minimum reward USD 150; post-reward buffer at least 50% of daily drawdown amount. Requests subject to review.","leverage_forex":"50:1.","news_and_weekend":"News trading and weekend holding permitted, subject to the terms restrictions against strategies designed primarily to exploit high-impact news.","eligibility":"Official site has a firm restricted-jurisdiction list and separate platform access restrictions. Verify program-specific availability.","source_note":"Official BEM ONE ONLY Terms of Use last updated 2026-06-14, official evaluation and reward FAQs, and current homepage selector reviewed 2026-09-28."}'),
 ('BEM Classic Normal','bem-classic-normal','Two-phase simulated Forex evaluation with 9% and 4.5% targets, 4.5% daily loss and 9% static maximum loss.',
  '[5000,10000,25000,50000,100000]',100::numeric,80::numeric,'Every 14 days',3::integer,null::boolean,true::boolean,
  '{"availability":"Listed on current official two-step selector as Classic.","account_sizes":"Selector displayed $5K, $10K, $25K, $50K, and $100K two-step options. Selector selected-size and price card became inconsistent during capture; verify before publication.","fees":"Not staged. A $5K cTrader base-price example displayed $39, but selector consistency and platform-specific price matrix require recapture. Treat this as a research observation only, not a full price record.","evaluation_rules":"Phase 1 target 9%; Phase 2 target 4.5%; each phase daily loss 4.5% and static maximum loss 9%; at least three trading days per phase, each with at least 0.5% realized profit on initial balance.","funded_rules":"80% reward share. At least three trading days per trading period before a reward request. Two-step reward cycle is 14 days by default or 7 days with add-on. USD 150 minimum; 2% processing fee applies to rewards.","leverage_forex":"100:1.","weekend_and_news":"Weekend holding is permitted during evaluation; after funding, Forex positions must be closed before Friday market close. Eight-hour high-impact-news restrictions and exceptions are defined in terms. Verify current news condition before publication.","eligibility":"Official site has a restricted-jurisdiction list; MT5 has separate platform access restrictions.","source_note":"Official homepage selector, Classic Normal Terms of Use and FAQ, rewards FAQ, and official company disclosure reviewed 2026-09-28."}'),
 ('BEM Classic Swing','bem-classic-swing','Two-phase simulated Forex evaluation for swing trading with weekend holding, 9% and 4.5% targets, and 9% static maximum loss.',
  '[5000,10000,25000,50000,100000]',30::numeric,80::numeric,'Every 14 days',3::integer,null::boolean,true::boolean,
  '{"availability":"Listed on current official two-step selector as Swing.","account_sizes":"Selector displayed $5K, $10K, $25K, $50K, and $100K two-step options. Selector selected-size and price card became inconsistent during capture; verify before publication.","fees":"Not verified. No fee matrix staged.","evaluation_rules":"Phase 1 target 9%; Phase 2 target 4.5%; each phase daily loss 4.5% and fixed maximum loss 9%; at least three trading days per phase, each with at least 0.5% realized profit on initial balance.","funded_rules":"80% reward share. At least three trading days per trading period before reward requests. Two-step reward cycle is 14 days by default or 7 days with add-on. USD 150 minimum; 2% processing fee applies to rewards.","leverage_forex":"30:1.","news_and_weekend":"Program supports long-term trading, no swap fees and weekend holding on supported instruments. Trades/orders opened within eight hours of high-impact news are subject to restrictions; see Terms of Use. Do not flatten per-stage differences.","eligibility":"Official site has a restricted-jurisdiction list; MT5 has separate platform access restrictions.","source_note":"Official homepage selector, Classic Swing Terms of Use and FAQ, rewards FAQ, and official company disclosure reviewed 2026-09-28."}')
) as x(name,slug,description,sizes,leverage,split,payout,minimum_days,news_allowed,weekends_allowed,details) on true
where f.slug='bem-funding'
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
 ('bem-one',1,'Evaluation',9::numeric,3::numeric,6::numeric,'trailing',null::integer,'{"daily_limit_basis":"Higher of equity or balance at 22:00 UTC less 3% of initial balance.","maximum_drawdown_basis":"Balance trailing, never trails downward; locks at initial balance.","minimum_trading_days":"No minimum per current selector page."}'),
 ('bem-one-only',1,'Evaluation',6::numeric,3::numeric,6::numeric,'trailing',null::integer,'{"daily_limit_basis":"Balance at 22:00 UTC less 3% of initial balance.","maximum_drawdown_basis":"Balance trailing; locks at initial balance.","consistency_percent":30,"consistency_basis":"Highest single-day realized profit divided by total evaluation realized profits.","minimum_trading_days":"No minimum per current selector page."}'),
 ('bem-classic-normal',1,'Challenge',9::numeric,4.5::numeric,9::numeric,'static',3::integer,'{"minimum_daily_profit_percent":0.5,"daily_limit_basis":"Higher of equity or balance at 22:00 UTC less 4.5% of initial balance.","weekend_holding":"Allowed during evaluation."}'),
 ('bem-classic-normal',2,'Consistency',4.5::numeric,4.5::numeric,9::numeric,'static',3::integer,'{"minimum_daily_profit_percent":0.5,"daily_limit_basis":"Higher of equity or balance at 22:00 UTC less 4.5% of initial balance."}'),
 ('bem-classic-swing',1,'Swing Mastery - Challenge',9::numeric,4.5::numeric,9::numeric,'static',3::integer,'{"minimum_daily_profit_percent":0.5,"daily_limit_basis":"Balance at 22:00 UTC less 4.5% of initial balance.","weekend_holding":"Supported; program markets itself as swing trading."}'),
 ('bem-classic-swing',2,'Swing Mastery - Consistency',4.5::numeric,4.5::numeric,9::numeric,'static',3::integer,'{"minimum_daily_profit_percent":0.5,"daily_limit_basis":"Balance at 22:00 UTC less 4.5% of initial balance."}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,minimum_days,rules) on x.program_slug=p.slug
where f.slug='bem-funding'
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
 ('https://bemfunding.com/','Official homepage, legal disclosure and live selector','Company entities, simulated service, platform ownership, selector sizes and volatile promotion; live selector did not reliably pair selected size with displayed product-card price during this capture.'),
 ('https://bemfunding.com/all-challenges','All Challenges catalog','Current product lineup: BEM ONE, BEM ONE ONLY, BEM Classic and BEM Swing.'),
 ('https://bemfunding.com/terms-and-conditions','Master Terms & Conditions','Current general service terms, simulated service description, age and restricted-territory text.'),
 ('https://bemfunding.com/terms-of-use/bem-one','BEM ONE Terms of Use','9%/3%/6% evaluation rules, 1:30 Forex leverage, 80% reward share and reward conditions.'),
 ('https://bemfunding.com/terms-of-use/bem-one-only','BEM ONE ONLY Terms of Use','Updated 2026-06-14; 6% target, 3% daily loss, 6% balance-trailing drawdown, 30% consistency and 1:50 Forex leverage.'),
 ('https://bemfunding.com/terms-of-use/bem-classic-normal','BEM Classic Normal Terms of Use','9%/4.5% targets, 4.5% daily loss, 9% static max loss, minimum-day rules, 1:100 Forex leverage, funded weekend restrictions.'),
 ('https://bemfunding.com/terms-of-use/bem-classic-swing','BEM Classic Swing Terms of Use','9%/4.5% targets, 4.5% daily loss, 9% static max loss, minimum-day rules, news-window restrictions, 1:30 Forex leverage.'),
 ('https://bemfunding.com/faq/rewards-when-and-how-often-can-i-request-my-reward','Reward frequency FAQ','One-step on-demand rewards; two-step standard 14-day or add-on 7-day cycle.'),
 ('https://bemfunding.com/faq/rewards-are-there-any-fees-or-limits-on-rewards','Reward fees FAQ','Minimum USD 150 reward after split; 2% processing fee.'),
 ('https://bemfunding.com/faq/bem-one-what-are-the-rules-for-the-bem-one','BEM ONE evaluation FAQ','Current evaluation target, daily loss and trailing maximum drawdown.'),
 ('https://bemfunding.com/faq/bem-one-only-what-are-the-rules-for-bem-one-only','BEM ONE ONLY evaluation FAQ','Current target, drawdowns and 30% evaluation consistency rule.'),
 ('https://bemfunding.com/faq/bem-classic-normal-what-are-the-rules-for-the-bem-classic-normal','BEM Classic Normal evaluation FAQ','Current two-phase targets, loss limits and minimum profitable-day rules.'),
 ('https://bemfunding.com/faq/bem-classic-swing-how-does-the-bem-classic-swing-evaluation-work','BEM Classic Swing evaluation FAQ','Current two-phase targets, loss limits and minimum profitable-day rules.')
) as x(url,label,notes) on true
where f.slug='bem-funding'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('bem-one','https://bemfunding.com/terms-of-use/bem-one','BEM ONE Terms of Use','Evaluation and funded reward rules, drawdown calculation, leverage, and eligibility.'),
 ('bem-one','https://bemfunding.com/faq/bem-one-what-are-the-rules-for-the-bem-one','BEM ONE evaluation rules FAQ','Official current target, daily drawdown, maximum trailing drawdown and one-phase structure.'),
 ('bem-one','https://bemfunding.com/','BEM ONE live homepage selector','Selector showed a $5K cTrader base-price example, but no complete matrix is stored; re-capture fees.'),
 ('bem-one-only','https://bemfunding.com/terms-of-use/bem-one-only','BEM ONE ONLY Terms of Use','Evaluation consistency and drawdown mechanics, leverage, funded reward and buffer rules.'),
 ('bem-one-only','https://bemfunding.com/faq/bem-one-only-what-are-the-rules-for-bem-one-only','BEM ONE ONLY evaluation rules FAQ','Official current single-phase target, daily/max loss and evaluation consistency.'),
 ('bem-one-only','https://bemfunding.com/faq/bem-one-only-what-is-reward-on-demand','BEM ONE ONLY Reward on Demand FAQ','Funded reward share, best-day cap, minimum amount and buffer.'),
 ('bem-classic-normal','https://bemfunding.com/terms-of-use/bem-classic-normal','BEM Classic Normal Terms of Use','Phase objectives, reset basis, minimum trading days, leverage, funded rules and eligibility.'),
 ('bem-classic-normal','https://bemfunding.com/faq/bem-classic-normal-what-are-the-rules-for-the-bem-classic-normal','BEM Classic Normal evaluation rules FAQ','Official current phase targets, daily/max loss and minimum profitable-day rules.'),
 ('bem-classic-normal','https://bemfunding.com/faq/rewards-when-and-how-often-can-i-request-my-reward','BEM reward frequency FAQ','Official two-step reward cycles and add-on cadence.'),
 ('bem-classic-swing','https://bemfunding.com/terms-of-use/bem-classic-swing','BEM Classic Swing Terms of Use','Phase objectives, drawdown reset, leverage, news restrictions, weekend support and funded rewards.'),
 ('bem-classic-swing','https://bemfunding.com/faq/bem-classic-swing-how-does-the-bem-classic-swing-evaluation-work','BEM Classic Swing evaluation rules FAQ','Official current phase objectives and minimum profitable-day rules.'),
 ('bem-classic-swing','https://bemfunding.com/faq/rewards-when-and-how-often-can-i-request-my-reward','BEM reward frequency FAQ','Official two-step reward cycles and add-on cadence.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='bem-funding'
and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);
