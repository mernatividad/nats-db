begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, name) as (
  values ('3-step','3 Step'), ('pay-later','Pay Later')
)
update bullish_banana.program_phases ph
set minimum_trading_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_minimum_trading_days', true,
      'day_requirement_note', 'Goat Funded Trader states there is no minimum trading-day requirement during this model’s evaluation phases. Funded-stage reward-day requirements are separate.',
      'day_requirement_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'goat-funded-trader'
  and p.market_type = 'forex' and p.status in ('published','in_review');

with offers(slug, name) as (
  values ('3-step','3 Step'), ('pay-later','Pay Later')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://help.goatfundedtrader.com/en/articles/13860595-what-are-the-minimum-trading-days',
  'Goat Funded Trader evaluation day requirements — ' || o.name || ' — 2026-10-01',
  'Current official Goat Funded Trader Minimum Trading Days FAQ reviewed 2026-10-01 explicitly lists ' || o.name || ' as having no minimum trading-day requirement during evaluation. Funded-stage payout day requirements are listed separately.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'goat-funded-trader' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'Goat Funded Trader evaluation day requirements — ' || o.name || ' — 2026-10-01');

with offers(slug, name, note) as (
  values
    ('3-step','3 Step','Rechecked the official Goat Funded Trader minimum-day FAQ on 2026-10-01. It states no trading-day requirement for 3 Step evaluation; separate funded-stage days are required for payouts.'),
    ('pay-later','Pay Later','Rechecked the official Goat Funded Trader minimum-day FAQ on 2026-10-01. It states Pay Later has no minimum during evaluation and three qualifying trading days once funded.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T05:40:00+09:00'::timestamptz, o.note
from offers o
join bullish_banana.firms f on f.slug = 'goat-funded-trader'
join bullish_banana.programs p on p.firm_id = f.id and p.slug = o.slug
where p.market_type = 'forex' and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.note);

commit;
