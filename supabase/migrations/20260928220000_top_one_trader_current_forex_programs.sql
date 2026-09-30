-- Add Top One Trader's current Forex account families from first-party sources.
-- Reviewed 2026-09-28. Product availability, rule variants, and fees still need
-- checkout confirmation, so every program remains in review.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'Top One Trader', 'top-one-trader',
  'Top One Trader offers simulated Forex evaluation and instant-funding account models with distinct risk rules, payout terms, and platform options.',
  'https://www.toponetrader.com/', 'published', now()
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description,
    website_url = excluded.website_url, status = 'published',
    published_at = coalesce(bullish_banana.firms.published_at, now()), updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'top-one-trader'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, legal_entity_name, supported_assets, profile_details)
select id, 'Top One Trader, LLC', array['Forex', 'Indices', 'Commodities', 'Cryptocurrencies']::text[],
  '{"service_model":"Simulated trading challenges and simulated funded accounts; no live trading is provided directly by the company.","platform_options":["Match-Trader","TradeLocker","MetaTrader 5"],"platform_notes":"Platform availability varies by account size and location. MT5 is unavailable to traders in the United States, Canada, U.S. Outlying Territories, or Puerto Rico. The official help center says cTrader is restricted for U.S. traders; cTrader was not added as a platform because the current account comparison lists Match-Trader, TradeLocker, and MT5.","asset_notes":"Official account rules list Forex, indices, commodities/metals, and crypto; stocks are not available for these accounts.","availability_note":"Official account comparison lists six account families. 2-Step PLUS is listed there, but its own Help Center collection is labeled discontinued. Checkout availability must be confirmed before publication."}'::jsonb
from bullish_banana.firms where slug = 'top-one-trader'
on conflict (firm_id) do update
set legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select firms.id, item.name, item.slug, item.description, item.program_type, 'in_review', 'USD', item.account_sizes::jsonb,
  item.max_leverage, item.profit_split_percent, item.payout_frequency, item.minimum_trading_days,
  item.news_allowed, item.weekend_holding_allowed, item.commercial_details::jsonb, null
