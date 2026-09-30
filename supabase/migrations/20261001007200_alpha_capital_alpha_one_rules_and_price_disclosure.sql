begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', 'Alpha One daily loss is variant-specific: 3% during evaluation on the 6% target plan (4% on Qualified), 4% on the 10% target plan, and 5% on the 12% target plan. Daily loss uses the higher of end-of-day balance or equity.',
      'maximum_drawdown_rule', 'Alpha One maximum loss trails by selected target variant: 4% on the 6% plan, 6% on the 10% plan, and 8% on the 12% plan, measured from the high-water mark.',
      'drawdown_by_account_size', 'Targets 6%/10%/12% map to 4%/6%/8% trailing maximum loss and 3%/4%/5% evaluation daily loss respectively. The 6% target daily limit becomes 4% after qualification. Values vary by selected plan; do not merge into one fixed risk profile.',
      'source_note', 'Current official Alpha One product page and rules article reviewed 2026-10-01; the product offers selectable 6%, 10%, and 12% target variants with corresponding variant-specific drawdown limits.',
      'risk_rules_verified_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'alpha-capital-group'
  and p.slug = 'alpha-one' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

update bullish_banana.programs p
set payout_frequency = 'Bi-weekly or on-demand; select the schedule at purchase',
    profit_split_percent = coalesce(p.profit_split_percent, 80),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'challenge_rules', 'Alpha One is a one-phase evaluation on simulated funds. Select a 6%, 10%, or 12% target at purchase and complete at least one evaluation trading day. There is no maximum trading-day cap. FX leverage is up to 1:30; evaluation news trading and weekend holding are allowed. Drawdown limits vary by target variant and are detailed in the phase rules.',
      'trading_rules', 'One minimum trading day is required in evaluation. Evaluation news trading and weekend holding are allowed. On the Qualified Account, the stated five-minute news window applies to listed instruments. Daily and maximum drawdown are variant-specific; see phase rules.',
      'payout_rules', 'Performance fees can be requested bi-weekly or on-demand, according to the payout schedule selected at purchase. On-demand requests require at least 2% gross account profit and compliance with the 40% Best Day Rule. The standard performance split is 80%; an optional 90% split add-on is available at purchase. Eligible requests are processed within two business days; approval is not guaranteed.',
      'account_size_price_note', 'The current official checkout calculates the price after selecting the Alpha One target variant, account size, payout schedule, performance-split add-on, and swap-free option. There is no single fee for the unconfigured programme; confirm the exact base fee and add-ons in the live selector before purchase.',
      'pricing_note', 'Price depends on the selected target variant, account size, payout schedule, and optional add-ons. Current static page content does not provide one universally applicable Alpha One fee matrix; use the live official selector for the chosen configuration.',
      'alpha_one_variant_rules_verified_at', '2026-10-01',
      'alpha_one_price_configuration_verified_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'alpha-capital-group'
  and p.slug = 'alpha-one' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

with evidence(source_url, source_label, notes) as (
  values
    ('https://alphacapitalgroup.uk/product/alpha-one',
     'Alpha Capital Alpha One live plan and checkout selector — 2026-10-01',
     'Current official Alpha One product page reviewed 2026-10-01. It describes one simulated evaluation phase; selectable 6%, 10%, and 12% targets; variant-specific trailing drawdown; 1 minimum trading day; no maximum trading-day cap; 80% standard performance split; and a checkout selector where price depends on selected plan options.'),
    ('https://help.alphacapitalgroup.uk/en/articles/10097421-alpha-one-6-10-12',
     'Alpha Capital Alpha One evaluation risk rules — 2026-10-01',
     'Official Help Center article reviewed 2026-10-01. It lists Alpha One 6%: 4% trailing max drawdown and 3% daily loss in evaluation; 10%: 6% trailing and 4% daily; 12%: 8% trailing and 5% daily. Each evaluation variant requires one minimum trading day.'),
    ('https://help.alphacapitalgroup.uk/en/articles/10102634-on-demand-performance-fee',
     'Alpha Capital Alpha One on-demand payout terms — 2026-10-01',
     'Official Help Center article reviewed 2026-10-01. Alpha One on-demand requests require a minimum 2% gross account profit and the 40% Best Day Rule.'),
    ('https://help.alphacapitalgroup.uk/en/articles/6933755-how-do-i-get-paid-performance-fees',
     'Alpha Capital performance fee processing and payment methods — 2026-10-01',
     'Official Help Center article reviewed 2026-10-01. Performance fee requests are processed within two business days; payment methods and account review conditions are described in the article.')
)
insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, e.source_url, e.source_label, e.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join evidence e
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources old
    where old.program_id = p.id and old.source_label = e.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T12:00:00+09:00'::timestamptz,
  'Rechecked the current official Alpha One product page, Alpha One 6/10/12 rules article, on-demand performance fee article, and payout-processing article on 2026-10-01. Recorded variant-specific challenge and payout rules. Exact checkout fees are configuration-dependent and are disclosed as requiring the live selector; no static fee was inferred.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'alpha-capital-group' and p.slug = 'alpha-one'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like 'Rechecked the current official Alpha One product page%');

commit;
