begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, source_url, name, note) as (
  values
    ('stellar-1-step','https://help.fundednext.com/en/articles/17252927-stellar-1-step-account','Stellar 1-Step','The current official Stellar 1-Step account article reviewed 2026-10-01 explicitly states there is no time limit to reach the 10% challenge target. It also lists the separate requirement of two minimum trading days.'),
    ('stellar-lite','https://help.fundednext.com/en/articles/9094074-how-many-days-will-i-get-to-complete-phases-1-2-of-the-stellar-lite-challenge','Stellar Lite','The current official Stellar Lite help article reviewed 2026-10-01 explicitly states there is no time limit to complete either evaluation phase. The five-day minimum trading requirement for each phase is recorded separately.')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'Unlimited; no fixed evaluation deadline',
      'time_limit_label', 'No time limit',
      'time_limit_unit', 'unlimited',
      'time_limit_note', o.note,
      'time_limit_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'fundednext'
  and p.market_type = 'forex' and p.status in ('published','in_review');

with offers(slug, source_url, name, note) as (
  values
    ('stellar-1-step','https://help.fundednext.com/en/articles/17252927-stellar-1-step-account','Stellar 1-Step','The current official Stellar 1-Step account article reviewed 2026-10-01 explicitly states there is no time limit to reach the 10% challenge target. It also lists the separate requirement of two minimum trading days.'),
    ('stellar-lite','https://help.fundednext.com/en/articles/9094074-how-many-days-will-i-get-to-complete-phases-1-2-of-the-stellar-lite-challenge','Stellar Lite','The current official Stellar Lite help article reviewed 2026-10-01 explicitly states there is no time limit to complete either evaluation phase. The five-day minimum trading requirement for each phase is recorded separately.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url, 'FundedNext ' || o.name || ' evaluation time limit — 2026-10-01', o.note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'fundednext' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = 'FundedNext ' || o.name || ' evaluation time limit — 2026-10-01');

with offers(slug, name, note) as (
  values
    ('stellar-1-step','Stellar 1-Step','Rechecked the current official FundedNext Stellar 1-Step account page on 2026-10-01. It specifies no challenge deadline; the two-day minimum trading requirement remains separately recorded.'),
    ('stellar-lite','Stellar Lite','Rechecked the current official FundedNext Stellar Lite deadline FAQ on 2026-10-01. It says no time limit applies to either challenge phase; each phase still requires five trading days.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T04:45:00+09:00'::timestamptz, o.note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'fundednext' and p.market_type = 'forex'
  and p.status in ('published','in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.note);

commit;
