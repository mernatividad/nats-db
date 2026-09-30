begin;

-- The current Axi Select Help Center explicitly scopes program availability
-- to AxiTrader LLC clients. Keep the unresolved country-by-country matrix
-- visible, but do not hold an otherwise complete roster record in review.
update bullish_banana.firms f
set status = 'published',
    published_at = coalesce(f.published_at, now()),
    archived_at = null,
    updated_at = now()
where f.slug = 'axi-select' and f.status = 'in_review';

update bullish_banana.firm_profiles fp
set legal_entity_name = 'AxiTrader LLC',
    profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'entity_scope_note', 'Axi Select-specific Help Center identifies eligible clients as clients under AxiTrader LLC. The global footer also identifies AxiTrader LLC as the Axi trading name.',
      'eligibility_note', 'Axi Select is available to clients under AxiTrader LLC. A complete country-by-country eligibility matrix was not found; confirm current country availability with Axi before opening an account.',
      'region_note', 'The official global page says its information is not intended for residents of Australia and New Zealand. Regional product availability may vary; verify eligibility for the specific country and account entity.',
      'source_checked_at', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'axi-select';

update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'eligibility', 'Available to clients under AxiTrader LLC according to the current Axi Select Help Center. Full country eligibility remains unstated in reviewed public sources.',
      'review_note', 'Published as a no-fee capital-allocation alternative, not a pass/fail challenge. Axi Select-specific entity scope is documented; verify country availability with Axi.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'axi-select' and p.slug = 'axi-select-allocation' and p.status = 'in_review';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://help.axi.com/en-US/axiv2--axicorp-prod/article/1YzJXzUf-what-is-axi-select',
  'Axi Select Help Center overview',
  'Official program-specific article states Axi Select is available to clients under AxiTrader LLC and confirms this is a free capital-allocation program rather than a third-party challenge; checked 2026-09-30.'
from bullish_banana.firms f
where f.slug = 'axi-select'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://help.axi.com/en-US/axiv2--axicorp-prod/article/1YzJXzUf-what-is-axi-select');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.axi.com/en-US/axiv2--axicorp-prod/article/1YzJXzUf-what-is-axi-select',
  'Axi Select Help Center overview',
  'Official program-specific article states this offer is available to clients under AxiTrader LLC, has no third-party evaluation challenge, and includes six progression stages; checked 2026-09-30.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'axi-select' and p.slug = 'axi-select-allocation'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://help.axi.com/en-US/axiv2--axicorp-prod/article/1YzJXzUf-what-is-axi-select');

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Axi Select Help Center explicitly scopes program availability to AxiTrader LLC clients, resolving the previous entity-scope conflict. The complete country eligibility matrix remains unavailable and is disclosed on the profile.')
from bullish_banana.firms f
where v.firm_id = f.id and f.slug = 'axi-select' and v.verified_at::date = '2026-09-30';

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30'::timestamptz,
  'Axi Select Help Center explicitly scopes program availability to AxiTrader LLC clients, resolving the previous entity-scope conflict. The complete country eligibility matrix remains unavailable and is disclosed on the profile.'
from bullish_banana.firms f
where f.slug = 'axi-select'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at::date = '2026-09-30');

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Rechecked current Axi Select Help Center and program page. Entity scope is AxiTrader LLC clients; this is a free capital-allocation program, not a challenge. Country eligibility remains incompletely mapped and is disclosed.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where v.program_id = p.id and f.slug = 'axi-select' and p.slug = 'axi-select-allocation' and v.verified_at::date = '2026-09-30';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30'::timestamptz,
  'Rechecked current Axi Select Help Center and program page. Entity scope is AxiTrader LLC clients; this is a free capital-allocation program, not a challenge. Country eligibility remains incompletely mapped and is disclosed.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'axi-select' and p.slug = 'axi-select-allocation'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at::date = '2026-09-30');

commit;
