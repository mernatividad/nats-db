set search_path = bullish_banana, extensions, public;

-- Darwinex Zero's official product is a Forex virtual-membership/allocation service,
-- not a prop-firm challenge. Keep it review-only and model it as program_type=other.
insert into bullish_banana.firms (name,slug,description,website_url,status,market_type,published_at)
values ('Darwinex Zero','darwinex-zero','A virtual Forex/CFD trading membership for building a verified track record and pursuing merit-based investor-capital allocations; it does not offer a pass/fail prop challenge.','https://www.darwinexzero.com/','in_review','forex',null)
on conflict (slug) do update
set name=excluded.name,description=excluded.description,website_url=excluded.website_url,
    status='in_review',market_type='forex',published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.firm_markets (firm_id,market_type)
select id,'forex' from bullish_banana.firms where slug='darwinex-zero'
on conflict (firm_id,market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id,country_code,legal_entity_name,supported_assets,profile_details)
select id,'GB','Tradeslide Technologies Limited',
       array['Forex','Indices','Commodities']::text[],
       '{"company_number":"14398381","registered_address":"24 Fitzroy Square, London W1T 6EP, England","appointed_representative_disclosure":"Tradeslide Technologies Ltd is an introducer appointed representative of Tradeslide Trading Tech Ltd, FCA FRN 586466. Do not conflate Darwinex Zero''s service brand/operator with the Darwinex broker entity.","service_classification":"Darwinex Zero explicitly says it is not a prop firm and does not sell a prop challenge. It offers a virtual trader membership, track-record certification and merit-based allocation pathway.","supported_assets":"Forex, indices and commodities on the Forex & CFDs membership; other asset categories require different account types.","platforms":["TradingView","MetaTrader 4","MetaTrader 5"],"virtual_account":"Official assets page states CFD accounts start with $100,000 virtual equity. This is not a challenge size or live trading capital.","forex_leverage":"Up to 1:30 for Forex CFD accounts; actual leverage varies by symbol.","allocation_model":"A DARWIN index is created after approximately 15 days of trading activity and enters DarwinIA SILVER while the membership remains active. Further allocation depends on the DARWIN ranking/performance. Optional Boosters and permanent allocations are separate purchases.","performance_fee":"Official pages state 15% performance fees on allocated capital. This is not a challenge profit split.","eligibility":"March 2026 help-center documentation says subscriptions can be opened from any country; recheck current service Terms before publication.","source_note":"Official pricing selector and product pages checked 2026-09-28; current service is expressly not a prop-firm challenge."}'::jsonb
from bullish_banana.firms where slug='darwinex-zero'
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
select f.id,'Forex & CFDs Membership','darwinex-zero-forex-cfds-membership',
       'Subscription membership providing a virtual Forex/CFD trading account, track-record analytics and access to DarwinIA allocation programs. This is not a pass/fail challenge and has no evaluation phases.',
       'other','forex','in_review','USD','[]'::jsonb,30::numeric,null::numeric,null,null,
       null::boolean,null::boolean,
       '{"service_type":"recurring membership; not an evaluation challenge","subscription_prices":{"monthly":{"amount":50,"currency":"USD","billing_period":"month"},"annual":{"amount":480,"currency":"USD","billing_period":"year","equivalent_monthly":40},"three_year":{"amount":1260,"currency":"USD","billing_period":"3 years","equivalent_monthly":35}},"price_context":"Forex & CFDs membership price shown in USD on the official pricing selector. Taxes included. Do not treat limited promotions, add-ons, Boosters, permanent allocations, restart charges, or optional asset-specific account types as base Forex membership fees.","virtual_account_equity_usd":100000,"platforms":["TradingView","MetaTrader 4","MetaTrader 5"],"forex_leverage":"Up to 1:30; varies by instrument.","no_challenge_rules":"No fixed evaluation target, challenge phases, daily loss limit, maximum drawdown limit, minimum trading-day rule, or challenge pass/fail condition is stated for the standard membership. Do not fabricate phase rows or compare against challenge programs.","allocation_and_rewards":"After approximately 15 days of trading activity a DARWIN index is generated; it participates in monthly DarwinIA SILVER allocation. Additional allocations are merit-based. Stated 15% performance fee applies to profits on allocated capital, not to the virtual signal-account PnL as a challenge split.","source_note":"Live official pricing selector, track-record page, program FAQ and leverage FAQ reviewed 2026-09-28."}'::jsonb,
       null,null
from bullish_banana.firms f where f.slug='darwinex-zero'
on conflict (firm_id,slug) do update
set name=excluded.name,description=excluded.description,program_type='other',
    market_type='forex',status='in_review',currency='USD',account_sizes='[]'::jsonb,
    max_leverage=excluded.max_leverage,profit_split_percent=null,payout_frequency=null,
    minimum_trading_days=null,news_allowed=null,weekend_holding_allowed=null,
    commercial_details=excluded.commercial_details,published_at=null,archived_at=null,updated_at=now();

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f
join (values
 ('https://www.darwinexzero.com/track-record','Official track record and membership page','States this is not a prop challenge; details no challenge targets/drawdown rules, membership pricing and investor-capital model.'),
 ('https://www.darwinexzero.com/pricing','Official membership pricing selector','Forex & CFDs selected with MT5: $50 monthly, $40/month when billed yearly, or $35/month equivalent on three-year billing; selector checked 2026-09-28. Prices include taxes.'),
 ('https://www.darwinexzero.com/assets','Official assets and platforms page','Forex, indices and commodities on TradingView, MT4 and MT5; CFD virtual-account equity and platform-dependent product coverage.'),
 ('https://www.darwinexzero.com/docs/en/darwinex-zero-leverage','Official leverage FAQ','Updated 2026-03-19; maximum 1:30 for Forex CFD accounts and asset-dependent leverage.'),
 ('https://www.darwinexzero.com/docs/what-is-darwinex-zero','Official Zero model explainer','Subscription, virtual accounts, approximately 15 trading days to DARWIN creation, DarwinIA allocation and performance-fee model.'),
 ('https://www.darwinexzero.com/blog/is-darwinex-zero-a-prop-firm-the-answer-might-save-your-career','Official classification statement','Darwinex Zero says it is not a prop firm and explains its subscription/track-record certification and merit-based allocation model.'),
 ('https://www.darwinexzero.com/legal/terms-of-use','Official Terms of Use','Current legal terms and service conditions; recheck any eligibility statement before firm profile publication.')
) as x(url,label,notes) on true
where f.slug='darwinex-zero'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('https://www.darwinexzero.com/track-record','Forex membership model','Official statement that no prop challenge, monthly return target, or drawdown rule applies to membership.'),
 ('https://www.darwinexzero.com/pricing','Forex & CFDs membership price','USD monthly, annual and three-year subscription options captured in the official live selector on 2026-09-28.'),
 ('https://www.darwinexzero.com/assets','Forex product/assets/platforms','CFD virtual account, Forex product coverage and platform support.'),
 ('https://www.darwinexzero.com/docs/en/darwinex-zero-leverage','Forex leverage','Forex CFD maximum leverage 1:30; varies by instrument.'),
 ('https://www.darwinexzero.com/docs/what-is-darwinex-zero','DARWIN creation and allocation','Approximate initial track-record calibration and DarwinIA allocation workflow; no phase/pass criteria.')
) as x(url,label,notes) on true
where f.slug='darwinex-zero'
and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);
