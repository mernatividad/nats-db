begin;
set search_path = bullish_banana, extensions, public;

-- Refresh gaps from current official provider material. All records with
-- unresolved offer/model mapping remain in_review; disclosure is not publication.

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'evaluation_rules', 'One-step BNPL evaluation. Official model rules state a 4% Phase 1 target, 4% daily loss calculated at the 5pm EST reset from the higher of balance or equity, and 8% trailing maximum loss from the highest watermark closing trade. No minimum days are required to pass; five qualifying trading days of at least 0.5% initial-balance profit apply only before funded payout requests. Challenge news trading is allowed; funded high-impact news execution is restricted ±5 minutes. Two-minute minimum holding rule; overnight/weekend holding and EAs allowed. Funded accounts have 20% consistency, Guardian Shield at 1% floating loss, and an 80% base split with an optional 90% add-on. The provider lists a $10 activation fee after passing; its current marketing page has conflicting $5/$10 setup copy, so confirm checkout amount. This update does not treat funded-only rules as evaluation rules.',
  'platforms', jsonb_build_array('MetaTrader 5', 'TradeLocker', 'Match-Trader'),
  'platform_availability_note', 'Current Blue Guardian BNPL page names Match Trader 5, TradeLocker, and Match-Trader. The linked checkout selector observed MT5 for a $100K BNPL configuration. Confirm the selected platform and account-size combination at checkout; the provider page has inconsistent platform naming.',
  'rules_source_conflict', 'Dedicated Help Center rules were updated 2026-09-30 and describe $10 activation; the current BNPL landing page includes both $5 and $10 setup claims. The $10 remaining activation fee is separately listed by size in the Help Center. Do not resolve the setup-fee discrepancy by inference.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later'
  and p.market_type = 'forex' and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.blueguardian.com/en/articles/15859899-buy-now-pay-later-bnpl-rules',
  'Blue Guardian BNPL current model-specific rules — 2026-10-01',
  'Official model-specific help article reports the one-step 4% target, 4% daily and 8% trailing loss limits, no evaluation minimum days, funded payout day conditions, trading restrictions, funded split, and activation fee schedule. Current landing page and help article differ on setup-fee copy; exact checkout fee must be confirmed.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://help.blueguardian.com/en/articles/15859899-buy-now-pay-later-bnpl-rules');

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'direct_funding_note', 'The March 2026 official Trading Evaluation Outline has a model-specific Instant Pro section (pages 19–20): immediate account access, no evaluation target, 6% daily loss, 10% maximum loss, trailing maximum-loss behavior, three minimum active trading days (0.5% initial-balance profit threshold), 1.5% maximum risk per trade idea, and 70% base profit share. No maximum trading duration is stated in that document. The current store capture exposes purchasable MT5 variations. The rules document predates the current store capture; payout eligibility and any later rule changes are not verified. Keep in review.',
  'platform_availability_note', 'Current Blueberry Funded Store API variation capture (2026-09-30) showed MT5 for this program’s selectable variations. The complete current platform matrix and any later changes are not verified; confirm at checkout.',
  'verification_note', 'The most detailed official model-specific rules source found is the March 2026 Trading Evaluation Outline. It is older than the current purchase-selector capture; recheck current Terms/Help Center for later amendments before publishing this offer as verified.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'blueberry-funded' and p.slug = 'instant-pro'
  and p.market_type = 'forex' and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://blueberryfunded.com/wp-content/uploads/2026/03/BBF-Trading-Evaluation-Outline-and-Fees.pdf',
  'Blueberry Funded Instant Pro official rules outline — March 2026',
  'Pages 19–20 contain the model-specific Instant Pro rules. This is the latest detailed official rules document found in this review; it predates the current store variation capture, so later amendments remain possible.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'blueberry-funded' and p.slug = 'instant-pro' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://blueberryfunded.com/wp-content/uploads/2026/03/BBF-Trading-Evaluation-Outline-and-Fees.pdf');

