-- Refresh Top One Trader selector evidence from the live first-party checkout
-- observed 2026-09-30. Keep individual programs in review: the page exposed a
-- product-wide price range, not reliable per-variant prices.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles
set profile_details = profile_details || jsonb_build_object(
      'checkout_selector_reviewed_at', '2026-09-30',
      'checkout_product_families', array['1 Step', '2 Step', '2-Step Plus', '2-Step PRO', 'Instant', 'PRIME'],
      'checkout_platform_options', array['cTrader', 'MatchTrader', 'MetaTrader 5', 'TradeLocker'],
      'checkout_price_range_usd', jsonb_build_object('minimum', 39, 'maximum', 2537),
      'checkout_selector_note', 'Live unified checkout exposes the six family choices, account capital options, and platform options. The page returned a broad product price range and did not expose reliable per-variant prices during review; do not infer a fee from that range or map every platform to every program.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'top-one-trader');

update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
      'availability_note', 'The live official unified checkout selector observed 2026-09-30 lists this family. Product-level listing confirms a selectable family, but individual size, platform, add-on, and fee variants were not reliably returned; retain in review until those values are verified.',
      'checkout_reviewed_at', '2026-09-30'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'top-one-trader')
  and slug in ('1-step-flash', '1-step-nova', '2-step-plus', '2-step-pro-v2', 'instant-funding', 'instant-prime');

update bullish_banana.programs
set commercial_details = commercial_details || jsonb_build_object(
      'availability_conflict', 'Older official Help Center collection labels 2-Step PLUS discontinued, but the live unified checkout selector observed 2026-09-30 lists 2-Step Plus as a selectable family. Availability is therefore supported at selector level; exact variant terms and current fees remain unverified.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'top-one-trader')
  and slug = '2-step-plus';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, 'https://checkout.toponetrader.com/product/top-one-trader-challenges/', 'Top One Trader live unified checkout selector', 'Observed 2026-09-30 in a browser. Selector lists 1 Step, 2 Step, 2-Step Plus, 2-Step PRO, Instant, PRIME and platform options cTrader, MatchTrader, MetaTrader 5, and TradeLocker. Product page shows a broad $39-$2,537 range; exact per-size/per-platform fees were not returned reliably. A selectable family is not treated as confirmation of every combination.'
from bullish_banana.firms
where firms.slug = 'top-one-trader'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = 'https://checkout.toponetrader.com/product/top-one-trader-challenges/');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Rechecked live unified official checkout selector on 2026-09-30. It lists six product families and four platform options, but did not provide reliable per-variant fees; all six program records remain in review pending exact configuration/pricing verification.'
from bullish_banana.firms where firms.slug = 'top-one-trader';

