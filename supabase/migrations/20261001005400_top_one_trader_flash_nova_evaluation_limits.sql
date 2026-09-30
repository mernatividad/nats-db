begin;
set search_path = bullish_banana, extensions, public;

-- Official Top One Trader sources state FLASH and NOVA have no fixed evaluation deadline.
with offers(slug, source_note) as (
  values
    ('1-step-flash', 'Official FLASH rules state the trading period is unlimited; an inactivity rule still requires a trade at least once every 30 days.'),
    ('1-step-nova', 'Official NOVA overview states Time Limit: None and lists no minimum trading days for the evaluation phase.')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = case when o.slug = '1-step-nova' then 0 else ph.minimum_trading_days end,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'evaluation_time_limit', 'Unlimited; no fixed challenge deadline',
      'evaluation_time_limit_condition', case when o.slug = '1-step-flash'
        then 'A separate inactivity rule requires at least one trade every 30 days'
        else 'A separate inactivity rule applies after 30 consecutive inactive days'
      end,
      'evaluation_time_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and ph.phase_number = 1
  and f.slug = 'top-one-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

with offers(slug, source_url, source_label, notes) as (
  values
    ('1-step-flash', 'https://help.toponetrader.com/en/articles/8318230-what-are-the-rules-for-the-1-step-flash-challenge-account',
      'Top One Trader 1-Step FLASH rules — 2026-10-01',
      'Official Help Center rules article reviewed 2026-10-01. It states Trading Period: Unlimited and separately requires at least one trade every 30 days. The article also specifies three profitable trading days.'),
    ('1-step-nova', 'https://help.toponetrader.com/en/articles/13832165-nova-account-overview',
      'Top One Trader NOVA account overview — 2026-10-01',
      'Official Help Center overview reviewed 2026-10-01. Its rules table states Time Limit: None and the overview describes the NOVA evaluation as one phase with no minimum trading-day requirement.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url, o.source_label, o.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'top-one-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = o.source_label);

with offers(slug, note) as (
  values
    ('1-step-flash', 'Rechecked the official 1-Step FLASH rules on 2026-10-01: no fixed evaluation deadline; inactivity requires at least one trade every 30 days. The phase retains its official requirement of three profitable trading days.'),
    ('1-step-nova', 'Rechecked the official NOVA overview on 2026-10-01: no evaluation time limit, no minimum evaluation trading days, and a separate 30-day inactivity rule.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T01:21:27+09:00'::timestamptz, o.note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'top-one-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.note);

commit;
