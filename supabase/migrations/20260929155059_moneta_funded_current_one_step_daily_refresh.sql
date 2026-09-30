-- Refresh Moneta Funded's renamed/relaunched 1-Step Daily offer using its current product page.
-- Reviewed 2026-09-30; selector prices are still not treated as verified fees.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set name = 'Moneta Funded 1-Step Daily',
    slug = '1-step-daily',
    description = 'Single-phase Forex evaluation with a 3% target, 1% daily loss limit, 2% maximum loss, no minimum trading days, and daily 88% payouts once funded.',
    program_type = 'evaluation',
    account_sizes = '[]'::jsonb,
    max_leverage = null,
    profit_split_percent = 88,
    payout_frequency = 'Daily when profitable and eligible',
    minimum_trading_days = 0,
    news_allowed = null,
    weekend_holding_allowed = null,
    commercial_details = p.commercial_details || jsonb_build_object(
      'evaluation_rules', 'The current 1-Step Daily product page states a single 3% profit target, 1% daily loss limit, 2% maximum loss (calculation method not stated), no consistency rule, and no minimum trading days.',
      'funded_rules', 'The current page states an 88% share and daily payouts on profitable days once funded. Confirm any funded-stage loss limits and payout eligibility conditions in the applicable agreement.',
      'current_product_name', '1-Step Daily (marked NEW on the official challenge navigation)',
      'source_refresh_date', '2026-09-30',
      'account_size_price_note', 'The current official 1-Step Daily page does not expose its size matrix or leverage in the captured text. Do not carry the prior 1-Step Challenge values into the new offer.',
      'current_vs_legacy_note', 'The earlier staged 1-Step Challenge record (10% target, 3% daily loss, 6% maximum loss, 14-day payout) does not match the current official 1-Step Daily page. This row is renamed and corrected; do not present the older terms as the current offer.',
      'fee_refund_policy', 'Current public page has an interactive Challenge Builder. Exact base fees by size remain unverified; no price inferred.'
    ),
    status = 'in_review', published_at = null, archived_at = null, updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'moneta-funded' and p.slug = '1-step-challenge';

update bullish_banana.program_phases ph
set profit_target_percent = 3,
    daily_drawdown_percent = 1,
    maximum_drawdown_percent = 2,
    drawdown_type = null,
    time_limit_days = null,
    minimum_trading_days = 0,
    raw_rules = ph.raw_rules || jsonb_build_object(
      'official_product_name', '1-Step Daily',
      'current_rules_verified_on', '2026-09-30',
      'current_rule_summary', '3% target; 1% daily loss; 2% maximum loss (calculation method not stated); no consistency rule; no minimum trading days. Funded stage advertises daily payouts at 88%.',
      'legacy_rule_warning', 'Replaces the staged 10% target / 3% daily / 6% maximum-loss values from the prior 1-Step Challenge page.'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'moneta-funded' and p.slug = '1-step-daily' and ph.phase_number = 1;

update bullish_banana.sources s
set source_url = 'https://www.monetafunded.com/one-step-daily/',
    source_label = 'Moneta Funded 1-Step Daily — current offer',
    notes = 'Current official product page reviewed 2026-09-30. It names the 1-Step Daily offer and states a 3% target, 1% daily loss, 2% maximum loss, no consistency rule, no minimum days, and daily 88% payouts when profitable. Exact builder fees and additional funded-stage conditions remain unverified.',
    captured_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id and f.slug = 'moneta-funded' and p.slug = '1-step-daily'
  and s.source_url = 'https://www.monetafunded.com/one-step/';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://www.monetafunded.com/one-step-daily/', 'Moneta Funded 1-Step Daily — current offer', 'Current official product page reviewed 2026-09-30. It names the 1-Step Daily offer and states a 3% target, 1% daily loss, 2% maximum loss, no consistency rule, no minimum days, and daily 88% payouts when profitable. Exact builder fees and additional funded-stage conditions remain unverified.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'moneta-funded' and p.slug = '1-step-daily'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://www.monetafunded.com/one-step-daily/');

update bullish_banana.affiliate_destinations d
set destination_url = 'https://www.monetafunded.com/one-step-daily/',
    label = 'View Moneta Funded 1-Step Daily'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'moneta-funded' and p.slug = '1-step-daily';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Current official 1-Step Daily product page reviewed 2026-09-30. It materially replaces the prior 1-Step Challenge terms: current page states 3% target, 1% daily loss, 2% max loss, no consistency rule, no minimum days, and daily 88% payouts when profitable. Builder fees and funded-stage eligibility details remain open; record stays in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'moneta-funded' and p.slug = '1-step-daily';
