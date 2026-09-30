set search_path = bullish_banana, extensions, public;

-- The current Axi Select page names AxiTrader Limited for eligibility, while
-- the page footer identifies AxiTrader LLC as the site operator/trading name.
-- Preserve the discrepancy and keep the offer out of public publication until
-- Axi clarifies which entity contracts for Select clients.
update bullish_banana.firms
set status = 'in_review',
    published_at = null,
    updated_at = now()
where slug = 'axi-select';

update bullish_banana.firm_profiles
set legal_entity_name = null,
    profile_details = profile_details || jsonb_build_object(
      'eligibility_note', 'The current Axi Select page says the program is available only to clients of AxiTrader Limited. The same page footer says Axi is a trading name of AxiTrader LLC, a St Vincent and the Grenadines entity. These disclosures may have different regional scopes; do not infer that AxiTrader LLC is the Select contracting entity or imply worldwide eligibility.',
      'entity_scope_note', 'Entity and regional scope unresolved as of 2026-09-30: Axi Select eligibility footnote names AxiTrader Limited, while the global site footer says Axi is a trading name of AxiTrader LLC. Confirm the contracting entity and eligible jurisdictions with Axi before publication.',
      'platform_scope_note', 'Axi Select page supports Axi MT4 and MT5 accounts; program eligibility is explicitly scoped to AxiTrader Limited clients on the current page.',
      'source_checked_at', '2026-09-30'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'axi-select');

update bullish_banana.programs
set status = 'in_review',
    published_at = null,
    commercial_details = commercial_details || jsonb_build_object(
      'eligibility', 'Only AxiTrader Limited clients are named as eligible on the current official Axi Select page. The site footer names AxiTrader LLC as operator/trading name; contracting entity is unresolved.',
      'review_note', 'Publication held on 2026-09-30 pending written reconciliation of the AxiTrader Limited eligibility footnote and the AxiTrader LLC footer disclosure, and confirmation of eligible jurisdictions.',
      'verification_note', 'The official stage matrix still shows six stages, minimum equity from $500 to $20,000, Edge Score 50 to 90, allocation caps from $5,000 to $1,000,000, profit shares from 0% to 80%, stage-specific profit targets/durations/trade counts/leverage/max loss. Values are indicative and subject to change. No pass/fail challenge is sold.'
    ),
    updated_at = now()
where slug = 'axi-select-allocation'
  and firm_id = (select id from bullish_banana.firms where slug = 'axi-select');

update bullish_banana.sources
set captured_at = now(),
    notes = 'Official Axi Select page rechecked 2026-09-30. It states the program is available only to clients of AxiTrader Limited and displays six indicative stages through Pro M/$1M. The page footer says Axi is a trading name of AxiTrader LLC. The relationship between this footer and Select eligibility is unresolved; catalog remains in review.'
where firm_id = (select id from bullish_banana.firms where slug = 'axi-select')
  and source_url = 'https://www.axi.com/int/funded-trader-program';

update bullish_banana.sources
set captured_at = now(),
    notes = 'Axi corporate page checked 2026-09-30. Its footer says Axi is a trading name of AxiTrader LLC, incorporated in St Vincent and the Grenadines. The Axi Select page separately restricts eligibility to AxiTrader Limited clients; do not assume the two disclosures identify the same contracting entity.'
where firm_id = (select id from bullish_banana.firms where slug = 'axi-select')
  and source_url = 'https://www.axi.com/int/company/about-axi';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select id,
       'https://www.axi.com/int/company/about-axi',
       'Axi entity disclosure recheck',
       'Official Axi corporate page checked 2026-09-30. Axi Select eligibility footnote names AxiTrader Limited, while the current site footer says Axi is a trading name of AxiTrader LLC; contracting entity needs direct confirmation.'
from bullish_banana.firms
where slug = 'axi-select'
  and not exists (
    select 1 from bullish_banana.sources
    where firm_id = bullish_banana.firms.id
      and source_url = 'https://www.axi.com/int/company/about-axi'
  );

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Official Axi Select page, stage table, corporate page footer, and performance fee FAQ rechecked 2026-09-30. Six-stage allocation path and monthly performance fees remain documented; publication is held because the Select eligibility footnote names AxiTrader Limited while the site footer says Axi is a trading name of AxiTrader LLC. Eligible jurisdictions and contracting entity require confirmation.'
where firm_id = (select id from bullish_banana.firms where slug = 'axi-select');

update bullish_banana.data_verifications
set verified_at = '2026-09-30T00:00:00Z'::timestamptz,
    notes = 'Official six-stage Axi Select matrix and performance-fee FAQ rechecked 2026-09-30. Terms are indicative, and Select eligibility is stated only for AxiTrader Limited clients. Keep in review until the eligibility-footnote/site-footer entity and regional scope is resolved.'
where program_id = (
  select p.id from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'axi-select' and p.slug = 'axi-select-allocation'
);
