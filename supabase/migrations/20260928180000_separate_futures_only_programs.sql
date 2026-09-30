-- Keep multi-market firms and their Forex offers visible while excluding Futures-only
-- programs from the Forex challenge directory. Identified from current catalog facts
-- and first-party E8/FundedNext market descriptions, reviewed 2026-09-28.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'futures' from bullish_banana.firms where slug = 'fundednext'
on conflict (firm_id, market_type) do nothing;

update bullish_banana.programs
set market_type = 'futures', updated_at = now()
where slug in ('e8-zero', 'futures-flex', 'futures-legacy', 'futures-rapid-daily', 'futures-rapid-pro');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join (values
  ('e8-zero', 'https://helpfutures.e8markets.com/en/articles/15935817-e8-zero-starter-and-max', 'E8 Zero Futures rules', 'E8 first-party help center explicitly identifies E8 Zero as a Futures product; used to keep this program out of the Forex challenge catalog.'),
  ('futures-flex', 'https://fundednext.com/futures', 'FundedNext Futures catalog', 'FundedNext first-party Futures catalog lists Flex as a Futures challenge.'),
  ('futures-legacy', 'https://fundednext.com/futures', 'FundedNext Futures catalog', 'FundedNext first-party Futures catalog lists Legacy as a Futures challenge.'),
  ('futures-rapid-daily', 'https://fundednext.com/futures', 'FundedNext Futures catalog', 'FundedNext first-party Futures catalog lists Rapid Daily as a Futures challenge.'),
  ('futures-rapid-pro', 'https://fundednext.com/futures', 'FundedNext Futures catalog', 'FundedNext first-party Futures catalog lists Rapid Pro as a Futures challenge.')
) as source(slug, url, label, notes) on source.slug = programs.slug
where not exists (
  select 1 from bullish_banana.sources existing
  where existing.program_id = programs.id and existing.source_url = source.url
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reclassified to Futures after checking current first-party product categorization on 2026-09-28.'
from bullish_banana.programs
where slug in ('e8-zero', 'futures-flex', 'futures-legacy', 'futures-rapid-daily', 'futures-rapid-pro');