from bullish_banana.firms
join (values
  ('Top One Trader 1-Step FLASH', '1-step-flash', 'evaluation', 'Single-step Forex evaluation with a 10% target, 4% daily loss limit, 7% trailing maximum loss, and three qualifying profitable days.', '[]', 10::numeric, 80::numeric, 'First payout 14 days after funded-account activation; then every 14 days', 3::integer, true, true, '{"account_size_prices":[],"account_size_price_note":"Current account-size fee matrix was not captured from the official checkout. The challenge fee is non-refundable; confirm size, base fee, and add-ons in checkout.","payout_rules":"Standard profit share is 80%; a 90% share is an add-on. Minimum payout is 2% of initial balance. Monthly payout cap is $25,000. A weekly payout add-on is available after the first payout.","consistency_rule":"No consistency rule listed in the current official account comparison.","funded_rules":"Funded maximum daily profit is 3% per trading day. News trading is restricted within five minutes before/after high-impact events on funded accounts; challenge-stage news trading is allowed.","prohibited_strategies":"Unique personal EAs are allowed during evaluation only. Stop loss is required unless removed by add-on. Consult current full rules for other prohibited strategies.","commission_details":"Not stated in the reviewed current official account rules.","time_limit":"Unlimited evaluation duration; a trade is required at least once every 30 days.","source_note":"Official comparison reports 7% drawdown trailing and locking at starting balance after payout or 7% growth. The dedicated FLASH rules page gives the same loss limits and confirms 10:1 Forex leverage."}'),
  ('Top One Trader 1-Step NOVA', '1-step-nova', 'evaluation', 'Single-step pay-after-you-pass Forex evaluation with a 5% target, 6% trailing evaluation drawdown, and a $7 entry fee followed by a size-dependent activation fee.', '[25000,50000,100000,200000]', 100::numeric, 90::numeric, 'First payout 14 days after funded-account activation; weekly add-on available', null::integer, null::boolean, true, '{"account_size_prices":[],"account_size_price_note":"Official NOVA page states a $7 initial challenge fee and a separate one-time activation payment after passing. It lists activation fees of $165/$275/$550/$880 for $25K/$50K/$100K/$200K; these are not ordinary upfront challenge fees. Confirm the current checkout basket before publication.","payout_rules":"Funded profit share is 90%, with a 100% upgrade. A 20% Equity Stability Score applies. Minimum payout is 2% of initial balance; $25,000 monthly payout maximum is shown in the official comparison. Weekly payout add-on is available.","consistency_rule":"No evaluation consistency rule. A 20% funded ESS requirement applies.","risk_limits":"Current NOVA overview says no evaluation daily loss limit; evaluation drawdown is 6% trailing and locks at initial balance. Funded stage has 3% daily loss and 5% trailing drawdown, also under Lock Upon Payout.","prohibited_strategies":"Own unique EA allowed in evaluation; EAs and connected bots are not allowed in funded stage. Stop loss is required unless removed by add-on. Inactivity rule is 30 days.","commission_details":"Not stated in the reviewed current NOVA overview.","time_limit":"No evaluation deadline. Passing traders have 30 days to pay the activation fee. Accounts are subject to a 30-day inactivity rule.","source_conflict":"The general account comparison has a malformed split entry (90/20 standard, up to 100/10 add-on); the current NOVA overview states a 90% base share and optional 100%. This record uses the detailed NOVA page. The comparison says no minimum evaluation days."}'),
  ('Top One Trader 2-Step PLUS', '2-step-plus', 'evaluation', 'Two-phase Forex evaluation with 10% then 5% profit targets, five qualifying days per phase, and static drawdown rules; current purchase availability is unclear.', '[]', 30::numeric, 80::numeric, 'Biweekly; on-demand add-on listed', 5::integer, true, true, '{"account_size_prices":[],"account_size_price_note":"Current official checkout fee schedule and size options were not captured. Challenge fee refund is non-refundable for purchases after 5 February 2026.","payout_rules":"Base funded profit share is 80%, with 90% add-on. Biweekly payout schedule; on-demand add-on listed. Minimum payout 2%; funded daily-profit soft limit 5%.","consistency_rule":"No consistency rule listed.","risk_limits":"The dedicated overview says 8% standard static maximum drawdown, with a limited launch promotion at 10%; the comparison table lists 10%. The applicable current purchase value must be verified. Daily drawdown is 4%.","prohibited_strategies":"News allowed during evaluation and disallowed when funded. EAs allowed during evaluation only. Four soft breaches listed; 30-day inactivity limit.","commission_details":"$2.50 per side listed in the dedicated account overview.","time_limit":"Unlimited evaluation duration; 30-day inactivity limit.","availability_conflict":"The current comparison table lists 2-Step PLUS, but its official Help Center collection is titled 2-Step-PLUS Accounts (Discontinued). Keep in review until checkout confirms it is purchasable."}'),
  ('Top One Trader 2-Step PRO V2', '2-step-pro-v2', 'evaluation', 'Two-phase Forex evaluation with 8% then 5% targets, 4% daily loss, 9% static maximum loss, and three qualifying days per phase.', '[5000,10000,25000,50000,100000,150000,300000]', 100::numeric, 85::numeric, 'Biweekly; weekly payout add-on available', 3::integer, true, true, '{"account_size_prices":[],"account_size_price_note":"Current official checkout fees by account size were not captured; verify base prices and any selected add-ons in checkout.","payout_rules":"Base funded profit share is 85%, with up to 100% via add-on. Payouts are biweekly or weekly with add-on. Minimum payout is 3%. Per-cycle cap is 6% of initial balance or $15,000. Evaluation fee is refunded on fourth payout.","consistency_rule":"No consistency rule listed.","funded_rules":"Funded Forex leverage is 50:1 (evaluation 100:1). Max daily profit is $3,000 below $300K and $4,000 on $300K accounts. Eight soft breaches; maximum allocation $600K and scaling potential up to $2M.","prohibited_strategies":"Dedicated overview says news trading is allowed during evaluation and disallowed when funded; weekend holding is allowed. Own unique EAs are allowed in evaluation only. 5-minute minimum trade duration applies.","commission_details":"Not stated in the reviewed current official overview.","time_limit":"No evaluation time limit is listed.","source_conflict":"The July 24, 2026 comparison page reports 9% static max drawdown and three qualifying days per phase; the dedicated overview says news allowed in evaluation and not funded. This record follows the dedicated overview for stage-specific rules."}'),
  ('Top One Trader Instant Funding', 'instant-funding', 'instant_funding', 'Immediate simulated Forex funding with no evaluation, 3% daily loss, 6% trailing maximum loss, and a 15% consistency threshold.', '[]', 50::numeric, 60::numeric, 'First payout 30 days after account activation; an instant-payout add-on may be available', null::integer, false, false, '{"account_size_prices":[],"account_size_price_note":"Current official checkout prices and sizes were not captured; verify available options and fees before publication.","payout_rules":"Initial profit share is 60%, increasing by 10 percentage points per payout to 90%. The account comparison lists 30 days until the first payout and $25,000 monthly payout maximum. Minimum payout is 2% of initial balance.","consistency_rule":"15% consistency threshold. A historical 20% rule applies only to $5K-$100K accounts purchased before 24 September 2025.","risk_limits":"3% daily loss and 6% trailing maximum loss; trailing drawdown locks at initial balance after a payout or growth above 6%.","prohibited_strategies":"Weekend holding is prohibited unless the add-on is purchased. EAs are not allowed. Stop loss is required unless removed with add-on. 10 soft breaches and 30-day inactivity rule. Forex leverage 50:1.","commission_details":"Not stated in the reviewed current official rules.","time_limit":"No evaluation period; inactivity breach applies after 30 days without a trade.","source_note":"Dedicated Instant Funding rules are dated April 1, 2026 and confirm no evaluation, account restrictions, and 50:1 FX leverage."}'),
  ('Top One Trader Instant PRIME', 'instant-prime', 'instant_funding', 'Immediate simulated Forex funding with 2.5% daily loss, 5% trailing maximum loss, and a 20% Equity Stability Score requirement.', '[]', 50::numeric, 80::numeric, 'First payout after 14 days; then every 14 days', null::integer, false, false, '{"account_size_prices":[],"account_size_price_note":"Current official checkout prices and account sizes were not captured; verify available options, add-ons, and fees before publication.","payout_rules":"Profit share steps from 80% at first payout to 90% at second and 100% from third payout; 100% from first payout is an add-on. Minimum payout is 2%. Monthly maximum is $25,000. A 20% ESS is required.","consistency_rule":"No traditional consistency rule; 20% ESS is required before payout.","risk_limits":"For accounts purchased on/after 25 October 2025, daily hard loss is 2.5%; older accounts used a soft daily pause. Trailing max loss is 5% and locks at starting balance after payout or growth above 5%.","prohibited_strategies":"News and weekend holding are restricted unless corresponding add-ons are selected. EAs are not allowed. Five soft breaches, 30-day inactivity limit. Standard Forex leverage 50:1; 100:1 add-on unavailable on TradeLocker.","commission_details":"Not stated in the reviewed current official overview.","time_limit":"No evaluation period; inactivity breach applies after 30 days without a trade."}')
) as item(name, slug, program_type, description, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details) on true
where firms.slug = 'top-one-trader'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = 'in_review', currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, published_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, fee, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, null, phase.target, phase.daily_loss,
  phase.max_loss, phase.drawdown_type, null, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'top-one-trader'
