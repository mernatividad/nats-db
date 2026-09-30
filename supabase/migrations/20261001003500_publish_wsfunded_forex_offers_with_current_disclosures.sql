begin;
set search_path = bullish_banana, extensions, public;

-- Publish the seven current public Forex offers. Material source conflicts and
-- checkout-dependent details stay visible on the firm/program records.
update bullish_banana.firms
set status = 'published', published_at = coalesce(published_at, now()),
    archived_at = null, updated_at = now()
where slug = 'wall-street-funded';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
  'programs', jsonb_build_array('Instant Pro','Instant Standard','Classic','Ultra','Rapid','Elite','Power'),
  'supported_assets', 'Forex is in scope for this catalog. The firm also lists metals, commodities, indices, cryptocurrencies and stocks; instrument availability can differ by product.',
  'platform_scope_note', 'The firm lists MetaTrader 5, cTrader and MatchTrader. Availability by offer is not mapped in the reviewed official material. Wall Street Power is specifically MT5 only.',
  'service_model', 'WSFmarkets Ltd Terms state all accounts use fictitious funds and trading is simulated. The Instant Pro and Instant Standard FAQs describe real-money accounts. This material conflict is unresolved; the Terms description is shown provisionally.',
  'jurisdiction_conflict', 'Terms list the United States, Singapore, Russia, UAE and FATF/sanctioned jurisdictions. The FAQ gives a different restricted-country list. Confirm current eligibility at checkout.',
  'entity_scope_note', 'WSFmarkets Ltd is named as the legal operator in the Terms. WSF Technology FZCO is identified as technology provider and RENATICA LTD as handling payment operations; these entities have different stated roles.',
  'promotion_note', 'The current homepage advertises 35% off plus buy one, get one on the first withdrawal with code FUNDED2x1. Conditions and expiry were not captured; catalog fees do not include inferred coupon adjustments.',
  'profile_review', 'The Terms/instant-account description conflict, firm-wide eligibility lists, and firm-level platform mapping remain unresolved. Classic and Ultra selector/FAQ leverage values also conflict; leverage is left unspecified.'
), updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'wall-street-funded';

-- The current selector no longer shows the previously captured Elite discounts.
-- Represent the six current amounts as single prices; no coupon math is inferred.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'account_size_prices', '[{"account_size":2500,"fee":39,"currency":"USD"},{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":109,"currency":"USD"},{"account_size":25000,"fee":229,"currency":"USD"},{"account_size":50000,"fee":339,"currency":"USD"},{"account_size":100000,"fee":629,"currency":"USD"}]'::jsonb,
  'pricing_note', 'The current selector displays $39, $59, $109, $229, $339 and $629 for the listed sizes without paired discounted amounts. An earlier captured discounted matrix is stale. Homepage promotion code FUNDED2x1 is not applied to these prices; confirm final amount in checkout.',
  'promotion_note', 'Homepage advertises 35% off plus buy one, get one on the first withdrawal with code FUNDED2x1. Conditions and expiry are not stated in reviewed material; no adjusted price is inferred.',
  'service_model_disclosure', 'WSFmarkets Ltd Terms say all accounts are simulated demo accounts with fictitious funds. Instant-account FAQ language says real money. This conflict is unresolved; the legal Terms are used provisionally.',
  'eligibility_note', 'Firm Terms and Help Center country lists differ. Check current checkout eligibility; Wall Street Power additionally excludes Spain and Andorra.',
  'platforms', case when p.slug = 'power' then jsonb_build_array('MetaTrader 5') else jsonb_build_array('MetaTrader 5','cTrader','MatchTrader') end,
  'platforms_note', case when p.slug = 'power' then 'Official Power FAQ specifies MT5 only.' else 'These platforms are listed at firm level; availability for this offer is not mapped in reviewed official sources.' end,
  'published_source_recheck', '2026-09-30'
), status = 'published', published_at = coalesce(p.published_at, now()),
  archived_at = null, updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'wall-street-funded'
  and p.slug in ('rapid','power','classic','ultra','elite','instant-pro','instant-standard');

