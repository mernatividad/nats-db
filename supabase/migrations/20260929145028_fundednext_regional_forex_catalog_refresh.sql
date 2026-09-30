-- Refresh FundedNext Forex/CFD catalog details from current first-party sources.
-- Fee schedules are region-labeled and exclude time-limited promotions.
-- Reviewed 2026-09-30. Staged only; do not apply during catalog authoring.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set description='FundedNext provides simulated CFD challenges and instant accounts with distinct Forex rules, payout paths, platform availability and regional prices.',
    website_url='https://fundednext.com/cfds',updated_at=now()
where slug='fundednext';

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select f.id,'KM','FundedNext Ltd.',array['Forex','Indices','Commodities','Crypto','Stocks']::text[],
$profile$
{"service_model":"All trading is simulated in a demo environment using virtual funds; no client deposits or live market orders.","program_operator":"FundedNext Ltd. (Comoros; registration number HY01023052) operates CFD trading activities.","website_operator":"FundedNext Limited (Hong Kong) operates fundednext.com.","brand_owner":"GrowthNext F.Z.E. (Ajman, UAE); Incenteco Trading LTD. and Abutor Investments LTD. are listed for payment-operation activities.","assets_note":"CFD instruments include Forex, indices, commodities, crypto and stock CFDs; the official page lists 46 Forex symbols.","platforms":["MetaTrader 4","MetaTrader 5","cTrader","Match-Trader"],"jurisdiction_notes":"Help Center country list dated 2026-08-27: Bangladesh, Myanmar, Belarus, North Korea, Syria, Grenada, Chad, Malaysia, Belize, Antigua and Barbuda, Cape Verde, Tuvalu, Vietnam, Bouvet Island, Burundi, Cook Islands, Eritrea, Comoros, Sri Lanka and Fiji. Website legal footer additionally lists Iran and Russia, absent from that Help Center list. U.S. clients are accepted but CFD platform choices are restricted to Match-Trader; product availability differs between official Stellar Instant U.S. materials.","entity_scope_note":"Legal disclosure distinguishes CFD operator FundedNext Ltd. from website operator FundedNext Limited and brand owner GrowthNext F.Z.E.; the identities are recorded by role.","verification_note":"Current CFD catalog, product pages, general trading/platform rules, legal disclosure and Help Center restrictions reviewed 2026-09-30."}
$profile$::jsonb
from bullish_banana.firms f where f.slug='fundednext'
on conflict (firm_id) do update
set country_code=excluded.country_code,legal_entity_name=excluded.legal_entity_name,
    supported_assets=excluded.supported_assets,
    profile_details=coalesce(bullish_banana.firm_profiles.profile_details,'{}'::jsonb)||excluded.profile_details,
    updated_at=now();

