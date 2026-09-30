-- Darwinex Zero is present in the user's 39-entry Forex discovery roster, but
-- official sources describe a subscription/allocation alternative, not a prop
-- challenge. Publish a clearly labeled firm profile and alternative detail;
-- challenge directory/comparison routes must continue to exclude program_type=other.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set status='published',
    published_at=coalesce(published_at,now()),
    market_type='forex',
    updated_at=now()
where slug='darwinex-zero';

update bullish_banana.firm_profiles
set legal_entity_name='Tradeslide Technologies Limited',
    country_code='GB',
    supported_assets=array['Forex','Indices','Commodities']::text[],
    profile_details=profile_details || jsonb_build_object(
      'service_model','Paid virtual trading membership with track-record analytics and merit-based access to investor-capital allocation programs; it is not a prop-firm challenge.',
      'service_classification','Darwinex Zero states that it is not a prop firm and does not sell pass/fail challenges.',
      'entity_scope_note','Darwinex Zero is a commercial name used by Tradeslide Technologies Limited (UK company no. 14398381). The company states Darwinex Zero is an introducer appointed representative of Tradeslide Trading Tech Ltd; do not conflate the membership operator with the Darwinex broker entity.',
      'jurisdiction_notes','Official Darwinex Zero documentation updated 2026-03-20 says subscriptions are available from any country without restrictions. Verify account-specific asset and broker terms separately.',
      'eligibility','Subscriptions are available from any country according to Darwinex Zero documentation updated 2026-03-20; this does not establish that every asset/account type is available worldwide.',
      'source_note','Official pricing, track-record, service-comparison and model pages rechecked 2026-09-30. Service is explicitly described as not being a prop challenge.'
    ),
    updated_at=now()
from bullish_banana.firms f
where firm_profiles.firm_id=f.id and f.slug='darwinex-zero';

update bullish_banana.programs p
set status='published',
    program_type='other',
    market_type='forex',
    commercial_details=p.commercial_details || jsonb_build_object(
      'service_type','Recurring virtual trading membership; not an evaluation challenge.',
      'program_model','Subscription access to a virtual Forex/CFD account, track-record analytics, and monthly DarwinIA allocation programs.',
      'eligibility','Worldwide subscription availability is stated in official Darwinex Zero documentation updated 2026-03-20. Account-type and instrument availability may vary.',
      'source_note','Official pricing, product, track-record and service-comparison pages rechecked 2026-09-30. Subscription prices below are the current public USD Forex & CFDs plans; taxes included.',
      'no_challenge_rules','No pass/fail challenge, challenge phase, target, daily loss limit, maximum drawdown rule or challenge minimum-day rule applies to this membership. No challenge phase rows are provided.',
      'allocation_and_rewards','A DARWIN index is created after approximately 15 days of trading activity and can participate in DarwinIA allocation while the membership is active. Further capital allocation depends on performance/ranking. The stated 15% performance fee applies to allocated capital, not virtual signal-account PnL.',
      'subscription_prices',jsonb_build_object(
        'monthly',jsonb_build_object('amount',50,'currency','USD','billing_period','month'),
        'annual',jsonb_build_object('amount',480,'currency','USD','billing_period','year','equivalent_monthly',40),
        'three_year',jsonb_build_object('amount',1260,'currency','USD','billing_period','3 years','equivalent_monthly',35)
      ),
      'platforms_note','MT4 and MT5 are listed for Forex & CFDs. TradingView is listed on the product page; platform and asset availability depend on the selected account type.'
    ),
    published_at=coalesce(p.published_at,now()),
    archived_at=null,
    updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='darwinex-zero' and p.slug='darwinex-zero-forex-cfds-membership';

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes
from bullish_banana.firms f
join (values
  ('https://www.darwinexzero.com/track-record','Darwinex Zero membership, operator and pricing','Official product page rechecked 2026-09-30. Identifies Tradeslide Technologies Limited as the commercial-name operator, its appointed-representative relationship, current Forex & CFDs membership prices, and the virtual-account/allocation model.'),
  ('https://www.darwinexzero.com/docs/en/darwinex-zero-versus-darwinex-classic','Darwinex Zero worldwide availability','Official documentation updated 2026-03-20 says Darwinex Zero subscriptions can be opened from any country; asset and broker account terms remain separate.'),
  ('https://www.darwinexzero.com/docs/what-is-darwinex-zero','Darwinex Zero model and DarwinIA','Official model explainer updated 2026-03-20 describes virtual accounts, automatic participation in seed-capital allocation programs and performance-fee model.')
) as x(url,label,notes) on true
where f.slug='darwinex-zero'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
  ('https://www.darwinexzero.com/pricing','Current Forex & CFDs membership pricing','Official pricing page rechecked 2026-09-30. Public USD plans: $50 monthly, $480 yearly ($40/month equivalent), and $1,260 for three years ($35/month equivalent); taxes included. Optional futures/crypto account fees and add-ons are excluded.'),
  ('https://www.darwinexzero.com/track-record','Membership model and published plan options','Official product page rechecked 2026-09-30. Describes the virtual Forex & CFDs membership, platform options, pricing plans and capital-allocation pathway; explicitly distinguishes the service from live brokerage trading.'),
  ('https://www.darwinexzero.com/docs/en/darwinex-zero-versus-darwinex-classic','Subscription eligibility','Official documentation updated 2026-03-20 says subscriptions can be opened from any country; do not infer universal instrument or broker eligibility.'),
  ('https://www.darwinexzero.com/docs/what-is-darwinex-zero','Allocation model and non-challenge rules','Official model explainer updated 2026-03-20 describes virtual trading, DarwinIA allocation and performance fees; no pass/fail challenge rules are stated.')
) as x(url,label,notes) on true
where f.slug='darwinex-zero' and p.slug='darwinex-zero-forex-cfds-membership'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

