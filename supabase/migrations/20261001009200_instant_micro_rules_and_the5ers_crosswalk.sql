begin;
set search_path = bullish_banana, extensions, public;

-- The current official FAQ calls Hyper Growth “Instant Funding (Hyper-Growth)”.
-- Preserve the legacy row, but do not expose a second direct-funded product that
-- duplicates the existing Hyper Growth evaluation record.
update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_status', 'legacy duplicate; represented by the current Hyper Growth record',
      'archived_reason', 'Current The5ers sources identify Instant Funding as the Hyper-Growth program. The current product page describes Hyper Growth as a one-step evaluation with a 10% target; the separate legacy direct-funded/no-target description was unsupported and duplicated the existing Hyper Growth record.',
      'archived_reviewed_at', '2026-10-01',
      'current_product_slug', 'hyper-growth'
    )
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'the5ers' and p.slug = 'instant-funding'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'the5ers' and p.slug = 'instant-funding';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://the5ers.com/faqs/can-i-trade-during-news/',
  'The5ers current program naming crosswalk — 2026-10-01',
  'The current official FAQ labels this model “Instant Funding (Hyper-Growth)”; the live Hyper Growth page describes a one-step 10% evaluation. This supersedes the unsupported legacy standalone direct-funded/no-target record. The existing Hyper Growth catalog entry remains the current offer record.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'instant-funding' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://the5ers.com/faqs/can-i-trade-during-news/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://the5ers.com/en/hyper-growth/',
  'The5ers current Hyper Growth product and evaluation — 2026-10-01',
  'The current official product page presents Hyper Growth as a one-step model with a 10% evaluation target and identifies its platform and risk terms. It is the live catalog destination for the legacy Instant Funding (Hyper-Growth) naming.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'instant-funding' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://the5ers.com/en/hyper-growth/');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Reconciled current The5ers naming: official FAQ calls Hyper Growth “Instant Funding (Hyper-Growth)”, while the current product page states a one-step 10% evaluation. Archived the unsupported separate direct-funded/no-target duplicate and retained Hyper Growth as the current record.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'instant-funding' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz and v.notes like 'Reconciled current The5ers naming:%');

-- IF Micro PRO is described by current Instant Funding material as evolved
-- from IF Micro. Keep the program in review because the FAQ index and selector
-- use inconsistent archived/current labels and the model page cannot be opened
-- in this capture. Rules below are attributed to the current IF Micro article.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'direct_funding_note', 'Current official selector calls the product IF Micro PRO, “evolved from IF Micro”; the official Help Center model page calls IF Micro Pro previously known as IF Micro. The current official IF Micro rules article describes an immediate-access account with no profit target, 4% daily loss recalculated at 17:00 EST from the higher of balance or equity, 6% static maximum loss, and 1% maximum risk per trade idea. The general on-demand payout article sets a 15% best-day cap and minimum 5% net profit for IF Micro. The IF Micro article allows news, overnight and weekend holding, and describes size-dependent maximum lot rules. These are attributed to IF Micro lineage, not independently confirmed for every IF Micro PRO variation.',
  'platform_availability_note', 'Instant Funding’s current official platform article lists MT5, cTrader, and Match-Trader for global clients, with Match-Trader only for US clients; the reviewed current homepage selector presents all three platforms. ZAR accounts are MT5 only. Confirm region and account-currency availability at checkout.',
  'availability_conflict', 'The current selector and IF Micro model article describe IF Micro PRO as the evolved/current IF Micro product. A separate current Help Center comparison page labels IF Micro Pro “Archived”, while the main model article and selector list the product. Availability is unresolved; retain in review and confirm that the exact variation can be purchased before treating it as a current offer.',
  'verification_note', 'Rules are supported by current official IF Micro lineage pages, but the specific IF Micro PRO rules page could not be independently opened and current help-center indexing conflicts on availability. Do not publish as verified until the current variation and its model-specific terms are reconfirmed.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'instant-funding' and p.slug = 'if-micro-pro'
  and p.market_type = 'forex' and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://instantfunding.com/help/if-micro/',
  'Instant Funding IF Micro rules and payout conditions — 2026-10-01',
  'Official IF Micro rules page gives 4% daily loss, 6% static drawdown, 1% trade-idea risk, on-demand payout eligibility and trading conditions. Instant Funding help text says IF Micro Pro was previously known as IF Micro. The rules are attributed to the product lineage, with exact IF Micro PRO variation equivalence still under review.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug = 'if-micro-pro' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://instantfunding.com/help/if-micro/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://instantfunding.com/help/trading-platforms/',
  'Instant Funding current supported platforms — 2026-10-01',
  'Official platform help page says global users can use MT5, cTrader, and Match-Trader; US users can use Match-Trader only. It notes platform switching requires contacting support. Product/region selector eligibility should be confirmed at checkout.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug = 'if-micro-pro' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://instantfunding.com/help/trading-platforms/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://instantfunding.com/help/payout-on-demand/',
  'Instant Funding on-demand payout policy — 2026-10-01',
  'Current official payout guidance includes IF Micro among the on-demand models and states a 15% best-day cap and 5% net-profit threshold. This is used as IF Micro lineage evidence, not as proof that every IF Micro PRO variation has identical terms.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug = 'if-micro-pro' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://instantfunding.com/help/payout-on-demand/');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Added current official IF Micro lineage rules and global platform scope. IF Micro PRO exact variation mapping and purchase availability remain in review because one current Help Center index labels it archived while the selector and model page still list it.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug = 'if-micro-pro' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz and v.notes like 'Added current official IF Micro lineage rules%');

commit;
