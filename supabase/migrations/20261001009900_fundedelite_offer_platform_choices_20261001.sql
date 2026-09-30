begin;
set search_path = bullish_banana, extensions, public;

-- First-party challenge FAQs explicitly list the selectable platforms for six
-- FundedElite Forex offers. Keep Catalyst, Flash Activation, and Custom
-- Challenge unmapped because their current pages do not identify platforms.
insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join bullish_banana.platforms pl on pl.slug in ('metatrader-5', 'tradelocker')
where f.slug = 'fundedelite'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug in (
    '1-step-free-retry', '2-step-free-retry', 'lite-1-step', 'lite-2-step',
    'instant-funding', 'instant-elite'
  )
on conflict do nothing;

with target_programs as (
  select p.id, p.slug
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'fundedelite'
    and p.market_type = 'forex'
    and p.status = 'in_review'
    and p.slug in (
      '1-step-free-retry', '2-step-free-retry', 'lite-1-step', 'lite-2-step',
      'instant-funding', 'instant-elite'
    )
),
source_map as (
  select * from (values
    ('1-step-free-retry', 'https://faq.fundedelite.com/en/articles/12683556-1-step-challenge-free-retry', 'FundedElite 1-Step + Free Retry platform options'),
    ('2-step-free-retry', 'https://faq.fundedelite.com/en/articles/12683226-2-step-challenge-free-retry', 'FundedElite 2-Step + Free Retry platform options'),
    ('lite-1-step', 'https://faq.fundedelite.com/en/articles/12683734-lite-1-step-challenge', 'FundedElite Lite 1-Step platform options'),
    ('lite-2-step', 'https://faq.fundedelite.com/en/articles/12683646-lite-2-step-challenge', 'FundedElite Lite 2-Step platform options'),
    ('instant-funding', 'https://faq.fundedelite.com/en/articles/12683783-instant-challenge', 'FundedElite Instant Standard platform options'),
    ('instant-elite', 'https://faq.fundedelite.com/en/articles/12683783-instant-challenge', 'FundedElite Instant Elite platform options')
  ) as sources(program_slug, source_url, source_label)
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, s.source_url,
  s.source_label || ' — reviewed 2026-10-01',
  'The official offer-specific FAQ states that traders may choose MetaTrader 5 or TradeLocker. It separately links leverage options to FX pairs and identifies platform-specific restricted countries; access is subject to the provider''s regional eligibility rules.'
from target_programs p
join source_map s on s.program_slug = p.slug
where not exists (
  select 1 from bullish_banana.sources existing
  where existing.program_id = p.id
    and existing.source_url = s.source_url
    and existing.source_label = s.source_label || ' — reviewed 2026-10-01'
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T20:15:00+00:00'::timestamptz,
  'Rechecked the current offer-specific FundedElite FAQ on 2026-10-01. It explicitly lists MetaTrader 5 and TradeLocker as selectable platforms for this offer. Platform access remains subject to the official restricted-country policy; this verification does not infer eligibility for a particular country.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug in (
    '1-step-free-retry', '2-step-free-retry', 'lite-1-step', 'lite-2-step',
    'instant-funding', 'instant-elite'
  )
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30T20:15:00+00:00'::timestamptz
      and v.notes like 'Rechecked the current offer-specific FundedElite FAQ%'
  );

update bullish_banana.programs p
set commercial_details = jsonb_set(
      p.commercial_details,
      '{platform_availability_note}',
      to_jsonb('The offer-specific FAQ lists MetaTrader 5 and TradeLocker as selectable options. Platform access is restricted in certain countries; verify the current official restricted-country policy for the trader’s jurisdiction.'::text),
      true
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fundedelite'
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and p.slug in (
    '1-step-free-retry', '2-step-free-retry', 'lite-1-step', 'lite-2-step',
    'instant-funding', 'instant-elite'
  );

commit;
