-- Fintokei first-party recheck captured 2026-09-30.
-- Add the Japan/Japanese-language ProTrader Slim variant and separate current eligibility categories.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set supported_assets=array['Forex','Metals','Energies','Indices']::text[],
    profile_details=fp.profile_details || '{
      "asset_scope_recheck":"Current Programs page FAQ says supported instruments are FX pairs and CFD metals, energies and indices, and explicitly says no crypto or stock trading. The previously reviewed instruments FAQ said crypto was available to all four standard families; retain this source conflict for review rather than asserting crypto support.",
      "restricted_jurisdiction_notes":"Who-can-join FAQ rechecked 2026-09-30. Service is unavailable to residents or citizens of Afghanistan, Belarus, Cuba, India, Iran, Iraq, Myanmar, North Korea, Russia, Somalia, South Sudan, Sudan, Syria, USA, Venezuela and Yemen; Bangladesh, China, Pakistan and Vietnam are temporarily restricted. New purchases are separately unavailable in Cambodia, Ethiopia, Ghana, Indonesia, Kenya, Malaysia, Morocco, Nigeria, Philippines, Saudi Arabia, Senegal, South Africa, Thailand, Türkiye, Ukraine and UAE. Do not merge the purchase-only list with service exclusions.",
      "legal_operator_update":"Current site names Fintokei a.s. as owner/operator and AXSE Brokerage Ltd. as the provider of trading platforms and technical infrastructure.",
      "protrader_slim":"Current Help Center identifies a Japan/Japanese-language ProTrader variant, JPY only, six plan labels (Quartz, Crystal, Pearl, Ruby, Sapphire, Topaz; no Emerald), MT5 only, special z-suffixed FX instruments, and 500 JPY round-turn commission. It states the variant follows standard ProTrader rules; current size/fee matrix is not public in the reviewed source and is not inferred."
    }'::jsonb,
    updated_at=now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='fintokei';

update bullish_banana.programs p
set commercial_details=p.commercial_details || '{"asset_scope_recheck":"Current Programs page says Forex/FX pairs and CFD metals, energies and indices; it explicitly excludes crypto and stocks. Previously reviewed official instruments FAQ states cryptocurrencies are supported by all four standard families, so retain the conflict for human review.","verification_date":"2026-09-30"}'::jsonb,
    updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='fintokei'
and p.slug in ('fintokei-starttrader','fintokei-swifttrader','fintokei-protrader','fintokei-protrader-swing');

insert into bullish_banana.programs (
 firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
 profit_split_percent,payout_frequency,minimum_trading_days,news_allowed,weekend_holding_allowed,
 commercial_details,published_at,archived_at
)
select f.id,'ProTrader Slim','fintokei-protrader-slim',
 'Japan/Japanese-language JPY variant of the simulated Forex CFD ProTrader evaluation; account-size and fee matrix not stated in the reviewed official source.',
 'evaluation','forex','in_review','JPY','[]'::jsonb,80,'Every 14 days',3,true,true,
 '{
   "account_size_and_fee_status":"Not stated in the reviewed public ProTrader Slim FAQ. Six plan labels are disclosed (Quartz, Crystal, Pearl, Ruby, Sapphire, Topaz); no Emerald. Do not infer starting capital or fee.",
   "eligibility":"Exclusive to JPY accounts and available only to people accessing/using Fintokei services from Japan or using Japanese as their primary communication language.",
   "platforms":["MetaTrader 5"],
   "instrument_note":"Special z-suffixed symbols required for the enhanced conditions. The FAQ lists 16 eligible FX symbols and says corresponding standard symbols remain read-only.",
   "commission":"500 JPY per round turn (250 JPY each side).",
   "trading_conditions":"The Help Center says ProTrader Slim follows standard ProTrader rules. Improved spreads are market-depth dependent; zero-spread condition applies only to top-of-book volume and can involve slippage.",
   "availability_note":"Not listed as a distinct family on the public USD Programs catalog; documented in the official Help Center for regional JPY customers. Keep in review pending current purchase path and complete fee/size matrix.",
   "verification_date":"2026-09-30"
 }'::jsonb,null,null
