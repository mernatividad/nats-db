begin;
set search_path = bullish_banana, extensions, public;

-- Record the latest first-party review of the two Blueberry offers still held
-- in review. Keep unresolved selector/model conflicts visible; do not publish.
with target_programs as (
  select p.id, p.slug
  from bullish_banana.programs p
  join bullish_banana.firms f on f.id = p.firm_id
  where f.slug = 'blueberry-funded'
    and p.slug in ('flex-one-step', 'instant-pro')
    and p.market_type = 'forex'
    and p.status = 'in_review'
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
  'https://help.blueberryfunded.com/en/articles/16390779-what-s-changing-on-17-august-2026',
  'Blueberry current offer lifecycle guidance — reviewed 2026-10-01',
  case p.slug
    when 'flex-one-step' then 'First-party lifecycle guidance describes Flex 1-Step as replacing the older 1-Step model. The current Flex rules page still caps documented sizes at $100K; the captured selector has a $200K variation whose applicability to Flex remains unresolved.'
    else 'First-party current lifecycle and Instant Help Center pages reviewed for model status. They document Instant Lite and Instant Elite but do not supply current Instant Pro model-specific rules; the older March 2026 outline does not resolve whether current variations retain those terms.'
  end
from target_programs p
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id
    and s.source_url = 'https://help.blueberryfunded.com/en/articles/16390779-what-s-changing-on-17-august-2026'
    and s.source_label = 'Blueberry current offer lifecycle guidance — reviewed 2026-10-01'
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T19:50:00+00:00'::timestamptz,
  case p.slug
    when 'flex-one-step' then 'Rechecked current first-party Flex 1-Step rules and the August offer lifecycle update on 2026-10-01. Core rules remain documented, but the official rules size range ends at $100K while the recorded Store API selector capture includes a $200K Flex variation. Kept in review pending a first-party explanation or model-specific rules for that size.'
    else 'Rechecked current first-party offer lifecycle and Instant help guidance on 2026-10-01. The detailed model-specific Instant Pro source remains the March 2026 outline; current Help Center guidance names Instant Lite and Instant Elite without providing current Instant Pro rules. Kept in review pending a current Instant Pro rule source and selector mapping.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blueberry-funded'
  and p.slug in ('flex-one-step', 'instant-pro')
  and p.market_type = 'forex'
  and p.status = 'in_review'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30T19:50:00+00:00'::timestamptz
      and v.notes like 'Rechecked current first-party offer lifecycle%'
  );

commit;

