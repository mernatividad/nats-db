set search_path = bullish_banana, extensions, public;

-- Current official U.S. sources confirm Stellar Instant can be purchased by U.S.
-- clients when using Match-Trader. MetaQuotes restrictions constrain platform
-- choice; they do not make the offer unavailable in the United States.
update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    commercial_details = p.commercial_details || jsonb_build_object(
      'platforms_and_region', 'Global platform choices include MT4 and MT5 where offered. U.S.-based CFD clients can purchase Stellar Instant on Match-Trader only; MT4/MT5 are unavailable to U.S. clients under MetaQuotes restrictions. U.S. clients cannot switch to another platform. Current official May and June 2026 guidance and the promotion page updated this week explicitly include U.S. Stellar Instant purchases. The base-price schedule is the same globally and in the U.S.; do not mix temporary promotional prices into the base matrix.',
      'us_eligibility', 'Confirmed by FundedNext U.S. client guidance: Stellar Instant is available to U.S. residents on Match-Trader. MetaQuotes platform restrictions remove MT4/MT5 access but do not remove U.S. purchase eligibility.',
      'promotion_note', 'As checked 2026-09-30, the U.S. Stellar Instant page displays the coupon INSTANT30 with 30% off the shown base fees. A separate Help Center promotion updated this week advertises NEW25 for 25% off an initial Stellar purchase at $50K or below, including Stellar Instant, for new users; it does not apply to resets. Expiry and whether the two offers can be combined are not stated. Do not treat either discount as a base price or assume stacking; confirm the eligible offer at checkout.',
      'review_note', 'U.S. availability is confirmed; U.S. platform is Match-Trader only. Keep temporary coupons and discounts separate from the recorded base fees.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fundednext'
  and p.slug = 'stellar-instant';

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || jsonb_build_object(
      'jurisdiction_notes', replace(
        fp.profile_details->>'jurisdiction_notes',
        'U.S. clients are accepted but CFD platform choices are restricted to Match-Trader; product availability differs between official Stellar Instant U.S. materials.',
        'U.S. clients are accepted; Stellar Instant availability is confirmed, with Match-Trader as the only U.S. platform. Official May/June 2026 U.S. guidance and the September 30 promotion page agree. The separate Help Center/legal-footer restriction-list difference for Iran and Russia remains.'
      ),
      'stellar_instant_us_eligibility_verified_at', '2026-09-30'
    ),
    updated_at = now()
where fp.firm_id = (select id from bullish_banana.firms where slug = 'fundednext');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.source_url, x.source_label, x.notes
from bullish_banana.firms f
cross join (values
  ('https://help.fundednext.com/en/articles/11982074-does-fundednext-accept-u-s-clients', 'FundedNext U.S. client eligibility', 'Official U.S. Help Center page dated 2026-05-05 explicitly lists Stellar Instant among CFD offers U.S. clients can purchase and says U.S. CFD clients use Match-Trader.'),
  ('https://help.fundednext.com/en/articles/12673271-usa-client-guide-at-fundednext-cfd-accounts-platforms-rewards', 'FundedNext U.S. CFD client guide', 'Official guide dated 2026-06-16 explicitly lists Stellar Instant as available to U.S. clients, confirms Match-Trader is exclusive and no extra platform fee applies; temporary promotional prices are not treated as base fees.'),
  ('https://help.fundednext.com/en/articles/15450535-do-you-have-any-ongoing-offers-or-promotions', 'FundedNext current CFD promotion', 'Official promotion article updated this week (checked 2026-09-30) explicitly states Stellar Instant is available to U.S. residents on Match-Trader only. Promotion eligibility and discounts are time-limited and excluded from base-price data.')
) as x(source_url, source_label, notes)
where f.slug = 'fundednext'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id and s.source_url = x.source_url
  );

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'FundedNext CFD legal roles, active models, prices, platforms and country rules checked against official sources on 2026-09-30. Current U.S. guidance confirms Stellar Instant is available on Match-Trader. The Help Center country list and legal-footer restrictions still differ for Iran and Russia; preserve both scopes.'
where firm_id = (select id from bullish_banana.firms where slug = 'fundednext');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://help.fundednext.com/en/articles/11982074-does-fundednext-accept-u-s-clients', 'Stellar Instant U.S. eligibility', 'Official U.S. eligibility article explicitly lists Stellar Instant as purchasable by U.S.-based clients and identifies Match-Trader as the U.S. CFD platform.'),
  ('https://help.fundednext.com/en/articles/12673271-usa-client-guide-at-fundednext-cfd-accounts-platforms-rewards', 'Stellar Instant U.S. platform and reward rules', 'Official June 2026 U.S. guide confirms Instant is available on Match-Trader, unavailable on MT4/MT5, and has 70% starting reward share scaling to 80% after tier 3. U.S. clients are excluded from the 95% Lifetime Reward add-on.'),
  ('https://help.fundednext.com/en/articles/15450535-do-you-have-any-ongoing-offers-or-promotions', 'Current Stellar Instant U.S. offer scope', 'Official article updated this week confirms U.S. residents can buy Stellar Instant on Match-Trader only. The promotion is temporary; its coupon-adjusted price is not added to the base-fee schedule.')
) as x(source_url, source_label, notes)
where f.slug = 'fundednext'
  and p.slug = 'stellar-instant'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = x.source_url
  );

update bullish_banana.sources
set captured_at = now(),
    notes = 'Stellar Instant Help Center platform article rechecked 2026-09-30. U.S.-based Instant clients use Match-Trader only and cannot use MetaQuotes MT4/MT5; this is a platform limitation, not an eligibility denial. Newer official U.S. guidance confirms the U.S. purchase path.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundednext' and p.slug = 'stellar-instant'
)
  and source_url = 'https://help.fundednext.com/en/articles/11641140-which-trading-platforms-are-available-for-the-stellar-instant-account';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official U.S. Stellar Instant page checked 2026-09-30. U.S. purchase is available on Match-Trader and the page displays an INSTANT30 code with 30% off the shown base fee. The page does not state offer expiry or checkout stacking eligibility; retain base fees separately.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundednext' and p.slug = 'stellar-instant'
)
  and source_url = 'https://fundednext.com/usa/cfds/stellar-instant';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official promotion article updated the week of 2026-09-30. NEW25 is described as 25% off one initial CFD Stellar account priced at $50K or below, including Stellar Instant; resets are excluded. Expiration is not stated. Do not assume it stacks with the U.S. landing-page INSTANT30 coupon.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundednext' and p.slug = 'stellar-instant'
)
  and source_url = 'https://help.fundednext.com/en/articles/15450535-do-you-have-any-ongoing-offers-or-promotions';

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Stellar Instant base prices, account sizes, 6% trailing loss, on-demand/biweekly reward rules, platforms and U.S. eligibility checked against official sources on 2026-09-30. U.S. purchase eligibility is confirmed; Match-Trader is required and MT4/MT5 are unavailable. Temporary offers remain separate from base pricing.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundednext' and p.slug = 'stellar-instant'
);
