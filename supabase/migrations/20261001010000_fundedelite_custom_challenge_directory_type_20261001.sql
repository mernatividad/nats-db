begin;
set search_path = bullish_banana, extensions, public;

alter table bullish_banana.programs
  drop constraint if exists programs_program_type_check;
alter table bullish_banana.programs
  add constraint programs_program_type_check
  check (program_type in ('evaluation', 'instant_funding', 'funded_account', 'custom_challenge', 'other'));

-- FundedElite advertises a Forex challenge builder with trader-selected rules.
-- Give it a challenge type so it appears in directories and comparisons while
-- keeping the specific terms explicitly variable and the offer in review.
update bullish_banana.programs p
set program_type = 'custom_challenge',
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_disclosure', 'Account size is selected in the builder; no fixed public size range is stated.',
      'challenge_rules', 'The builder lets the trader configure the profit target, maximum loss, payout schedule, leverage, and profit split. Drawdown may be static or trailing depending on the selected configuration; no fixed phase template is stated.',
      'price_configuration', 'Price varies with the selected configuration. The public product page does not state a default price; a completed checkout was not available for verification.',
      'platform_availability_note', 'Platform availability for the Custom Challenge selection is not stated on the public product page. Do not infer it from the firm-wide platform list.',
      'review_note', 'Custom challenge builder is listed on the official product page. Keep under review until representative completed configurations and checkout terms can be captured.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fundedelite'
  and p.market_type = 'forex'
  and p.slug = 'custom-challenge'
  and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://fundedelite.com/challenges/custom-challenge',
       'FundedElite Custom Challenge product page — reviewed 2026-10-01',
       'Official product page advertises a configurable Forex challenge builder. It describes user-selected target, maximum loss, payout schedule, leverage, profit split, and static or trailing drawdown. It does not state a fixed account size, price, platform, or phase template.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite'
  and p.market_type = 'forex'
  and p.slug = 'custom-challenge'
  and p.status = 'in_review'
  and not exists (
    select 1 from bullish_banana.sources existing
    where existing.program_id = p.id
      and existing.source_url = 'https://fundedelite.com/challenges/custom-challenge'
      and existing.source_label = 'FundedElite Custom Challenge product page — reviewed 2026-10-01'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30T20:32:00+00:00'::timestamptz,
       'Rechecked the official FundedElite Custom Challenge page on 2026-10-01. The page advertises a Forex challenge builder with user-selected target, maximum loss, payout schedule, leverage, profit split, and drawdown mode. Public fixed size, default price, platform, and phase template are not stated.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite'
  and p.market_type = 'forex'
  and p.slug = 'custom-challenge'
  and p.status = 'in_review'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.verified_at = '2026-09-30T20:32:00+00:00'::timestamptz
      and v.notes like 'Rechecked the official FundedElite Custom Challenge page%'
  );

commit;