join (values
  ('1-step-flash',1,'Evaluation',10.000::numeric,4.000::numeric,7.000::numeric,'trailing',3::integer,'{"qualifying_day_profit_percent":0.5,"source_note":"Official FLASH rules: 10% target, 4% daily hard loss, 7% trailing hard loss, at least three profitable days, each at 0.5% of initial balance. Unlimited duration."}'),
  ('1-step-nova',1,'Evaluation',5.000::numeric,null::numeric,6.000::numeric,'trailing',null::integer,'{"drawdown_lock":"Locks at initial balance after 6% gain","entry_fee_usd":7,"activation_fees_by_size_usd":{"25000":165,"50000":275,"100000":550,"200000":880},"source_note":"Current dedicated NOVA overview says $7 one-time entry and activation charge after passing; 5% target and 6% trailing max loss. Activation fee is not treated as challenge-phase fee."}'),
  ('2-step-plus',1,'Phase 1',10.000::numeric,4.000::numeric,8.000::numeric,'static',5::integer,'{"qualifying_day_profit_percent":0.5,"availability":"in_review","source_conflict":"Overview says 8% standard max loss, limited launch promotion 10%; July comparison lists 10%. Official collection marks account discontinued."}'),
  ('2-step-plus',2,'Phase 2',5.000::numeric,4.000::numeric,8.000::numeric,'static',5::integer,'{"qualifying_day_profit_percent":0.5,"availability":"in_review","source_conflict":"Overview says 8% standard max loss, limited launch promotion 10%; July comparison lists 10%. Official collection marks account discontinued."}'),
  ('2-step-pro-v2',1,'Phase 1',8.000::numeric,4.000::numeric,9.000::numeric,'static',3::integer,'{"qualifying_day_profit_percent":0.5,"source_note":"Official overview updated July 24, 2026: 8% target, 4% daily loss, 9% static max loss, three qualifying profitable days of 0.5%."}'),
  ('2-step-pro-v2',2,'Phase 2',5.000::numeric,4.000::numeric,9.000::numeric,'static',3::integer,'{"qualifying_day_profit_percent":0.5,"source_note":"Official overview updated July 24, 2026: 5% target, 4% daily loss, 9% static max loss, three qualifying profitable days of 0.5%."}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, minimum_days, raw_rules) on true
where programs.slug = phase.program_slug
on conflict (program_id, phase_number) do update
set name = excluded.name, fee = excluded.fee, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent, maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, time_limit_days = excluded.time_limit_days,
    minimum_trading_days = excluded.minimum_trading_days, raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.platforms (name, slug) values
  ('MetaTrader 5', 'metatrader-5'), ('Match-Trader', 'match-trader'), ('TradeLocker', 'tradelocker')
on conflict (slug) do update set name = excluded.name;

insert into bullish_banana.program_platforms (program_id, platform_id)
select programs.id, platforms.id
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'top-one-trader'
cross join bullish_banana.platforms
where programs.slug in ('1-step-flash','1-step-nova','2-step-plus','2-step-pro-v2','instant-funding','instant-prime')
  and platforms.slug in ('metatrader-5','match-trader','tradelocker')
on conflict do nothing;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://www.toponetrader.com/terms-and-conditions','Top One Trader official Terms and Conditions','Terms last updated June 2026 identify Top One Trader, LLC and describe simulated account services and non-refundable challenge purchases.'),
  ('https://help.toponetrader.com/en/articles/10912482-comparison-of-account-types','Top One Trader official account comparison','First-party comparison updated July 24, 2026 lists FLASH, NOVA, PLUS, PRO V2, Instant Funding, and Instant PRIME with their headline rules. Some entries contain conflicting or malformed values, which are retained as review notes.'),
  ('https://help.toponetrader.com/en/collections/17913309-2-step-plus-accounts-discontinued','Top One Trader 2-Step PLUS availability notice','Official Help Center collection marks the 2-Step PLUS account type discontinued; conflicts with its appearance on the comparison page.'),
  ('https://checkout.toponetrader.com/product/top-one-trader-challenges/','Top One Trader official challenge checkout','Official product checkout is the place to confirm current product availability, size-specific fee matrix, platform, and add-ons. Dynamic fees were not captured in this review.')
) as source(url, label, notes) on true
where firms.slug = 'top-one-trader'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'top-one-trader'
join (values
  ('1-step-flash','https://help.toponetrader.com/en/articles/8318230-what-are-the-rules-for-the-1-step-flash-challenge-account','Top One Trader FLASH rules','Official rules updated August 22, 2026: phase target, loss limits, minimum days, news rules, platforms, and Forex leverage.'),
  ('1-step-nova','https://help.toponetrader.com/en/articles/13832165-nova-account-overview','Top One Trader NOVA rules and activation fees','Current official overview identifies $7 entry fee, activation fees by size, evaluation and funded rules, platforms, and payout terms.'),
  ('1-step-nova','https://help.toponetrader.com/en/collections/18644764-1-step-nova-accounts','Top One Trader NOVA rules collection','Official collection links to NOVA payout, drawdown, leverage, news, and Equity Stability Score rule articles.'),
  ('2-step-plus','https://help.toponetrader.com/en/articles/13391994-2-step-plus-overview','Top One Trader PLUS rules','Official overview last updated March 28, 2026; includes 8% standard/10% launch max drawdown variant, phase rules, commission, and purchase refund notes.'),
  ('2-step-pro-v2','https://help.toponetrader.com/en/articles/15164777-2-step-pro-v2-overview','Top One Trader PRO V2 rules','Official overview dated July 24, 2026 lists sizes, phase targets, loss limits, funded payout rules, platform-independent Forex leverage, and payout cap.'),
  ('instant-funding','https://help.toponetrader.com/en/articles/12575317-what-are-the-rules-for-the-instant-funding-account','Top One Trader Instant Funding rules','Official rules dated April 1, 2026 list simulated funding, 3% daily loss, 6% trailing max loss, payout consistency, restrictions, and Forex leverage.'),
  ('instant-prime','https://help.toponetrader.com/en/articles/12132613-prime-accounts-overview','Top One Trader Instant PRIME rules','Official overview dated June 15, 2026 lists drawdown, payout, ESS, add-on, platform, and leverage terms.')
) as source(slug, url, label, notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed Top One Trader official terms, account comparison, challenge checkout destination, and Help Center sources on 2026-09-28. Firm identity and six comparison-page product families are recorded. Product availability, live fee matrices, selectable add-ons, and some source conflicts need checkout confirmation before publication.'
from bullish_banana.firms where slug = 'top-one-trader';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed the current Top One Trader first-party product/rules source on 2026-09-28. Program remains in review pending live checkout confirmation of availability, account-size fees, and selectable add-ons.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'top-one-trader'
where programs.slug in ('1-step-flash','1-step-nova','2-step-plus','2-step-pro-v2','instant-funding','instant-prime');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'View ' || programs.name,
  case programs.slug
    when '1-step-nova' then 'https://www.toponetrader.com/nova'
    when '2-step-pro-v2' then 'https://help.toponetrader.com/en/articles/15164777-2-step-pro-v2-overview'
    when 'instant-prime' then 'https://help.toponetrader.com/en/articles/12132613-prime-accounts-overview'
    else 'https://checkout.toponetrader.com/product/top-one-trader-challenges/'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'top-one-trader'
  and programs.slug in ('1-step-flash','1-step-nova','2-step-plus','2-step-pro-v2','instant-funding','instant-prime')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