update bullish_banana.sources s
set source_label=x.label,notes=x.notes
from bullish_banana.firms f,
     (values
       ('https://www.darwinexzero.com/track-record','Darwinex Zero membership, operator and pricing','Official product page rechecked 2026-09-30. Identifies Tradeslide Technologies Limited as the commercial-name operator, its appointed-representative relationship, current Forex & CFDs membership prices, and the virtual-account/allocation model.'),
       ('https://www.darwinexzero.com/docs/en/darwinex-zero-versus-darwinex-classic','Darwinex Zero worldwide availability','Official documentation updated 2026-03-20 says Darwinex Zero subscriptions can be opened from any country; asset and broker account terms remain separate.'),
       ('https://www.darwinexzero.com/docs/what-is-darwinex-zero','Darwinex Zero model and DarwinIA','Official model explainer updated 2026-03-20 describes virtual accounts, automatic participation in seed-capital allocation programs and performance-fee model.')
     ) as x(url,label,notes)
where f.slug='darwinex-zero' and s.firm_id=f.id and s.source_url=x.url;

update bullish_banana.sources s
set source_label=x.label,notes=x.notes
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id,
     (values
       ('https://www.darwinexzero.com/pricing','Current Forex & CFDs membership pricing','Official pricing page rechecked 2026-09-30. Public USD plans: $50 monthly, $480 yearly ($40/month equivalent), and $1,260 for three years ($35/month equivalent); taxes included. Optional futures/crypto account fees and add-ons are excluded.'),
       ('https://www.darwinexzero.com/track-record','Membership model and published plan options','Official product page rechecked 2026-09-30. Describes the virtual Forex & CFDs membership, platform options, pricing plans and capital-allocation pathway; explicitly distinguishes the service from live brokerage trading.'),
       ('https://www.darwinexzero.com/docs/en/darwinex-zero-versus-darwinex-classic','Subscription eligibility','Official documentation updated 2026-03-20 says subscriptions can be opened from any country; do not infer universal instrument or broker eligibility.'),
       ('https://www.darwinexzero.com/docs/what-is-darwinex-zero','Allocation model and non-challenge rules','Official model explainer updated 2026-03-20 describes virtual trading, DarwinIA allocation and performance fees; no pass/fail challenge rules are stated.')
     ) as x(url,label,notes)
where f.slug='darwinex-zero' and p.slug='darwinex-zero-forex-cfds-membership'
  and s.program_id=p.id and s.source_url=x.url;

update bullish_banana.data_verifications v
set verified_at='2026-09-30T00:00:00Z'::timestamptz,
    notes='Official product, pricing and model sources reviewed 2026-09-30. Company identity and the introducer relationship are disclosed from the provider page; current service documentation states worldwide subscription availability. The service is not a conventional prop firm or challenge.'
from bullish_banana.firms f
where f.slug='darwinex-zero' and v.firm_id=f.id;

update bullish_banana.data_verifications v
set verified_at='2026-09-30T00:00:00Z'::timestamptz,
    notes='Current public Forex & CFDs subscription prices, worldwide service eligibility, virtual-account model and allocation process rechecked against official sources 2026-09-30. Program is published as an alternative model and excluded from challenge directory/comparisons.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='darwinex-zero' and p.slug='darwinex-zero-forex-cfds-membership' and v.program_id=p.id;

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,'2026-09-30T00:00:00Z'::timestamptz,
       'Official product, pricing and model sources reviewed 2026-09-30. Company identity and the introducer relationship are disclosed from the provider page; current service documentation states worldwide subscription availability. The service is not a conventional prop firm or challenge.'
from bullish_banana.firms f
where f.slug='darwinex-zero'
and not exists(select 1 from bullish_banana.data_verifications v where v.firm_id=f.id);

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,'2026-09-30T00:00:00Z'::timestamptz,
       'Current public Forex & CFDs subscription prices, worldwide service eligibility, virtual-account model and allocation process rechecked against official sources 2026-09-30. Program is published as an alternative model and excluded from challenge directory/comparisons.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='darwinex-zero' and p.slug='darwinex-zero-forex-cfds-membership'
and not exists(select 1 from bullish_banana.data_verifications v where v.program_id=p.id);

insert into bullish_banana.affiliate_destinations (firm_id,kind,label,destination_url,is_primary,status)
select f.id,'official_site','Explore Darwinex Zero','https://www.darwinexzero.com/track-record',true,'active'
from bullish_banana.firms f
where f.slug='darwinex-zero'
and not exists(select 1 from bullish_banana.affiliate_destinations d where d.firm_id=f.id and d.kind='official_site');

insert into bullish_banana.affiliate_destinations (firm_id,program_id,kind,label,destination_url,is_primary,status)
select f.id,p.id,'official_site','View Darwinex Zero membership','https://www.darwinexzero.com/pricing',true,'active'
from bullish_banana.firms f join bullish_banana.programs p on p.firm_id=f.id
where f.slug='darwinex-zero' and p.slug='darwinex-zero-forex-cfds-membership'
and not exists(select 1 from bullish_banana.affiliate_destinations d where d.program_id=p.id and d.kind='official_site');
