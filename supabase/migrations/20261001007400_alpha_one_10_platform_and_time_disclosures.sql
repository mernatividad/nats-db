begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platform_mapping', jsonb_build_object(
        'disclosure', 'Alpha Capital lets buyers choose a trading platform during checkout. The reviewed official selector does not publish a single platform assignment for this Alpha One 10% record; confirm the available platform for your configuration in the live selector.',
        'scope', 'A checkout configuration choice; no single plan-level platform is asserted.',
        'reviewed_at', '2026-10-01',
        'source_url', 'https://alphacapitalgroup.uk/product/alpha-one'
      )
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'alpha-capital-group'
  and p.slug = 'alpha-one-10' and p.market_type = 'forex';

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'Alpha Capital states that Alpha One evaluations have no maximum trading-day cap.',
      'time_limit_scope', 'Alpha One 10% Forex evaluation',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'alpha-capital-group'
  and p.slug = 'alpha-one-10' and p.market_type = 'forex' and ph.phase_number = 1;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://alphacapitalgroup.uk/product/alpha-one',
   'Alpha One checkout platform selector — 2026-10-01',
   'The current official Alpha One page says buyers choose a trading platform during checkout. It does not establish a single platform for every checkout configuration, so the program records that selection as configuration-dependent.'),
  ('https://alphacapitalgroup.uk/product/alpha-one',
   'Alpha One evaluation duration — 2026-10-01',
   'The current official Alpha One page states there is no maximum trading-day cap. Applied to the listed Alpha One 10% evaluation variant.')
) as x(source_url, source_label, notes)
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one-10'
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked the current official Alpha One product page. Platform is chosen during checkout and no maximum trading-day cap applies to the Alpha One evaluation. Recorded the platform as configuration-dependent and the evaluation time limit as unlimited.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one-10'
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz);

commit;
