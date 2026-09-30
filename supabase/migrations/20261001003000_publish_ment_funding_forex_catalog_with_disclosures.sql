begin;

-- Publish the current Forex offer with explicit disclosure of unresolved scope
-- conflicts. Prices remain the 2026-09-29 selector snapshot; no coupon math is inferred.
update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    minimum_trading_days = 0,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platforms', jsonb_build_array('DXtrade', 'MatchTrader', 'cTrader', 'GooeyPro'),
      'platforms_note', 'Ment public Forex materials name DXtrade, MatchTrader, cTrader, and GooeyPro. The firm does not map availability to this plan, account size, or region; confirm the offered platform in the current order flow.',
      'time_limit', 'No minimum or maximum evaluation time is stated for this Forex program.',
      'minimum_trading_days', 'No minimum trading days.',
      'allocation_conflict', 'The current Forex selector directly offers a $2,000,000 size, while Terms section 13 state a maximum $1,000,000 in active evaluation or funded plans per person. The controlling applicability of the $1M cap to the displayed $2M offer is unresolved; confirm with Ment before purchase.',
      'review_note', 'Material account-allocation, contracting-entity, jurisdiction, and plan-specific platform details remain unresolved. Current listed sizes and price pairs were captured 2026-09-29; the homepage separately advertised code RETURNSDAY through 2026-09-30. No discounted checkout price was calculated. Confirm eligibility, contracting entity, platform, allocation and final payable amount with Ment.',
      'promotion_note', 'Homepage advertised code RETURNSDAY for 16% off through 2026-09-30 when reviewed. This is a dated promotion; the stored size and fee pairs are the 2026-09-29 selector snapshot before coupon entry, and no adjusted price is inferred.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'ment-funding' and p.slug = 'forex-1-step';

update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'No minimum or maximum evaluation time is stated for this Forex program.',
      'time_limit_source_reviewed', '2026-09-30',
      'no_minimum_trading_days', true,
      'minimum_trading_days', 'No minimum trading days.'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'ment-funding' and p.slug = 'forex-1-step';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'allocation_conflict', 'Current Forex selector directly offers a $2,000,000 size; Terms section 13 state a maximum $1,000,000 in active evaluation or funded plans per person. Applicability is unresolved; confirm with Ment before purchase.',
      'platform_scope_note', 'Official Forex materials name DXtrade, MatchTrader, cTrader, and GooeyPro, but do not map availability to account size or region. Confirm current offer configuration.',
      'legal_entity_conflict', 'Public Terms name entities within the Prop Account group, but the exact contracting entity for this Forex offer is not identified. Confirm the counterparty in the current order documents.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'ment-funding';

update bullish_banana.firms
set status = 'published', published_at = coalesce(published_at, now()),
    archived_at = null, updated_at = now()
where slug = 'ment-funding';

insert into bullish_banana.affiliate_destinations
  (firm_id, kind, label, destination_url, is_primary, status)
select f.id, 'official_site', 'Visit Ment Funding', 'https://mentfunding.com/', true, 'active'
from bullish_banana.firms f
where f.slug = 'ment-funding'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.kind = 'official_site'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:25:00Z'::timestamptz,
  'Rechecked Ment official Forex homepage and Terms on 2026-09-30. Homepage states no minimum or maximum evaluation time and no minimum trading days. Selector directly lists a $2M Forex size while Terms section 13 states a $1M cap on active evaluation/funded plans per person; applicability remains unresolved and disclosed. Current homepage advertises RETURNSDAY through 2026-09-30. Seven size/price pairs remain the 2026-09-29 capture and were not recalculated. Platform options, exact contracting entity, and full jurisdiction list remain subject to confirmation.'
from bullish_banana.firms f
where f.slug = 'ment-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T13:25:00Z'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T13:25:00Z'::timestamptz,
  'Official Forex homepage rechecked 2026-09-30: one-step 10% target, 5% daily loss, 6% static maximum loss, no minimum/maximum evaluation duration, and no minimum trading days. Seven account sizes and price pairs remain the selector capture from 2026-09-29; current promo is separately disclosed without calculating a discounted fee. $2M selector versus $1M Terms allocation cap remains unresolved.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'ment-funding' and p.slug = 'forex-1-step'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T13:25:00Z'::timestamptz);

commit;
