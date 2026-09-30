set search_path = bullish_banana, extensions, public;

-- Official Nordic legal pages and their linked client-terms document rechecked 2026-09-30.
-- This does not resolve the offer-specific entity conflict or make records publishable.

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "legal_entity_recheck_2026_09_30": {
    "nordic_about_and_terms_body": "Nordic Funder states that Forest Park FX LTD provides fee-based simulated assessments and enters the funded Trader Agreement.",
    "nordic_legal_footer_conflict": "Current Nordic About and Terms pages also say Prop Account, LLC provides assessments and Prop Account LC is the funded Trader Agreement counterparty.",
    "linked_client_terms": "The linked September 2026 Client Terms And Policies document defines Company as the Prop Account Group of Companies and names Prop Account d/b/a Dashboard Analytix, Forest Park FX LTD, Prop Account LLC, Prop Account Cayman and Prop Account LC. It does not map the Nordic offer to one assessment provider or contracting entity, so it does not resolve the offer-specific conflict.",
    "terms_status": "Nordic Terms page still says awaiting counsel sign-off and states that operative Trader Agreement clauses, dispute resolution, governing law, account-closure grounds and the complete prohibited-practices schedule still need approval/migration.",
    "refund_and_age": "Linked client terms state age 18+, with no refunds on services purchased. Applicability and precedence for Nordic''s specific offers should be checked against the eventual signed Nordic terms.",
    "instant_funding_lite_forex_scope": "Instant Funding Lite remains a separate top-level product category, outside the five-track FX & CFDs page. Its page states 30:1 leverage but does not explicitly map Forex symbols/instruments to the offer. Keep it outside the Forex program set pending direct asset eligibility evidence.",
    "jurisdiction_status": "Do not infer a Nordic-wide restricted-country list from general client-terms jurisdiction language; the live Nordic legal page still does not publish a complete product-specific list."
  }
}'::jsonb,
updated_at=now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='nordic-funder';

update bullish_banana.sources s
set notes = concat(s.notes, E'\nRechecked 2026-09-30: this page still says awaiting counsel sign-off and its operative terms are incomplete. Body names Forest Park FX LTD, while its current legal footer names Prop Account, LLC / Prop Account LC. The conflict remains unresolved.')
from bullish_banana.firms f
where s.firm_id=f.id and f.slug='nordic-funder'
  and s.source_url='https://nordicfunder.com/legal/terms/'
  and s.notes not like '%Rechecked 2026-09-30%';

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,'https://dashboardanalytix.com/client-terms-and-policies/','Linked Prop Account Group client terms — September 2026',
       'Document linked from Nordic Funder’s current Terms page and marked last updated September 2026. It defines Company as the Prop Account Group of Companies, listing Prop Account d/b/a Dashboard Analytix, Forest Park FX LTD, Prop Account LLC, Prop Account Cayman, and Prop Account LC. It describes age 18+, no refunds, and a trader agreement after passing, but does not map a particular Nordic assessment to one group entity. Nordic About and Terms pages continue to name inconsistent assessment providers/counterparties, so leave the offer-specific legal operator unresolved.'
from bullish_banana.firms f
where f.slug='nordic-funder'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url='https://dashboardanalytix.com/client-terms-and-policies/' and s.source_label='Linked Prop Account Group client terms — September 2026');

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,'https://nordicfunder.com/programs/instant-funding/','Instant Funding Lite market-scope recheck — 2026-09-30',
       'Current separate Instant Funding Lite page lists a no-assessment product from $2.5K to $100K, with 30:1 leverage, 3% static max drawdown, 1% intraday trailing daily loss, 20% funded consistency, 80% split, 14-day inactivity limit, and a one-time fee. The site lists this as a separate category from the five-track FX & CFDs programme. The page text does not state Forex instruments/asset eligibility for this offer; do not include it as a Forex program without direct symbol/eligibility confirmation.'
from bullish_banana.firms f
where f.slug='nordic-funder'
and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url='https://nordicfunder.com/programs/instant-funding/' and s.source_label='Instant Funding Lite market-scope recheck — 2026-09-30');

update bullish_banana.sources s
set notes=concat(s.notes, E'\nRechecked 2026-09-30: this page still publishes five FX & CFDs evaluation tracks and does not include Instant Funding Lite in that program set. Track rules and matrices remain as previously staged; the newly checked issue is unresolved provider/terms scope, not a program-rule correction.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where s.program_id=p.id and f.slug='nordic-funder'
  and p.slug in ('one-step','two-step','three-step','one-step-lite','two-step-lite')
  and s.source_url='https://nordicfunder.com/programs/fx-cfd/'
  and s.notes not like '%Rechecked 2026-09-30%';

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),
       'Nordic About/Terms and linked September 2026 Prop Account Group client-terms document rechecked 2026-09-30. Public Nordic body and footer still conflict between Forest Park FX LTD and Prop Account, LLC/LC; group terms do not resolve the offer-specific provider. Terms remain marked awaiting counsel sign-off. Instant Funding Lite remains separately categorized without explicit Forex instrument eligibility. Keep firm in_review.'
from bullish_banana.firms f where f.slug='nordic-funder';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),
       'Official FX & CFDs page rechecked 2026-09-30; the five staged evaluation tracks remain the current program set. No rule or fee correction was identified. Offer remains in_review because operative legal and restriction terms and product-specific platform/asset mapping remain unresolved.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='nordic-funder'
  and p.slug in ('one-step','two-step','three-step','one-step-lite','two-step-lite');
