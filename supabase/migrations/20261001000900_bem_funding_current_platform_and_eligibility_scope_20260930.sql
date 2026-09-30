-- Reconcile BEM Funding's current platform/operator and eligibility disclosures.
-- Preserve the homepage Symbols page and master Terms scopes separately.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set legal_entity_name = 'BEX Software Development L.L.C-FZ',
    profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'service_operator', 'The current Symbols page identifies BEX Software Development L.L.C-FZ as the UAE company managing BEM Funding website products and services. The master Terms last updated 2026-01-01 call BEX Software Development LLC the Company. The Symbols page identifies BEM Ltd. (Saint Lucia registration 2026-00240) as MT5 platform operator; do not conflate it with the website/service operator.',
      'platform_entities', 'The current selector lists MT5 and cTrader for all four captured offers; base fees matched between these two options by size on 2026-09-30. The Symbols page identifies BEX Software Development L.L.C-FZ as operating cTrader and DXtrade, and BEM Ltd. (Saint Lucia registration 2026-00240) as operating MT5. DXtrade is not listed in the captured selector. The contracting entity for each selectable offer/platform was not confirmed.',
      'jurisdiction_notes', 'The Symbols page (effective 2026-04-13) lists the residents to whom BEM Funding does not offer services and separately says MT5 access is restricted to U.S. citizens and where use would violate local law. The master Terms last updated 2026-01-01 contain a different non-exhaustive Forbidden Territory list that includes Israel but omits jurisdictions named by the Symbols page. Preserve these source-specific scopes and confirm eligibility at checkout.',
      'refund_terms', 'The master Terms §9, last updated 2026-01-01, require a refund request within 14 days of purchase/service initiation and that the service remain primarily unused. Any simulated transaction counts as use and makes the account ineligible for a refund. The Symbols page also says fees are non-refundable unless unused. Check the applicable offer terms for any more specific condition.',
      'platform_eligibility_checked_at', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'bem-funding';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platform_operator_scope', 'The 2026-09-30 selector capture listed MT5 and cTrader for this offer. The current Symbols page says BEX Software Development L.L.C-FZ operates cTrader and DXtrade, while BEM Ltd. (Saint Lucia registration 2026-00240) operates MT5. DXtrade was not listed in the captured offer selector. Offer-specific contracting entity and DXtrade availability are not stated; confirm platform and local eligibility before purchase.',
      'platform_eligibility_note', 'The Symbols page effective 2026-04-13 lists restricted residents and says MT5 is restricted for U.S. citizens and where use would violate local rules. Its resident list differs from the master Terms list updated 2026-01-01. See firm profile disclosure; all offers remain in_review.',
      'refund_rules', 'General site Terms §9 (last updated 2026-01-01) allow refund requests within 14 days only while the service is primarily unused; any simulated transaction counts as use. The Symbols page also says fees are non-refundable unless unused. Confirm any offer-specific refund condition before purchase.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'bem-funding'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
       'https://bemfunding.com/symbols',
       'Trading symbols, platform operators and jurisdiction scope — current Symbols page',
       'Rechecked 2026-09-30. The page states BEX Software Development L.L.C-FZ manages BEM Funding website products/services and operates cTrader and DXtrade; BEM Ltd. (Saint Lucia registration 2026-00240) operates MT5. It separately lists residents to whom BEM Funding does not offer services and says MT5 access is restricted for U.S. citizens and where use would violate local law. Page effective date is 2026-04-13. Selector capture lists MT5 and cTrader for the four offers; it did not list DXtrade.'
from bullish_banana.firms f
where f.slug = 'bem-funding'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://bemfunding.com/symbols');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
       'https://bemfunding.com/terms-and-conditions',
       'Master Terms & Conditions — jurisdiction list and service relationship',
       'Rechecked 2026-09-30. The current page identifies BEX Software Development LLC as Company and was last updated 2026-01-01. Its non-exhaustive Forbidden Territory definition differs from the Symbols page effective 2026-04-13 (which includes a longer resident restriction list and distinct MT5 access wording). Preserve both dated source scopes; do not treat them as interchangeable.'
from bullish_banana.firms f
where f.slug = 'bem-funding'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://bemfunding.com/terms-and-conditions');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://bemfunding.com/symbols',
       'Current platform operators and eligibility disclosure',
       'Rechecked 2026-09-30. Symbols page (effective 2026-04-13) identifies BEX Software Development L.L.C-FZ as operator of cTrader/DXtrade and BEM Ltd. as operator of MT5. Current selector lists MT5 and cTrader for this offer; it did not list DXtrade. Site-level restricted-resident list and separate MT5 restriction are recorded in the firm profile. Program-specific contracting entity not confirmed.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'bem-funding'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://bemfunding.com/symbols');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, timestamptz '2026-09-30 00:00:00+00',
       'Current official Symbols page and master Terms rechecked. Platform operator and resident-eligibility scopes are preserved separately; the pages differ on restricted jurisdictions. The selector lists MT5/cTrader for all four offers while the Symbols page assigns those platforms to different entities. Offer-level contracting entity remains unconfirmed; firm and programs remain in_review.'
from bullish_banana.firms f
where f.slug = 'bem-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.notes like '%Current official Symbols page and master Terms rechecked%');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, timestamptz '2026-09-30 00:00:00+00',
       'Current official Symbols page rechecked: selector offers MT5 and cTrader, while the Symbols page attributes those platform operations to BEM Ltd. and BEX Software Development L.L.C-FZ respectively. Firm-level jurisdiction restriction list and master Terms list have different scopes. Program-specific contracting entity and DXtrade availability remain unconfirmed; offer remains in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'bem-funding'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.notes like '%Current official Symbols page rechecked: selector offers MT5 and cTrader%');
