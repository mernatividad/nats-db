begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platform_mapping', jsonb_build_object(
        'disclosure', 'The current Alpha Capital selector exposes platform choices, but the reviewed public selector and rules do not establish which choices apply to this specific plan. Plan-level platform assignment is therefore unconfirmed; check the live selector before purchase.',
        'scope', 'This is an offer-specific unknown, not a claim that no platform is available.',
        'reviewed_at', '2026-09-30',
        'source_url', 'https://alphacapitalgroup.uk/cs/product/alpha-pro'
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'alpha-capital-group'
  and p.slug in ('alpha-one','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing');

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platform_mapping', jsonb_build_object(
        'disclosure', 'The current Alpha Capital selector exposes platform choices, but the reviewed Alpha Direct page and rules do not establish which choices apply to this specific plan. Plan-level platform assignment is therefore unconfirmed; check the live selector before purchase.',
        'scope', 'This is an offer-specific unknown, not a claim that no platform is available.',
        'reviewed_at', '2026-09-30',
        'source_url', 'https://alphacapitalgroup.uk/product/alpha-direct'
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'alpha-capital-group' and p.slug = 'alpha-direct';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, 'Alpha Capital offer-specific platform scope — ' || p.name || ' — 2026-09-30',
  'Alpha Capital’s current selector exposes platform choices, but the reviewed offer page and its public rules do not map a platform selection to this specific plan. The program record marks that assignment as unconfirmed and directs users to verify their chosen configuration in the live selector.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('alpha-one', 'https://alphacapitalgroup.uk/product/alpha-one'),
  ('alpha-pro-6', 'https://alphacapitalgroup.uk/cs/product/alpha-pro'),
  ('alpha-pro-8', 'https://alphacapitalgroup.uk/cs/product/alpha-pro'),
  ('alpha-pro-10', 'https://alphacapitalgroup.uk/cs/product/alpha-pro'),
  ('alpha-swing', 'https://help.alphacapitalgroup.uk/en/articles/9789907-alpha-swing'),
  ('alpha-direct', 'https://alphacapitalgroup.uk/product/alpha-direct')
) as x(slug, url) on x.slug = p.slug
where f.slug = 'alpha-capital-group'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'Alpha Capital offer-specific platform scope — ' || p.name || ' — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T15:30:00Z'::timestamptz,
  'Rechecked the current Alpha Capital offer page and rules. Platform choices are selectable, but no offer-specific mapping was published in the reviewed source. The limitation is recorded as an explicit scope disclosure.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group'
  and p.slug in ('alpha-one','alpha-pro-6','alpha-pro-8','alpha-pro-10','alpha-swing','alpha-direct')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id
    and v.verified_at = '2026-09-30T15:30:00Z'::timestamptz);

commit;
