begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_unit', 'hours',
      'time_limit_label', 'Select 1, 2, 4, or 8 hours',
      'time_limit_note', 'The current official Sprint rules let the trader select a 1-, 2-, 4-, or 8-hour challenge duration. The countdown starts with the first trade and runs for the selected duration. This is a configurable intraday timer, not a number of calendar evaluation days.',
      'time_limit_options_hours', jsonb_build_array(1, 2, 4, 8),
      'time_limit_verified_at', '2026-10-01',
      'day_requirement_label', 'Minimum trading days not stated',
      'day_requirement_note', 'The current public Sprint rules specify a selected duration in hours and require reaching the configured target before the timer expires; they do not state a minimum number of trading days.',
      'day_requirement_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'moneta-funded'
  and p.slug = 'sprint-challenge' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.source_url, s.source_label, s.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join (values
  ('https://www.monetafunded.com/latest-news/introducing-the-moneta-funded-sprint-challenge/',
   'Moneta Funded Sprint selected-duration rules — 2026-10-01',
   'Current official product announcement states the trader selects a duration of 1, 2, 4, or 8 hours; the timer starts on the first trade and runs for the selected duration. Reviewed 2026-10-01.'),
  ('https://www.monetafunded.com/sprint-challenge/',
   'Moneta Funded Sprint challenge builder — 2026-10-01',
   'Current official Sprint builder presents a configurable time limit in hours and challenge target. Its public rules describe completion within the selected window but do not state a minimum trading-day count. Reviewed 2026-10-01.')
) as s(source_url, source_label, notes)
where f.slug = 'moneta-funded' and p.slug = 'sprint-challenge'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources old
    where old.program_id = p.id and old.source_label = s.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T11:00:00+09:00'::timestamptz,
  'Rechecked Moneta Funded’s current Sprint announcement and builder on 2026-10-01. Sprint has a trader-selected 1/2/4/8-hour duration beginning at first trade. The public sources specify no minimum trading-day count; this is disclosed as unstated, not as zero or unlimited.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'moneta-funded' and p.slug = 'sprint-challenge'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'Rechecked Moneta Funded’s current Sprint announcement and builder on 2026-10-01.%');

commit;