insert into bullish_banana.restrictions (firm_id,country_code,restriction_type,note)
select f.id,r.code,'restricted',r.note
from bullish_banana.firms f
cross join (values
 ('BD','Listed on the FundedNext CFD Help Center restriction list, updated 2026-08-27.'),
 ('MM','Help Center restriction list and website legal footer.'),
 ('BY','Help Center restriction list and website legal footer.'),
 ('KP','Help Center restriction list and website legal footer.'),
 ('SY','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('GD','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('TD','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('MY','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('BZ','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('AG','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('CV','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('TV','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('VN','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('BV','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('BI','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('CK','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('ER','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('KM','Help Center restriction list; also listed as the operator incorporation location.'),
 ('LK','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('FJ','Listed on the Help Center restriction list, updated 2026-08-27.'),
 ('IR','Listed in website legal footer; omitted from Help Center list updated 2026-08-27. Scope conflict.'),
 ('RU','Listed in website legal footer; omitted from Help Center list updated 2026-08-27. Scope conflict.')
) as r(code,note)
where f.slug='fundednext'
on conflict (firm_id,country_code) do update
set restriction_type=excluded.restriction_type,note=excluded.note,updated_at=now();

-- Stellar 2-Step: current Global and U.S. base one-time fees.
update bullish_banana.programs p
set name='FundedNext Stellar 2-Step',
 description='Two-phase simulated Forex evaluation: 8% then 5% target, 5% daily loss, 10% static maximum loss and five non-zero-P&L days per phase.',
 status='published',currency='USD',account_sizes='[6000,15000,25000,50000,100000,200000]'::jsonb,
 max_leverage=100,minimum_trading_days=5,news_allowed=true,weekend_holding_allowed=true,
 payout_frequency='First reward after 21 days; then every 14 days',
 commercial_details=p.commercial_details||jsonb_build_object(
  'account_size_prices',$prices$[
   {"account_size":6000,"fee":59.99,"currency":"USD","region":"Global"},{"account_size":15000,"fee":119.99,"currency":"USD","region":"Global"},{"account_size":25000,"fee":199.99,"currency":"USD","region":"Global"},{"account_size":50000,"fee":299.99,"currency":"USD","region":"Global"},{"account_size":100000,"fee":549.99,"currency":"USD","region":"Global"},{"account_size":200000,"fee":1099.99,"currency":"USD","region":"Global"},
   {"account_size":6000,"fee":49.99,"currency":"USD","region":"United States"},{"account_size":15000,"fee":109.99,"currency":"USD","region":"United States"},{"account_size":25000,"fee":189.99,"currency":"USD","region":"United States"},{"account_size":50000,"fee":269.99,"currency":"USD","region":"United States"},{"account_size":100000,"fee":529.99,"currency":"USD","region":"United States"},{"account_size":200000,"fee":1049.99,"currency":"USD","region":"United States"}
  ]$prices$::jsonb,
  'payout_rules','Standard reward share is 80%; scaling may raise it to 90%, and an optional add-on may raise it to 95%. Global product page states 15% of challenge profit targets is paid at first scale-up. First reward is after 21 days, then every 14 days. Challenge fee is refunded with the first reward.',
  'fee_refund_policy','Challenge fee refunded with the first performance reward; add-on fees are separate.',
  'consistency_rule','Current official comparison labels consistency as not applicable.',
  'copy_trading_rule','Copying is limited to accounts owned by the same individual. Funded accounts cannot be involved in copied trades; third-party copying and external-broker hedging are prohibited.',
  'ea_rule','Paid EAs/VPS add-ons are supported only on MT4/MT5 for eligible 5K–25K accounts; automated trading is unavailable on cTrader and Match-Trader.',
  'trading_rules','News is allowed in challenge phases. In funded accounts, 40% of profit in the five minutes before/after listed high-impact events counts toward rewards; losses count fully. A 3% at-any-time maximum-risk condition is listed. Weekend holding allowed. A 60-day inactivity deactivation rule applies. Global Forex leverage is 1:100; U.S. product page lists 1:30.',
  'platforms_and_region','Global options: MT4, MT5, cTrader and Match-Trader; U.S. CFD clients have Match-Trader only. Global cTrader/Match-Trader selection costs $25 once; MT4/MT5 are free. Platform locks after first trade. $100K/$200K accounts have purchase/reset restrictions on cTrader and Match-Trader, with a U.S. Match-Trader exception.',
  'account_limitations','FundedNext states a $300,000 maximum aggregate simulated allocation across Stellar 1-Step, 2-Step and Lite accounts. Product size and price vary by region and platform.',
  'commission_details','Stellar 2-Step: $5 commission per side on Forex and Oil; 0.0016% Metals; 0.04% Crypto; 0.004% Stock.',
  'regional_pricing_note','Global and U.S. prices are distinct official one-time-fee schedules. Temporary promotions are excluded.'
 ),
 updated_at=now()
from bullish_banana.firms f where p.firm_id=f.id and f.slug='fundednext' and p.slug='stellar-2-step';

-- Stellar 1-Step: preserve the official five-business-day vs seven-day reward timing conflict.
update bullish_banana.programs p
set name='FundedNext Stellar 1-Step',
 description='Single-phase simulated Forex evaluation with 10% target, 3% daily loss, 6% static maximum loss and two minimum trading days.',
 status='in_review',currency='USD',account_sizes='[6000,15000,25000,50000,100000,200000]'::jsonb,
 max_leverage=30,minimum_trading_days=2,news_allowed=true,weekend_holding_allowed=true,
 payout_frequency='First reward timing differs by official source; subsequent rewards every 5 business days',
 commercial_details=p.commercial_details||jsonb_build_object(
  'account_size_prices',$prices$[
   {"account_size":6000,"fee":55.99,"currency":"USD","region":"United States"},{"account_size":15000,"fee":119.99,"currency":"USD","region":"United States"},{"account_size":25000,"fee":199.99,"currency":"USD","region":"United States"},{"account_size":50000,"fee":309.99,"currency":"USD","region":"United States"},{"account_size":100000,"fee":549.99,"currency":"USD","region":"United States"},{"account_size":200000,"fee":1049.99,"currency":"USD","region":"United States"}
  ]$prices$::jsonb,
  'payout_rules','Standard reward share is 80%; scaling may raise it to 90%, with an optional 95% add-on. Product rules say first reward after 5 business days; comparison and U.S. guide say within 7 days. Later rewards are every 5 business days. Fee refund through third reward. Global rules describe a 15% challenge-phase reward after scale-up; the U.S. guide says U.S. accounts are not eligible.',
  'fee_refund_policy','Challenge fee refunded through the third reward; add-on fees are separate.',
  'review_note','Official first-reward timing conflicts: the detailed product selector says 5 business days, while the comparison and U.S. guide say within 7 days. Keep under review until reconciled.',
  'trading_rules','10% target, 3% daily loss, 6% static maximum loss, two non-zero-P&L trading days, no phase deadline, and 60-day inactivity deactivation. News and weekend holding allowed. Funded news-window profits count at 40%; losses count fully. Forex leverage is 1:30.',
  'platforms_and_region','Global options: MT4, MT5, cTrader and Match-Trader; U.S. clients use Match-Trader only. Global cTrader/Match-Trader fee is $25 once; MT4/MT5 are free. Platform selection locks after first trade.',
  'account_limitations','FundedNext states a $300,000 maximum aggregate simulated allocation across Stellar 1-Step, 2-Step and Lite accounts.',
  'ea_rule','Paid EAs/VPS add-ons on MT4/MT5 for eligible 5K–25K accounts; no automation on cTrader/Match-Trader.',
  'copy_trading_rule','Same-individual copying only; funded accounts cannot be involved. Third-party copying and external-broker hedging are prohibited.',
  'commission_details','Stellar 1-Step: $5 commission per side on Forex and Oil; 0.0016% Metals; 0.04% Crypto; 0.004% Stock.',
  'regional_pricing_note','The United States base fee schedule was captured for this model; temporary discounts are excluded.'
 ),
 updated_at=now()
from bullish_banana.firms f where p.firm_id=f.id and f.slug='fundednext' and p.slug='stellar-1-step';

-- Stellar Lite: global and U.S. source pages currently show the same base fees.
update bullish_banana.programs p
set name='FundedNext Stellar Lite',
 description='Two-phase simulated Forex evaluation: 8% then 4% targets, 4% daily loss, 8% static maximum loss and five minimum trading days per phase.',
 status='published',currency='USD',account_sizes='[5000,10000,25000,50000,100000,200000]'::jsonb,
 max_leverage=100,minimum_trading_days=5,news_allowed=true,weekend_holding_allowed=true,
 payout_frequency='First reward after 21 days; then every 14 days',
 commercial_details=p.commercial_details||jsonb_build_object(
  'account_size_prices',$prices$[
   {"account_size":5000,"fee":32.99,"currency":"USD","region":"Global"},{"account_size":10000,"fee":59.99,"currency":"USD","region":"Global"},{"account_size":25000,"fee":139.99,"currency":"USD","region":"Global"},{"account_size":50000,"fee":229.99,"currency":"USD","region":"Global"},{"account_size":100000,"fee":399.99,"currency":"USD","region":"Global"},{"account_size":200000,"fee":798.99,"currency":"USD","region":"Global"},
   {"account_size":5000,"fee":32.99,"currency":"USD","region":"United States"},{"account_size":10000,"fee":59.99,"currency":"USD","region":"United States"},{"account_size":25000,"fee":139.99,"currency":"USD","region":"United States"},{"account_size":50000,"fee":229.99,"currency":"USD","region":"United States"},{"account_size":100000,"fee":399.99,"currency":"USD","region":"United States"},{"account_size":200000,"fee":798.99,"currency":"USD","region":"United States"}
  ]$prices$::jsonb,
  'payout_rules','Standard reward share is 80%; scaling may raise it to 90%; optional 95% add-on is available. First reward after 21 days, then every 14 days. Challenge fee refunded at the third reward. No 15% challenge-phase reward is stated for Lite.',
  'fee_refund_policy','Challenge fee refunded at the third reward; add-on fees are separate.',
  'trading_rules','8% then 4% targets, 4% daily loss, 8% static maximum loss, five non-zero-P&L days per phase, no pass deadline and 60-day inactivity deactivation. News and weekend holding allowed. Funded news-window profit counts at 40%; losses count fully. Global Forex leverage is 1:100; U.S. product page lists 1:30.',
  'platforms_and_region','Global options: MT4, MT5, cTrader and Match-Trader; U.S. CFD clients use Match-Trader only. Global cTrader/Match-Trader selection costs $25 once; MT4/MT5 are free. Platform selection locks after first trade.',
  'account_limitations','FundedNext states a $300,000 maximum aggregate simulated allocation across Stellar 1-Step, 2-Step and Lite accounts.',
  'ea_rule','Paid EAs/VPS add-ons on MT4/MT5 for eligible 5K–25K accounts; no automation on cTrader/Match-Trader.',
  'copy_trading_rule','Same-individual copying only; funded accounts cannot be involved. Third-party copying and external-broker hedging are prohibited.',
  'commission_details','Stellar Lite: $7 commission per side on Forex and Oil; 0.0018% Metals; 0.04% Crypto; 0.004% Stock.',
  'regional_pricing_note','Current global and U.S. source pages show the same base fee schedule. Temporary promotions are excluded.'
 ),
 updated_at=now()
from bullish_banana.firms f where p.firm_id=f.id and f.slug='fundednext' and p.slug='stellar-lite';

-- Stellar Instant: the official base-price article says fees match globally and in the U.S.
update bullish_banana.programs p
set name='FundedNext Stellar Instant',
 description='Instant simulated FundedNext Account without an evaluation phase or target; the 6% maximum loss trails equity until it reaches initial balance.',
 status='in_review',currency='USD',account_sizes='[2000,5000,10000,20000]'::jsonb,
 max_leverage=30,minimum_trading_days=null,news_allowed=true,weekend_holding_allowed=true,
 payout_frequency='On demand at 5% growth or every 14 days at 1% growth',
 commercial_details=p.commercial_details||jsonb_build_object(
  'account_size_prices',$prices$[
   {"account_size":2000,"fee":59.99,"currency":"USD","region":"All regions"},{"account_size":5000,"fee":149.99,"currency":"USD","region":"All regions"},{"account_size":10000,"fee":299.99,"currency":"USD","region":"All regions"},{"account_size":20000,"fee":599.99,"currency":"USD","region":"All regions"}
  ]$prices$::jsonb,
  'payout_rules','Performance reward share is 70% from day one and up to 80% from tier 3. Requests are available on demand at 5% growth or every 14 days at 1% growth. No challenge-fee refund.',
  'fee_refund_policy','No refundable challenge fee applies to Stellar Instant.',
  'trading_rules','No target, daily loss limit or minimum trading days. Maximum loss is 6% trailing. News allowed; 40% of profit during the five-minute high-impact-event window counts toward reward. Weekend holding allowed; CFD accounts deactivate after 60 days without a trade. Forex leverage is 1:30.',
  'platforms_and_region','MT4 and MT5 are listed globally; U.S. traders can use Match-Trader only. Official U.S. availability statements conflict: a U.S. account guide includes the product, while the Help Center says U.S. clients do not have access due to MetaQuotes platform limits. Platform selection fee and switching rules apply where offered.',
  'review_note','Official U.S. materials conflict on Stellar Instant access. A U.S. guide lists pricing and availability; the Help Center says U.S. clients cannot access Stellar Instant because MetaQuotes is unavailable. Verify checkout eligibility.',
  'account_limitations','Product page advertises scaling up to $2M; this is not the initial account-size range.',
  'commission_details','Stellar Instant: $7 per lot Forex, 0.0016% commodities, 0.04% Crypto, 0.004% Stock; no commission on indices. Charged on opening only.',
  'regional_pricing_note','Help Center states these base prices match globally and in the U.S. Swap-free option costs 10% extra; promotions excluded.'
 ),
 updated_at=now()
from bullish_banana.firms f where p.firm_id=f.id and f.slug='fundednext' and p.slug='stellar-instant';

update bullish_banana.program_phases ph
set profit_target_percent=case when p.slug='stellar-1-step' then 10 when p.slug='stellar-2-step' and ph.phase_number=1 then 8 when p.slug='stellar-2-step' and ph.phase_number=2 then 5 when p.slug='stellar-lite' and ph.phase_number=1 then 8 when p.slug='stellar-lite' and ph.phase_number=2 then 4 else ph.profit_target_percent end,
 daily_drawdown_percent=case when p.slug='stellar-1-step' then 3 when p.slug='stellar-2-step' then 5 when p.slug='stellar-lite' then 4 else ph.daily_drawdown_percent end,
 maximum_drawdown_percent=case when p.slug='stellar-1-step' then 6 when p.slug='stellar-2-step' then 10 when p.slug='stellar-lite' then 8 else ph.maximum_drawdown_percent end,
 drawdown_type='static',
 minimum_trading_days=case when p.slug='stellar-1-step' then 2 else 5 end,
 raw_rules=ph.raw_rules||jsonb_build_object('day_requirement_label',case when p.slug='stellar-1-step' then 'At least 2 non-zero-P&L days; no pass deadline; 60-day inactivity deactivation' else 'At least 5 non-zero-P&L days per phase; no pass deadline; 60-day inactivity deactivation' end,'daily_loss_reference','Percentage of initial balance, reset at 00:00 server time')
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id and f.slug='fundednext'
where ph.program_id=p.id and p.slug in ('stellar-1-step','stellar-2-step','stellar-lite');

insert into bullish_banana.platforms (name,slug) values
 ('MetaTrader 4','metatrader-4'),('MetaTrader 5','metatrader-5'),('cTrader','ctrader'),('Match-Trader','match-trader')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select p.id,pl.id from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id and f.slug='fundednext'
join bullish_banana.platforms pl on pl.slug in ('metatrader-4','metatrader-5','ctrader','match-trader')
where p.slug in ('stellar-1-step','stellar-2-step','stellar-lite','stellar-instant')
on conflict (program_id,platform_id) do nothing;

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,s.url,s.label,s.notes from bullish_banana.firms f
cross join (values
 ('https://fundednext.com/cfds','FundedNext global CFD catalog','Lists active Stellar CFD models and global prices; reviewed 2026-09-30.'),
 ('https://fundednext.com/usa/cfds','FundedNext U.S. CFD catalog','U.S. active offers and region-specific prices; reviewed 2026-09-30.'),
 ('https://fundednext.com/general-rules/cfds/trading-objectives','FundedNext CFD objectives','Targets, loss limits, day rules, inactivity and reward-share overview; reviewed 2026-09-30.'),
 ('https://fundednext.com/general-rules/cfds/symbols-and-conditions','FundedNext symbols, commissions and leverage','Current CFD instruments, commissions and Forex leverage by model/stage; reviewed 2026-09-30.'),
 ('https://fundednext.com/general-rules/cfds/trading-platforms','FundedNext CFD platform rules','Platforms, regional access, platform costs, switching and legal roles; reviewed 2026-09-30.'),
 ('https://fundednext.com/general-rules/cfds/what-is-allowed','FundedNext allowed trading rules','News-profit treatment, copy trading and EA/VPS conditions; reviewed 2026-09-30.'),
 ('https://help.fundednext.com/en/articles/8020080-are-any-countries-restricted-on-fundednext-cfds','FundedNext restricted countries','Current Help Center country list dated 2026-08-27; legal-footer scope differences are noted.'),
 ('https://fundednext.com/usa/cfds/stellar-1-step','FundedNext Stellar 1-Step','Current U.S. model rules and base-fee schedule; reward timing conflict remains open.'),
 ('https://fundednext.com/cfds/stellar-2-step','FundedNext Stellar 2-Step Global','Global fees, account sizes and current challenge/payout/refund details.'),
 ('https://fundednext.com/usa/cfds/stellar-2-step','FundedNext Stellar 2-Step U.S.','U.S. fees and program conditions; sales excluded.'),
 ('https://fundednext.com/cfds/stellar-lite','FundedNext Stellar Lite Global','Global fees, account sizes, phase rules and reward/refund terms.'),
 ('https://fundednext.com/usa/cfds/stellar-lite','FundedNext Stellar Lite U.S.','U.S. fees, account sizes and program conditions.'),
 ('https://fundednext.com/usa/cfds/stellar-instant','FundedNext Stellar Instant','Current instant account rules, sizes, payout, news, holding and leverage.'),
 ('https://help.fundednext.com/en/articles/11641161-how-much-does-each-stellar-instant-account-cost','FundedNext Stellar Instant prices','Base account prices and same-global/U.S. fee statement; 10% swap-free premium.'),
 ('https://help.fundednext.com/en/articles/11641140-which-trading-platforms-are-available-for-the-stellar-instant-account','FundedNext Stellar Instant platforms','MT4/MT5 options and U.S. Match-Trader-only note.'),
 ('https://help.fundednext.com/en/articles/8027523-how-many-accounts-can-i-have-with-fundednext','FundedNext aggregate allocation limits','$300K combined allocation for Stellar 1-Step, 2-Step and Lite.')
) s(url,label,notes)
where f.slug='fundednext' and not exists(select 1 from bullish_banana.sources e where e.firm_id=f.id and e.source_url=s.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,s.url,s.label,s.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id and f.slug='fundednext'
join (values
 ('stellar-1-step','https://fundednext.com/usa/cfds/stellar-1-step','Stellar 1-Step rules and pricing','U.S. base-price schedule and product terms; first reward timing is held in review due to source discrepancy.'),
 ('stellar-2-step','https://fundednext.com/cfds/stellar-2-step','Stellar 2-Step global rules and pricing','Current global base price schedule, phases and payout/refund terms.'),
 ('stellar-2-step','https://fundednext.com/usa/cfds/stellar-2-step','Stellar 2-Step U.S. rules and pricing','Current U.S. base price schedule; promotions excluded.'),
 ('stellar-lite','https://fundednext.com/cfds/stellar-lite','Stellar Lite global rules and pricing','Current global size/fee matrix, phases, reward cycle and fee refund.'),
 ('stellar-lite','https://fundednext.com/usa/cfds/stellar-lite','Stellar Lite U.S. rules and pricing','Current U.S. schedule and leverage statement.'),
 ('stellar-instant','https://fundednext.com/usa/cfds/stellar-instant','Stellar Instant account terms','Current account sizes, fees shown, trailing loss and payout details; U.S. access conflict disclosed.'),
 ('stellar-instant','https://help.fundednext.com/en/articles/11641161-how-much-does-each-stellar-instant-account-cost','Stellar Instant base prices','Official size/price table; source states global and U.S. pricing is the same.')
) as s(slug,url,label,notes) on s.slug=p.slug
where not exists(select 1 from bullish_banana.sources e where e.program_id=p.id and e.source_url=s.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'FundedNext CFD legal roles, active models, prices, assets, platform and country rules reviewed from first-party sources 2026-09-30. Help Center and legal-footer country scopes differ for Iran/Russia.'
from bullish_banana.firms f where f.slug='fundednext'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

update bullish_banana.data_verifications v
set verified_at=now(),notes='FundedNext CFD legal roles, active models, prices, assets, platform and country rules reviewed from first-party sources 2026-09-30. Help Center and legal-footer country scopes differ for Iran/Russia.'
from bullish_banana.firms f where v.firm_id=f.id and f.slug='fundednext';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),s.note from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id and f.slug='fundednext'
join (values
 ('stellar-1-step','Rules, U.S. base-price matrix, platform/trading terms reviewed 2026-09-30. Kept in_review because first-reward timing differs across official pages.'),
 ('stellar-2-step','Global/U.S. price matrices, phases, payout/refund, platform/trading terms reviewed 2026-09-30.'),
 ('stellar-lite','Global/U.S. price matrices, phases, payout/refund, platform/trading terms reviewed 2026-09-30.'),
 ('stellar-instant','Base sizes/prices, loss/payout/trading terms reviewed 2026-09-30. Official U.S. availability statements conflict.')
) s(slug,note) on s.slug=p.slug
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);

update bullish_banana.data_verifications v
set verified_at=now(),notes=s.note
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id and f.slug='fundednext'
join (values
 ('stellar-1-step','Rules, U.S. base-price matrix, platform/trading terms reviewed 2026-09-30. Kept in_review because first-reward timing differs across official pages.'),
 ('stellar-2-step','Global/U.S. price matrices, phases, payout/refund, platform/trading terms reviewed 2026-09-30.'),
 ('stellar-lite','Global/U.S. price matrices, phases, payout/refund, platform/trading terms reviewed 2026-09-30.'),
 ('stellar-instant','Base sizes/prices, loss/payout/trading terms reviewed 2026-09-30. Official U.S. availability statements conflict.')
) s(slug,note) on s.slug=p.slug
where v.program_id=p.id;