-- The public Store API exposes purchasable price variants even when the browser
-- variation/cart AJAX endpoints fail. Preserve platform-specific base prices.
update bullish_banana.firm_profiles
set profile_details = profile_details || jsonb_build_object(
      'checkout_api_pricing_reviewed_at', '2026-09-30',
      'checkout_api_product_id', 108123,
      'checkout_api_variants', 151,
      'checkout_api_purchasable_variants', 150,
      'checkout_api_unavailable_variant', 'PRIME $100,000 returned $0 with no platform and was not purchasable; excluded from price records.',
      'checkout_api_note', 'The official WooCommerce Store API returned prices for 150 in-stock purchasable variations. Prices are stored as USD base fees, not promotional prices. Platform names on each price option reflect only that size/family combination; options are not assumed available across all sizes.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'top-one-trader');

update bullish_banana.programs
set account_sizes = case slug
      when '1-step-flash' then '[5000,10000,25000,50000,100000,200000]'::jsonb
      when '2-step-plus' then '[5000,10000,25000,50000,100000,200000]'::jsonb
      when '2-step-pro-v2' then '[5000,10000,25000,50000,100000,150000,300000]'::jsonb
      when 'instant-funding' then '[2500,5000,10000,25000,50000,100000,200000]'::jsonb
      when 'instant-prime' then '[2500,5000,10000,25000,50000,100000,200000]'::jsonb
      else account_sizes end,
    commercial_details = commercial_details || case slug
      when '1-step-flash' then '{"account_size_prices":[{"account_size":5000,"fee":64,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":10000,"fee":107,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":215,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":286,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":575,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":200000,"fee":1079,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Base fee by size and available checkout platform; official Store API snapshot reviewed 2026-09-30. No sale price was active."}'::jsonb
      when '2-step-plus' then '{"account_size_prices":[{"account_size":5000,"fee":78,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":10000,"fee":149,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":315,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":510,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":998,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":200000,"fee":1807,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Base fee by size and available checkout platform; official Store API snapshot reviewed 2026-09-30. No sale price was active."}'::jsonb
      when '2-step-pro-v2' then '{"account_size_prices":[{"account_size":5000,"fee":39,"currency":"USD","platform":"TradeLocker"},{"account_size":5000,"fee":69,"currency":"USD","platform":"MatchTrader, MetaTrader 5"},{"account_size":10000,"fee":162,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":209,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":435,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":541,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":150000,"fee":863,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":300000,"fee":1398,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Base fee by size and platform, including the $5,000 platform difference; official Store API snapshot reviewed 2026-09-30. No sale price was active."}'::jsonb
      when 'instant-funding' then '{"account_size_prices":[{"account_size":2500,"fee":84,"currency":"USD","platform":"MatchTrader, MetaTrader 5"},{"account_size":5000,"fee":135,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":10000,"fee":226,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":423,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":586,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":1142,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":200000,"fee":2537,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Base fee by size and available checkout platform; official Store API snapshot reviewed 2026-09-30. No sale price was active."}'::jsonb
      when 'instant-prime' then '{"account_size_prices":[{"account_size":2500,"fee":65,"currency":"USD","platform":"MatchTrader, MetaTrader 5"},{"account_size":5000,"fee":94,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":10000,"fee":158,"currency":"USD","platform":"cTrader"},{"account_size":10000,"fee":223,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":296,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":410,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":798,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":200000,"fee":1776,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Base fee by size and platform. cTrader is a lower price at $10,000. The $100,000 cTrader combination returned a non-purchasable $0 and is excluded. Official Store API snapshot reviewed 2026-09-30; no sale price was active."}'::jsonb
      else '{}'::jsonb end,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'top-one-trader')
  and slug in ('1-step-flash','2-step-plus','2-step-pro-v2','instant-funding','instant-prime');

-- The unified first-party checkout also exposes a current two-step family not
-- represented by the previously staged six comparison-page records.
insert into bullish_banana.programs (
  firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
  max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,
  news_allowed,weekend_holding_allowed,commercial_details
)
select firms.id,'Top One Trader 2-Step','2-step-standard',
  'Two-phase simulated Forex evaluation. Current checkout lists a 4% daily loss limit, 8% static maximum loss, unlimited time, and size/platform-specific fees; phase targets and several funded terms are not stated in the captured current selector.',
  'evaluation','forex','in_review','USD','[5000,10000,25000,50000,100000,200000]'::jsonb,
  null,null,null,null,null,null,
  '{"account_size_prices":[{"account_size":5000,"fee":119,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":10000,"fee":189,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":355,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":491,"currency":"USD","platform":"cTrader, MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":1057,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":200000,"fee":1807,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Live unified checkout Store API base prices captured by size/platform on 2026-09-30; no sale price active.","review_note":"The current checkout selector exposes a generic 2 Step family. Do not conflate it with the separately listed 2-Step Amped or 2-Step PRO V2. Current selector does not state phase targets; resolve the correct live rule article before publication.","time_limit":"Unlimited, as shown in current unified checkout.","fee_refund_policy":"Not stated for this selector family in captured current material."}'::jsonb
from bullish_banana.firms where firms.slug='top-one-trader'
on conflict (firm_id,slug) do update set
  name=excluded.name,description=excluded.description,program_type=excluded.program_type,
  market_type=excluded.market_type,status='in_review',currency=excluded.currency,
  account_sizes=excluded.account_sizes,commercial_details=excluded.commercial_details,
  published_at=null,updated_at=now();

