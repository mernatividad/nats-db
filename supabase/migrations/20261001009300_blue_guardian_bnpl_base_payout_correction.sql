begin;
set search_path = bullish_banana, extensions, public;

-- The legacy challenge summary said 85%, which is not the current model-specific
-- base split. The current BNPL Help Center states 80% base and a 90% add-on.
update bullish_banana.programs p
set description = 'Blue Guardian Buy Now Pay Later: one-step Forex evaluation with a 4% profit target, 4% daily drawdown, 8% trailing maximum drawdown, and no evaluation minimum-day requirement. The funded account starts at an 80% profit split, with an optional 90% add-on; the remaining activation fee is due after passing.',
    profit_split_percent = 80,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'funded_rules', 'Current model-specific Help Center rules specify an 80% base profit split and an optional 90% profit-split upgrade at checkout. This replaces the stale 85% summary; the add-on price and selected checkout configuration must be confirmed before purchase.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later'
  and p.market_type = 'forex' and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.blueguardian.com/en/articles/15859899-buy-now-pay-later-bnpl-rules',
  'Blue Guardian BNPL base split and upgrade — 2026-10-01',
  'Current official BNPL rules state an 80% base profit split and optional 90% profit-split add-on. The model summary and structured base split were corrected to remove the stale 85% value.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_label = 'Blue Guardian BNPL base split and upgrade — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked current model-specific BNPL rules and corrected the stored funded profit split from stale 85% to the published 80% base, with optional 90% upgrade recorded separately.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz and v.notes like 'Rechecked current model-specific BNPL rules%');

commit;