-- Current offer-selector prices changed for Elite. Keep the dated source record
-- but make clear that only the regular amounts are current.
update bullish_banana.sources s
set notes = 'Current public selector rechecked 2026-09-30. Elite lists $39/$59/$109/$229/$339/$629 for $2.5K/$5K/$10K/$25K/$50K/$100K, without paired discounted prices. Previously captured discounted figures are stale. Homepage promotion is separately disclosed; coupon price not inferred.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id and f.slug = 'wall-street-funded' and p.slug = 'elite'
  and s.source_url = 'https://wsfunded.com/en';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://wsfunded.com/en', 'Current public selector and promotion recheck — 2026-09-30',
  'Current selector shows seven Forex offers. Elite now displays only the regular six-size price matrix ($39 to $629); the previously captured discounted matrix is stale. Homepage promotion code FUNDED2x1 advertises 35% off and buy one, get one on the first withdrawal; conditions and expiry are not stated and no discount is inferred.'
from bullish_banana.firms f
where f.slug = 'wall-street-funded'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_label = 'Current public selector and promotion recheck — 2026-09-30');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://wsfunded.com/en', 'Current public selector recheck — 2026-09-30',
  case when p.slug = 'elite'
    then 'Current selector lists the regular Elite fee matrix without paired discounted values; prior discounted values are stale. Promotion conditions and expiry were not captured and are not applied to the displayed fee.'
    else 'Current public selector and homepage promotion rechecked 2026-09-30. The homepage advertises code FUNDED2x1; promotion conditions and expiry are not stated, so no adjusted price is inferred.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'wall-street-funded'
  and p.slug in ('rapid','power','classic','ultra','elite','instant-pro','instant-standard')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_label = 'Current public selector recheck — 2026-09-30');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T14:00:00Z'::timestamptz,
  'Rechecked official selector, homepage promotion, Terms and current Help Center materials on 2026-09-30. Seven public offers are represented. Terms/instant-account model and firm-wide restricted-country sources conflict; Classic/Ultra leverage and product platform mapping remain unresolved and are disclosed.'
from bullish_banana.firms f
where f.slug = 'wall-street-funded'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T14:00:00Z'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T14:00:00Z'::timestamptz,
  case when p.slug = 'elite'
    then 'Rechecked current Elite selector and official Elite FAQ 2026-09-30. Current selector lists six regular prices and no paired discounts; previously captured discounted amounts are stale. Promotion conditions and expiry are unknown and no coupon adjustment is inferred. Challenge rules remain linked to the current official FAQ.'
    when p.slug = 'power'
    then 'Rechecked the current Power Help Center and selector 2026-09-30. The offer is MT5 only; $9.99 initial fees and size-specific funded-stage charges remain separately represented. Spain and Andorra exclusion is product-specific. Firm-wide legal/FAQ eligibility and service-model conflicts remain disclosed.'
    else 'Rechecked current selector and corresponding official Help Center materials 2026-09-30. Current offer price matrix and challenge rules are represented. Firm-level platform availability is not mapped to this offer; Terms/instant-account model and eligibility discrepancies remain disclosed.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'wall-street-funded'
  and p.slug in ('rapid','power','classic','ultra','elite','instant-pro','instant-standard')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T14:00:00Z'::timestamptz);

insert into bullish_banana.affiliate_destinations (firm_id, kind, label, destination_url, is_primary, status)
select f.id, 'official_site', 'Visit Wall Street Funded', 'https://wsfunded.com/en', true, 'active'
from bullish_banana.firms f
where f.slug = 'wall-street-funded'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.firm_id = f.id and d.program_id is null and d.kind = 'official_site');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name,
  case when p.slug = 'power' then 'https://faq.wsfunded.com/en/articles/16859382-1-phase-wall-street-power'
       when p.slug = 'instant-pro' then 'https://faq.wsfunded.com/en/articles/10719208-instant-pro'
       when p.slug = 'instant-standard' then 'https://faq.wsfunded.com/en/articles/10719192-instant-standard'
       else 'https://wsfunded.com/en' end,
  true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
where f.slug = 'wall-street-funded'
  and p.slug in ('rapid','power','classic','ultra','elite','instant-pro','instant-standard')
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');

commit;
