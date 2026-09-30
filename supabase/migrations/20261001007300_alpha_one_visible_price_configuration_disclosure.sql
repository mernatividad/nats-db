begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set description = concat_ws(' ', nullif(trim(p.description), ''),
      'The exact fee depends on the selected target variant, account size, payout schedule, and optional add-ons; confirm the configured price in Alpha Capital’s live selector before purchase.'),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'price_status', 'Configuration-dependent; verify the selected offer in the live official checkout.',
      'price_verified_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'alpha-capital-group'
  and p.slug = 'alpha-one' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and p.description not ilike '%confirm the configured price in Alpha Capital%';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T12:30:00+09:00'::timestamptz,
  'The current Alpha One description explicitly discloses that the exact fee depends on target, size, payout schedule, and add-ons and directs users to confirm the live selector. This preserves the configurability instead of implying a single price.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'The current Alpha One description explicitly discloses%');

commit;
