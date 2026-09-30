begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'profit_target_rule', 'Selectable evaluation target: 6%, 10%, or 12%, chosen at checkout.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and ph.phase_number = 1
  and f.slug = 'alpha-capital-group' and p.slug = 'alpha-one'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://alphacapitalgroup.uk/product/alpha-one',
  'Alpha One selectable evaluation target variants — 2026-10-01',
  'Current official Alpha One product page states that traders choose a 6%, 10%, or 12% target at checkout. The challenge has one evaluation phase; the catalog displays the available target variants instead of implying one universal target.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_label = 'Alpha One selectable evaluation target variants — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked Alpha Capital Group’s current Alpha One product page: the single evaluation phase offers selectable 6%, 10%, and 12% targets at checkout. This record represents the choices and does not assign one target to all configurations.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked Alpha Capital Group’s current Alpha One product page: the single evaluation phase offers selectable 6%, 10%, and 12% targets at checkout. This record represents the choices and does not assign one target to all configurations.');

commit;
