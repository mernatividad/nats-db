begin;
set search_path = bullish_banana, extensions, public;

-- Current E8 first-party rules describe unlimited challenge time for the
-- Classic Markets Forex variants. Preserve the separate 60-day activity rule.
with offers(slug, source_url, source_label, notes) as (
  values
    ('e8-one-forex', 'https://help.e8markets.com/en/articles/11775980-e8-one', 'E8 One Forex rules — unlimited challenge time — 2026-10-01', 'Official E8 One rules reviewed 2026-10-01. Challenge has unlimited trading days (no time limit); trader must open and close at least one trade every 60 days. The 60-day activity requirement is not an evaluation deadline.'),
    ('e8-pro-forex', 'https://help.e8markets.com/en/articles/15274219-e8-pro', 'E8 Pro Forex rules — unlimited challenge time — 2026-10-01', 'Official E8 Pro rules reviewed 2026-10-01. Challenge has unlimited trading days (no time limit); trader must open and close at least one trade every 60 days. The 60-day activity requirement is not an evaluation deadline.'),
    ('e8-signature-forex', 'https://help.e8markets.com/en/articles/11755943-e8-signature-forex', 'E8 Signature Forex rules — unlimited challenge time — 2026-10-01', 'Official E8 Signature Forex rules reviewed 2026-10-01. Challenge has unlimited trading days (no time limit); trader must open and close at least one trade every 60 days. The 60-day activity requirement is not an evaluation deadline.')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    minimum_trading_days = coalesce(ph.minimum_trading_days, 0),
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'evaluation_time_limit', 'Unlimited; no fixed challenge deadline',
      'minimum_trading_days_label', 'No minimum trading-day count stated; at least one opened and closed trade every 60 days to keep the account active',
      'evaluation_time_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and f.slug = 'e8-markets'
  and p.status = 'published' and ph.phase_number = 1;

with offers(slug, source_url, source_label, notes) as (
  values
    ('e8-one-forex', 'https://help.e8markets.com/en/articles/11775980-e8-one', 'E8 One Forex rules — unlimited challenge time — 2026-10-01', 'Official E8 One rules reviewed 2026-10-01. Challenge has unlimited trading days (no time limit); trader must open and close at least one trade every 60 days. The 60-day activity requirement is not an evaluation deadline.'),
    ('e8-pro-forex', 'https://help.e8markets.com/en/articles/15274219-e8-pro', 'E8 Pro Forex rules — unlimited challenge time — 2026-10-01', 'Official E8 Pro rules reviewed 2026-10-01. Challenge has unlimited trading days (no time limit); trader must open and close at least one trade every 60 days. The 60-day activity requirement is not an evaluation deadline.'),
    ('e8-signature-forex', 'https://help.e8markets.com/en/articles/11755943-e8-signature-forex', 'E8 Signature Forex rules — unlimited challenge time — 2026-10-01', 'Official E8 Signature Forex rules reviewed 2026-10-01. Challenge has unlimited trading days (no time limit); trader must open and close at least one trade every 60 days. The 60-day activity requirement is not an evaluation deadline.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url, o.source_label, o.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'e8-markets' and p.status = 'published'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = o.source_label);

with offers(slug) as (values ('e8-one-forex'), ('e8-pro-forex'), ('e8-signature-forex'))
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T15:53:49Z'::timestamptz,
  'Rechecked current official E8 Forex challenge rules on 2026-10-01. The evaluation has no fixed time limit. The one-trade-per-60-days rule is an account activity condition, not a challenge deadline; phase time_limit_days is recorded as 0 and no minimum trading-day count as 0.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'e8-markets' and p.status = 'published'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes like 'Rechecked current official E8 Forex challenge rules on 2026-10-01.%');

commit;
