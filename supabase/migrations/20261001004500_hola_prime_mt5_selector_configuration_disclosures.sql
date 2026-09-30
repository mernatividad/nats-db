begin;
set search_path = bullish_banana, extensions, public;

with offers(slug, source_url, model_label) as (
  values
    ('2-step-pro', 'https://holaprime.com/forex/pro-challenge/', '2-Step Pro'),
    ('1-step-prime', 'https://holaprime.com/forex/prime-challenge/', '1-Step Prime'),
    ('2-step-prime', 'https://holaprime.com/forex/prime-challenge/', '2-Step Prime'),
    ('direct-forex', 'https://holaprime.com/forex/direct-account/', 'Direct Forex')
)
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platforms', jsonb_build_array('MetaTrader 5'),
      'platforms_note', 'The recorded official price matrix was captured with MetaTrader 5 selected. This confirms the platform for that observed configuration only; availability and pricing may differ for other platform or payout selections.',
      'platform_scope_reviewed_at', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f, offers o
where p.firm_id = f.id and f.slug = 'hola-prime' and p.slug = o.slug
  and exists (select 1 from jsonb_array_elements(coalesce(p.commercial_details->'account_size_prices','[]'::jsonb)) price
    where price->>'price_context' like '%MT5%');

with offers(slug, source_url, model_label) as (
  values
    ('2-step-pro', 'https://holaprime.com/forex/pro-challenge/', '2-Step Pro'),
    ('1-step-prime', 'https://holaprime.com/forex/prime-challenge/', '1-Step Prime'),
    ('2-step-prime', 'https://holaprime.com/forex/prime-challenge/', '2-Step Prime'),
    ('direct-forex', 'https://holaprime.com/forex/direct-account/', 'Direct Forex')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, o.source_url, 'Hola Prime MT5 selector configuration — ' || p.name || ' — 2026-09-30',
  'The recorded size/price matrix was observed with MT5 selected in the official model selector. This source supports the specific captured configuration; it does not establish that MT5 is the only platform or that the same prices apply to other platform and payout selections.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'hola-prime'
  and exists (select 1 from jsonb_array_elements(coalesce(p.commercial_details->'account_size_prices','[]'::jsonb)) price
    where price->>'price_context' like '%MT5%')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'Hola Prime MT5 selector configuration — ' || p.name || ' — 2026-09-30');

with offers(slug, source_url, model_label) as (
  values
    ('2-step-pro', 'https://holaprime.com/forex/pro-challenge/', '2-Step Pro'),
    ('1-step-prime', 'https://holaprime.com/forex/prime-challenge/', '1-Step Prime'),
    ('2-step-prime', 'https://holaprime.com/forex/prime-challenge/', '2-Step Prime'),
    ('direct-forex', 'https://holaprime.com/forex/direct-account/', 'Direct Forex')
)
insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T16:00:00Z'::timestamptz,
  'Rechecked the current official model selector capture. The stored fee matrix explicitly records MetaTrader 5 as the selected platform for this configuration. No claim is made about unobserved platform choices.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join offers o on o.slug = p.slug
where f.slug = 'hola-prime'
  and exists (select 1 from jsonb_array_elements(coalesce(p.commercial_details->'account_size_prices','[]'::jsonb)) price
    where price->>'price_context' like '%MT5%')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id
    and v.verified_at = '2026-09-30T16:00:00Z'::timestamptz);

commit;
