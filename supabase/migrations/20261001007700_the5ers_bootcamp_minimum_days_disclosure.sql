begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'day_requirement_note', 'The current official Bootcamp program specifications and FAQ do not state a minimum trading-day requirement for this evaluation phase. No minimum has been confirmed.',
      'day_requirement_scope', 'Bootcamp evaluation phase',
      'day_requirement_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'the5ers'
  and p.slug = 'bootcamp' and p.market_type = 'forex'
  and ph.minimum_trading_days is null;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label || ' — 2026-10-01', x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://the5ers.com/bootcamp/', 'The5ers current Bootcamp specifications', 'The current official Bootcamp page publishes its account sizes, phase targets, loss limits, time limits, leverage, and trading rules. It does not specify a minimum evaluation trading-day count.'),
  ('https://the5ers.com/faqs/how-does-the-bootcamp-program-work/', 'The5ers Bootcamp evaluation FAQ', 'The official FAQ, updated 2026-09-06, describes the three evaluation phases and their rules. It states the evaluation has no time limit but does not specify a minimum trading-day count.')
) as x(source_url, source_label, notes)
where f.slug = 'the5ers' and p.slug = 'bootcamp' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked the current official Bootcamp product page and FAQ. Both describe the evaluation model; neither states a minimum trading-day count. Recorded the missing minimum as undisclosed instead of interpreting that omission as no minimum.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'bootcamp' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz);

commit;