from bullish_banana.firms f
where f.slug='fintokei'
on conflict (firm_id,slug) do update
set name=excluded.name,description=excluded.description,program_type=excluded.program_type,
 market_type=excluded.market_type,status='in_review',currency=excluded.currency,
 account_sizes=excluded.account_sizes,profit_split_percent=excluded.profit_split_percent,
 payout_frequency=excluded.payout_frequency,minimum_trading_days=excluded.minimum_trading_days,
 news_allowed=excluded.news_allowed,weekend_holding_allowed=excluded.weekend_holding_allowed,
 commercial_details=excluded.commercial_details,published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.program_phases (
 program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
 maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,x.phase_number,x.name,x.target,x.daily,x.maximum,'static',null,3,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 (1,'Challenge Phase 1',8::numeric,5::numeric,10::numeric,'{"basis_note":"ProTrader Slim FAQ states it follows standard ProTrader rules; exact Slim-specific timing/definitions require current Terms confirmation."}'),
 (2,'Challenge Phase 2',6::numeric,5::numeric,10::numeric,'{"basis_note":"ProTrader Slim FAQ states it follows standard ProTrader rules; exact Slim-specific timing/definitions require current Terms confirmation."}')
) as x(phase_number,name,target,daily,maximum,rules) on true
where f.slug='fintokei' and p.slug='fintokei-protrader-slim'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
 daily_drawdown_percent=5,maximum_drawdown_percent=10,drawdown_type='static',
 time_limit_days=null,minimum_trading_days=excluded.minimum_trading_days,
 raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f
join (values
 ('https://www.fintokei.com/programs','Programs catalog recheck 2026-09-30','Current public catalog lists four USD families and says available assets are FX pairs, CFD metals, energies and indices; explicitly says crypto and stocks are not offered. This conflicts with a previously reviewed instruments FAQ that said crypto was available. Also supplies currently displayed USD matrices.'),
 ('https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim','ProTrader Slim FAQ recheck 2026-09-30','Japan/Japanese-language JPY-only variant; six plan labels; MT5 only; z-suffixed FX instruments and 500 JPY round-turn commission. Standard ProTrader rules apply. No size/fee matrix disclosed.'),
 ('https://support.fintokei.com/en/articles/6538820-who-can-join-fintokei','Current eligibility FAQ 2026-09-30','Separates countries excluded from service, temporarily restricted countries, and countries where new purchases are disabled; lists crypto payout availability by country.'),
 ('https://www.fintokei.com/terms-and-conditions/','General Terms landing page recheck 2026-09-30','Terms are provided as a linked PDF; current public page and Help Center disclose Fintokei a.s. and AXSE Brokerage Ltd. roles.')
) as x(url,label,notes) on true
where f.slug='fintokei'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url and s.notes like '%2026-09-30%');

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,'https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim',
 'ProTrader Slim official regional offer FAQ',
 'Reviewed 2026-09-30. Standard ProTrader rules; Japan/Japanese-language eligibility, JPY only, six plan labels excluding Emerald, MT5 only, special z-suffixed FX symbols, 500 JPY round-turn commission. Public source does not state plan capital sizes or fees.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='fintokei' and p.slug='fintokei-protrader-slim'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url='https://support.fintokei.com/en/articles/13913487-what-is-protrader-slim');

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'Rechecked Programs catalog, ProTrader Slim FAQ, who-can-join FAQ, Terms landing page and current support disclosure on 2026-09-30. Four public USD families remain; Slim is staged separately in review. Current public asset statement conflicts with the previously reviewed instruments FAQ on crypto. Service exclusions and paused new-purchase jurisdictions are separately recorded.'
from bullish_banana.firms f where f.slug='fintokei';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),'Current ProTrader Slim FAQ rechecked 2026-09-30. Rules follow standard ProTrader; eligibility/platform/currency/instruments/commission captured. Account sizes and price matrix are not stated in the reviewed public source; record remains in review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='fintokei' and p.slug='fintokei-protrader-slim';