insert into bullish_banana.program_phases (
  program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
  maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select programs.id,phase.phase_number,phase.name,null,4,8,'static',null,null,
  '{"time_limit":"Unlimited","source_note":"Current unified checkout identifies this as a two-step program and labels 4% daily loss and 8% static maximum drawdown with unlimited evaluation time; phase-specific targets and minimum-day rules are not stated in the captured current checkout. Kept in review."}'::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id=programs.firm_id and firms.slug='top-one-trader'
join (values (1,'Phase 1'),(2,'Phase 2')) as phase(phase_number,name) on true
where programs.slug='2-step-standard'
on conflict (program_id,phase_number) do update set
  name=excluded.name,profit_target_percent=excluded.profit_target_percent,
  daily_drawdown_percent=excluded.daily_drawdown_percent,
  maximum_drawdown_percent=excluded.maximum_drawdown_percent,
  drawdown_type=excluded.drawdown_type,time_limit_days=excluded.time_limit_days,
  minimum_trading_days=excluded.minimum_trading_days,raw_rules=excluded.raw_rules,updated_at=now();

-- A separate AMP ED offer is still listed and purchasable on the official site.
insert into bullish_banana.programs (
  firm_id,name,slug,description,program_type,market_type,status,currency,account_sizes,
  max_leverage,profit_split_percent,payout_frequency,minimum_trading_days,
  news_allowed,weekend_holding_allowed,commercial_details
)
select firms.id,'Top One Trader 2-Step Amped','2-step-amped',
  'Two-phase simulated Forex evaluation with 8% then 5% targets, 4% daily loss, 8% trailing maximum loss, and five qualifying days per phase.',
  'evaluation','forex','in_review','USD','[10000,25000,50000,100000,200000]'::jsonb,
  150,80,'Biweekly',5,true,true,
  '{"account_size_prices":[{"account_size":10000,"fee":142,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":25000,"fee":292,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":50000,"fee":492,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":100000,"fee":973,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"},{"account_size":200000,"fee":1853,"currency":"USD","platform":"MatchTrader, MetaTrader 5, TradeLocker"}],"pricing_source_note":"Official Store API direct product variations are in stock and purchasable; base price by size/platform captured 2026-09-30. No sale price active.","availability_note":"The official Help Center article is currently filed in a collection labeled discontinued, while the direct official checkout product and all 15 price variants returned in stock and purchasable on 2026-09-30. Keep in review until the operator resolves this conflict.","payout_rules":"Bi-weekly; on-demand add-on available. Funded traders need five days with at least 1% profit between payout cycles; minimum withdrawal is 2% of balance. Payout cap after scaling: $10,000 per 30 days.","consistency_rule":"No consistency rule stated in the current 2-Step Amped overview.","news_and_weekend_rules":"News and weekend holding allowed during both evaluation phases; neither allowed when funded.","prohibited_strategies":"Open risk limits: 2% on a single trade and 2.5% total floating drawdown. Official overview says Expert Advisors and external API usage are not allowed in evaluation or funded stages. Five soft breaches maximum.","commission_details":"$2.50 per side; swap fees apply.","fee_refund_policy":"Not stated in the reviewed Amped overview; verify before publication.","time_limit":"No challenge time limit stated; account inactivity limit is 30 consecutive days."}'::jsonb
from bullish_banana.firms where firms.slug='top-one-trader'
on conflict (firm_id,slug) do update set
  name=excluded.name,description=excluded.description,program_type=excluded.program_type,
  market_type=excluded.market_type,status='in_review',currency=excluded.currency,
  account_sizes=excluded.account_sizes,max_leverage=excluded.max_leverage,
  profit_split_percent=excluded.profit_split_percent,payout_frequency=excluded.payout_frequency,
  minimum_trading_days=excluded.minimum_trading_days,news_allowed=excluded.news_allowed,
  weekend_holding_allowed=excluded.weekend_holding_allowed,
  commercial_details=excluded.commercial_details,published_at=null,updated_at=now();

insert into bullish_banana.program_phases (
  program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
  maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select programs.id,phase.phase_number,phase.name,phase.target,4,8,'trailing',null,5,phase.rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id=programs.firm_id and firms.slug='top-one-trader'
join (values
  (1,'Phase 1',8::numeric,'{"minimum_profitable_day_percent":0.5,"source_note":"Official 2-Step Amped overview: five days of at least 0.5% profit in this phase."}'),
  (2,'Phase 2',5::numeric,'{"minimum_profitable_day_percent":0.5,"source_note":"Official 2-Step Amped overview: five days of at least 0.5% profit in this phase."}')
) as phase(phase_number,name,target,rules) on true
where programs.slug='2-step-amped'
on conflict (program_id,phase_number) do update set
  name=excluded.name,profit_target_percent=excluded.profit_target_percent,
  daily_drawdown_percent=excluded.daily_drawdown_percent,
  maximum_drawdown_percent=excluded.maximum_drawdown_percent,
  drawdown_type=excluded.drawdown_type,time_limit_days=excluded.time_limit_days,
  minimum_trading_days=excluded.minimum_trading_days,raw_rules=excluded.raw_rules,updated_at=now();

insert into bullish_banana.platforms (name,slug) values ('cTrader','ctrader')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.program_platforms (program_id,platform_id)
select programs.id,platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id=programs.firm_id and firms.slug='top-one-trader'
join bullish_banana.platforms on platforms.slug='ctrader'
where programs.slug in ('1-step-flash','2-step-standard','instant-funding','instant-prime')
on conflict do nothing;

insert into bullish_banana.program_platforms (program_id,platform_id)
select programs.id,platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id=programs.firm_id and firms.slug='top-one-trader'
join bullish_banana.platforms on platforms.slug in ('metatrader-5','match-trader','tradelocker')
where programs.slug in ('2-step-standard','2-step-amped')
on conflict do nothing;

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select programs.id,source.url,source.label,source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id=programs.firm_id and firms.slug='top-one-trader'
join (values
  ('1-step-flash','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-challenges','Top One Trader official checkout Store API price variants','Current base prices by account size/platform for the unified 1 Step family; all listed combinations included in the parent variant set. Captured 2026-09-30; no active sale prices.'),
  ('2-step-standard','https://checkout.toponetrader.com/product/top-one-trader-challenges/','Top One Trader unified 2 Step checkout','Current selector lists this two-step family and its account-size/platform variants. Checkout summary shows 4% daily loss, 8% static max loss, and unlimited time; phase targets were not stated in captured current material.'),
  ('2-step-standard','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-challenges','Top One Trader official checkout Store API price variants','Current base fees by account size/platform for the unified 2 Step family. Captured 2026-09-30; no active sale prices.'),
  ('2-step-amped','https://help.toponetrader.com/en/articles/14432028-2-step-amped-overview','Top One Trader 2-Step Amped Overview','First-party overview dated April 28, 2026 documents 8%/5% targets, 4% daily and 8% trailing max loss, five qualifying days per phase, platform/risk/payout information.'),
  ('2-step-amped','https://checkout.toponetrader.com/product/top-one-trader-2-step-amped-accounts/','Top One Trader 2-Step Amped checkout product','Official direct product page exposes five capital sizes and MatchTrader, MT5, TradeLocker variants; all 15 returned variants were in stock and purchasable during the 2026-09-30 review.'),
  ('2-step-amped','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-2-step-amped-accounts','Top One Trader official Amped Store API price variants','Captured current base fees for each size/platform combination on 2026-09-30; no active sale prices.'),
  ('2-step-plus','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-challenges','Top One Trader official checkout Store API price variants','Current base prices by size/platform for the unified 2-Step Plus family; captured 2026-09-30; no active sale prices.'),
  ('2-step-pro-v2','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-challenges','Top One Trader official checkout Store API price variants','Current base prices by size/platform for the unified 2-Step PRO family; includes platform-specific $5,000 fees; captured 2026-09-30; no active sale prices.'),
  ('instant-funding','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-challenges','Top One Trader official checkout Store API price variants','Current base prices by size/platform for the unified Instant family; captured 2026-09-30; no active sale prices.'),
  ('instant-prime','https://checkout.toponetrader.com/wp-json/wc/store/v1/products?slug=top-one-trader-challenges','Top One Trader official checkout Store API price variants','Current base prices by size/platform for the unified PRIME family; one $100,000 combination was not purchasable and is excluded; captured 2026-09-30; no active sale prices.')
) as source(program_slug,url,label,notes) on source.program_slug=programs.slug
where programs.slug in ('1-step-flash','2-step-standard','2-step-amped','2-step-plus','2-step-pro-v2','instant-funding','instant-prime')
  and not exists (select 1 from bullish_banana.sources existing where existing.program_id=programs.id and existing.source_url=source.url);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select programs.id,now(),'Rechecked official checkout Store API price/availability for the current size/platform variants on 2026-09-30. This verifies price variants, not unresolved rule distinctions; records remain in review where required.'
from bullish_banana.programs
join bullish_banana.firms on firms.id=programs.firm_id and firms.slug='top-one-trader'
where programs.slug in ('1-step-flash','2-step-standard','2-step-amped','2-step-plus','2-step-pro-v2','instant-funding','instant-prime');

insert into bullish_banana.affiliate_destinations (firm_id,program_id,kind,label,destination_url,is_primary,status)
select firms.id,programs.id,'official_site','View '||programs.name,
  case programs.slug
    when '2-step-amped' then 'https://checkout.toponetrader.com/product/top-one-trader-2-step-amped-accounts/'
    else 'https://checkout.toponetrader.com/product/top-one-trader-challenges/' end,
  true,'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id=firms.id
where firms.slug='top-one-trader' and programs.slug in ('2-step-standard','2-step-amped')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id=programs.id and existing.kind='official_site');
