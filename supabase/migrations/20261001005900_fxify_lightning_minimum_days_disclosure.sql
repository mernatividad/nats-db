begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'day_requirement_note', 'The official Lightning FAQ and product page do not state a separate minimum number of trading days. The five-trading-day figure is the maximum completion window, not a stated minimum.',
  'day_requirement_verified_at', '2026-10-01'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fxify'
  and p.slug = 'lightning-challenge' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.source_url, s.source_label, s.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://fxify.com/faqs/all-faqs/lightning-plan/lightning-plan-what-is-the-lightning-plan/',
   'FXIFY Lightning minimum trading days disclosure — product FAQ — 2026-10-01',
   'Reviewed official Lightning plan FAQ on 2026-10-01. It states the five-trading-day completion window and does not state a separate minimum trading-day count.'),
  ('https://fxify.com/faqs/all-faqs/lightning-plan/lightning-plan-what-happens-if-i-do-not-hit-the-profit-target-in-7-days/',
   'FXIFY Lightning minimum trading days disclosure — target FAQ — 2026-10-01',
   'Reviewed official FAQ content on 2026-10-01. It describes the five-trading-day maximum/hard-breach rule; it does not state a separate minimum trading-day count.')
) as s(source_url, source_label, notes)
where f.slug = 'fxify' and p.firm_id = f.id
  and p.slug = 'lightning-challenge' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources x
    where x.program_id = p.id and x.source_label = s.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T02:00:00+09:00'::timestamptz,
  'Reviewed the official FXIFY Lightning product and FAQ on 2026-10-01. No separate minimum trading-day count is stated; preserved as unknown and disclosed. Five trading days is the maximum completion window.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'lightning-challenge'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = 'Reviewed the official FXIFY Lightning product and FAQ on 2026-10-01. No separate minimum trading-day count is stated; preserved as unknown and disclosed. Five trading days is the maximum completion window.');

commit;