-- Leveraged confirms MT5 and cTrader firm-wide, with choices depending on the
-- checkout offer. Do not infer that every portfolio model has both selectable.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'platforms', jsonb_build_array('MetaTrader 5', 'cTrader'),
  'platform_availability_note', 'Leveraged’s official platform FAQ confirms MT5 and cTrader are supported, and says the available option depends on the offer selected at purchase. No portfolio-manager-specific selector mapping was captured; verify platform eligibility in the live checkout.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'leveraged'
  and p.slug in ('exec-portfolio-manager', 'jr-portfolio-manager', 'sr-portfolio-manager', 'leveraged-one')
  and p.market_type = 'forex' and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://getleveraged.com/faq/what-trading-platforms-does-leveraged-support/',
  'Leveraged official platform availability — 2026-10-01',
  'The official FAQ confirms MT5 and cTrader support and states the option depends on the selected offer. It does not map each portfolio-manager product to a platform; check its live checkout.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'leveraged' and p.slug in ('exec-portfolio-manager', 'jr-portfolio-manager', 'sr-portfolio-manager', 'leveraged-one')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://getleveraged.com/faq/what-trading-platforms-does-leveraged-support/');

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'price_capture_note', 'The current official selector capture lists the $200,000 account size for 2-Step Pro Model but no corresponding fee. Fees for the other observed sizes are recorded separately. No $200K fee or discount has been inferred; confirm in the live official selector.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fundingpips' and p.slug = '2-step-pro-model'
  and p.market_type = 'forex' and p.status = 'in_review';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'price_capture_note', 'The captured official Leveraged ONE selector showed a $100,000 MT5 configuration at $188. Other sizes currently listed on this record do not have verified size-specific fees; platform/size availability and pricing must be checked in the live selector.',
  'platform_availability_note', 'Leveraged’s official FAQ confirms MT5 and cTrader support, with the choice depending on offer selected. The captured $100,000 Leveraged ONE configuration used MT5; availability by other account sizes has not been mapped.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'leveraged' and p.slug = 'leveraged-one'
  and p.market_type = 'forex' and p.status = 'in_review';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'platform_availability_note', 'The reviewed current official English Forex rules and comparison do not expose a Prime X-specific platform mapping. Other Hola Prime offers have selector-specific platform differences; do not inherit another model’s platform. Confirm Prime X in an official live checkout before purchase.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'hola-prime' and p.slug = '2-step-prime-x'
  and p.market_type = 'forex' and p.status = 'in_review';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'evaluation_rules', 'The current official Top One Trader checkout identifies the generic 2-Step offer and lists a 4% daily loss limit, 8% static maximum loss, and unlimited evaluation time. The checkout does not publish phase profit targets or a minimum evaluation-day requirement. Do not substitute the separate Amped or PRO V2 targets for this offer.',
  'payout_rules', 'The captured official checkout does not publish this generic 2-Step offer’s funded profit split, payout interval, payout eligibility conditions, or fee refund terms. Those terms remain unverified; confirm the applicable trader agreement before purchase.',
  'verification_note', 'The current checkout capture exposes a generic 2-Step offer distinct from 2-Step Amped and 2-Step PRO V2. It does not expose phase targets or funded payout terms. Keep in review until those model-specific terms are verified.'
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'top-one-trader' and p.slug = '2-step-standard'
  and p.market_type = 'forex' and p.status = 'in_review';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://checkout.toponetrader.com/product/top-one-trader-challenges/',
  'Top One Trader generic 2-Step current official checkout — 2026-10-01',
  'The current checkout selector distinguishes the generic 2-Step offer and shows its current account/platform options. The captured checkout states 4% daily loss, 8% static maximum loss, and unlimited time, but does not publish phase targets, an evaluation minimum-day requirement, or funded payout terms.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'top-one-trader' and p.slug = '2-step-standard' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://checkout.toponetrader.com/product/top-one-trader-challenges/');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Reviewed current official firm materials for model rules/platform/pricing and refreshed explicit unknowns. In-review records remain unpublished recommendations where sources conflict, the offer-specific selector is incomplete, or current terms are not fully verified.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where p.market_type = 'forex' and p.status = 'in_review' and (
  (f.slug = 'blue-guardian' and p.slug = 'buy-now-pay-later')
  or (f.slug = 'blueberry-funded' and p.slug = 'instant-pro')
  or (f.slug = 'leveraged' and p.slug in ('exec-portfolio-manager', 'jr-portfolio-manager', 'sr-portfolio-manager', 'leveraged-one'))
  or (f.slug = 'fundingpips' and p.slug = '2-step-pro-model')
  or (f.slug = 'hola-prime' and p.slug = '2-step-prime-x')
  or (f.slug = 'top-one-trader' and p.slug = '2-step-standard')
);

commit;
