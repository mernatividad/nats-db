-- Preserve product/region scope for FundedNext country restrictions.
update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'jurisdiction_notes', 'As of 2026-09-30, the FundedNext CFD Help Center list updated 2026-08-27 and the U.S. Terms of Service (last updated 2026-05-05) Section 5.3 agree on the same 20 restricted CFD countries. The U.S. CFD landing page footer separately lists North Korea, Myanmar, Belarus, Iran and Russia. Its U.S. Terms Section 5.4 assign Iran and Russia to the Futures restricted list, while Section 5.3 excludes both from its CFD list. Preserve the U.S. landing-page discrepancy as source-scoped evidence; do not add Iran or Russia to the unqualified CFD restriction list based on the Futures list. The Terms reserve case-specific restrictions for sanctions, regulators, payment networks and providers. U.S. CFD participation is supported through eligible platforms; MetaQuotes platform/IP availability is a separate platform restriction.',
      'cfd_restriction_source_scopes_2026_09_30', jsonb_build_object(
        'global_help_center', jsonb_build_object('url','https://help.fundednext.com/en/articles/8020080-are-any-countries-restricted-on-fundednext-cfds','updated','2026-08-27','count',20,'scope','CFD services'),
        'usa_terms', jsonb_build_object('url','https://fundednext.com/usa/terms-of-service','updated','2026-05-05','cfd_section','5.3','futures_section','5.4','scope','Separate CFD and Futures jurisdiction lists; Iran and Russia appear in Futures list but not in CFD list'),
        'usa_cfd_landing_page', jsonb_build_object('url','https://fundednext.com/usa/cfds','scope','Page footer says FundedNext Ltd does not offer services to residents of North Korea, Myanmar, Belarus, Iran and Russia; this is inconsistent with the U.S. Terms CFD list as to Iran and Russia')
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id
  and f.slug = 'fundednext';

-- These entries were previously stored as unqualified restrictions even
-- though the current CFD terms omit them. Keep them visible as unresolved.
update bullish_banana.restrictions r
set restriction_type = 'unknown',
    note = 'Unresolved CFD scope conflict: the U.S. CFD landing-page footer lists this country, but the U.S. Terms Section 5.3 and current CFD Help Center list do not. U.S. Terms Section 5.4 includes it for Futures. Do not treat as an established CFD restriction until FundedNext clarifies the page-level discrepancy.',
    updated_at = now()
from bullish_banana.firms f
where r.firm_id = f.id
  and f.slug = 'fundednext'
  and r.country_code in ('IR', 'RU');

insert into bullish_banana.sources (firm_id, source_url, source_label, notes, captured_at)
select f.id,
       src.source_url,
       src.source_label,
       src.notes,
       '2026-09-30 02:37:37+00'::timestamptz
from bullish_banana.firms f
cross join (values
  (
    'https://fundednext.com/usa/terms-of-service',
    'FundedNext USA Terms of Service — CFD vs Futures restriction scopes — 2026-09-30',
    'Current page states last updated 2026-05-05. Section 5.3 lists 20 restricted CFD countries; Section 5.4 separately lists Futures restrictions, which include Iran and Russia. Sections 5.5–5.6 reserve additional case-specific and sanctions restrictions.'
  ),
  (
    'https://fundednext.com/usa/cfds',
    'FundedNext USA CFD landing page — jurisdiction footer — 2026-09-30',
    'Current public page footer says services are not offered in North Korea, Myanmar, Belarus, Iran and Russia. The last two are absent from the U.S. Terms CFD list, while listed in that document under Futures. Preserve this as a page-level/Terms discrepancy; do not infer an unqualified CFD list.'
  )
) as src(source_url, source_label, notes)
where f.slug = 'fundednext'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.firm_id = f.id
      and s.source_url = src.source_url
      and s.source_label = src.source_label
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id,
       '2026-09-30 02:37:37+00'::timestamptz,
       'Rechecked FundedNext CFD jurisdiction disclosures 2026-09-30. CFD Help Center and U.S. Terms §5.3 align on 20 countries. U.S. CFD landing footer also names Iran/Russia, which U.S. Terms §5.4 scope to Futures and omit from §5.3 CFD list. Preserve the source-specific conflict; do not treat Futures restrictions as CFD terms. The firm/program records remain in review pending other facts and any needed clarification.'
from bullish_banana.firms f
where f.slug = 'fundednext'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.firm_id = f.id
      and v.verified_at = '2026-09-30 02:37:37+00'::timestamptz
      and v.notes like 'Rechecked FundedNext CFD jurisdiction disclosures 2026-09-30%'
  );
