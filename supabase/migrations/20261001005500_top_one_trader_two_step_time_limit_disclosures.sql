begin;
set search_path = bullish_banana, extensions, public;

-- The current official checkout guide explicitly lists unlimited time for the
-- Two-Step Challenge and 2-Step Plus Challenge. The Two-Step target/drawdown
-- terms match the Help Center's PRO V2 model; do not apply this to the generic
-- selector record or the separate AMPED offer.
with offers(slug, phase_number, mapping_note) as (
  values
    ('2-step-pro-v2', 1, 'The official checkout guide labels this Two-Step Challenge; its 8%/5% targets and static drawdown align with the current PRO V2 Help Center model.'),
    ('2-step-pro-v2', 2, 'The official checkout guide labels this Two-Step Challenge; its 8%/5% targets and static drawdown align with the current PRO V2 Help Center model.'),
    ('2-step-plus', 1, 'Official checkout guide explicitly labels the 2-Step Plus Challenge.'),
    ('2-step-plus', 2, 'Official checkout guide explicitly labels the 2-Step Plus Challenge.')
)
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'evaluation_time_limit', 'Unlimited; no fixed challenge deadline',
      'evaluation_time_verified_at', '2026-10-01',
      'evaluation_time_source_scope', o.mapping_note
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where ph.program_id = p.id and ph.phase_number = o.phase_number
  and f.slug = 'top-one-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

with offers(slug, note) as (
  values
    ('2-step-pro-v2', 'The official checkout guide labels the current Two-Step Challenge time limit as Unlimited. Its 8%/5% targets and static drawdown correspond to the Help Center PRO V2 model, which applies to accounts purchased after May 18. The generic 2 Step selector and separate AMPED offer were not mapped from this page.'),
    ('2-step-plus', 'The official checkout guide labels the 2-Step Plus Challenge time limit as Unlimited. This rule evidence is recorded separately from the conflicting Help Center discontinued label; the program remains in review.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://checkout.toponetrader.com/how-it-works/',
  case when p.slug = '2-step-pro-v2'
    then 'Top One Trader checkout Two-Step Challenge rules — 2026-10-01'
    else 'Top One Trader checkout 2-Step Plus Challenge rules — 2026-10-01'
  end,
  o.note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'top-one-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = case when p.slug = '2-step-pro-v2'
      then 'Top One Trader checkout Two-Step Challenge rules — 2026-10-01'
      else 'Top One Trader checkout 2-Step Plus Challenge rules — 2026-10-01'
    end);

with offers(slug, note) as (
  values
    ('2-step-pro-v2', 'Rechecked Top One Trader official checkout How It Works page on 2026-10-01. It states unlimited time for its Two-Step Challenge. Phase targets and static drawdown align with the official PRO V2 rules; no generic-selector or AMPED mapping is inferred.'),
    ('2-step-plus', 'Rechecked Top One Trader official checkout How It Works page on 2026-10-01. It states unlimited time for the 2-Step Plus Challenge. The Help Center discontinued label conflicts with checkout availability, so the offer remains in review.')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T01:24:22+09:00'::timestamptz, o.note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'top-one-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.notes = o.note);

commit;
