-- Add Atmos Funded's current Forex challenge families from first-party sources.
-- Reviewed 2026-09-28. Promo pricing and several source inconsistencies are preserved
-- in commercial_details; this migration is a draft and has not been applied.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'Atmos Funded', 'atmos-funded',
  'Atmos Funded offers simulated Forex evaluations, instant funding, and a pay-after-pass Nova challenge with model-specific risk and payout rules.',
  'https://atmosfunded.com/', 'published', now()
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description,
    website_url = excluded.website_url, status = 'published',
    published_at = coalesce(bullish_banana.firms.published_at, now()), updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'atmos-funded'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'KM', 'Atmos Global Ltd', array['Forex', 'Metals', 'Indices', 'Cryptocurrencies']::text[],
  '{"service_model":"Atmos describes its challenges and funded accounts as simulated trading using virtual funds, not live trading.","platform_options":["MetaTrader 5","TradeLocker","Match-Trader"],"platform_notes":"Confirm account- and country-specific availability at checkout before publication.","headquarters":"Bonovo Road, Fomboni, Mohéli, Comoros.","company_disclosure":"Atmos Global Ltd is disclosed as website owner/operator (company HT00525042; license BFX2025060). AtmosFunded Ltd (Cyprus registration HE471627) is identified as trademark owner/provider of educational, challenge, and payment services.","restricted_countries":["United States","Belgium","North Korea","Russia","Iraq","American Samoa","Belarus","Northern Mariana Islands","Palestine","Puerto Rico","Ukraine","U.S. Virgin Islands","Wallis and Futuna","Yemen","Zimbabwe"],"allocation_note":"Main homepage promotes scaling up to $400K; individual program pages state $400K maximum for evaluation products and $200K for Instant Funding."}'::jsonb
from bullish_banana.firms where slug = 'atmos-funded'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select firms.id, country.country_code, 'restricted', 'Atmos official website disclosure lists this jurisdiction as restricted (reviewed 2026-09-28).'
from bullish_banana.firms
cross join (values ('US'),('BE'),('KP'),('RU'),('IQ'),('AS'),('BY'),('MP'),('PS'),('PR'),('UA'),('VI'),('WF'),('YE'),('ZW')) as country(country_code)
where firms.slug = 'atmos-funded'
on conflict (firm_id, country_code) do update
set restriction_type = excluded.restriction_type, note = excluded.note, updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select firms.id, item.name, item.slug, item.description, item.program_type, item.status, 'USD', item.account_sizes::jsonb,
  item.max_leverage, item.profit_split_percent, item.payout_frequency, item.minimum_trading_days,
  item.news_allowed, item.weekend_holding_allowed, item.commercial_details::jsonb, null
from bullish_banana.firms
join (values
  ('Atmos Funded 1-Step Standard', '1-step-standard', 'evaluation', 'One-phase Forex evaluation with a 10% target, 3% daily loss, 6% trailing maximum loss that locks at initial balance, and three qualifying days.', 'published', '[5000,10000,25000,50000,100000,200000]', 50::numeric, null::numeric, 'Every 14 days after funding', 3::integer, false, true, '{"account_size_prices":[{"account_size":5000,"fee":43,"currency":"USD"},{"account_size":10000,"fee":69,"currency":"USD"},{"account_size":25000,"fee":139,"currency":"USD"},{"account_size":50000,"fee":239,"currency":"USD"},{"account_size":100000,"fee":383,"currency":"USD"},{"account_size":200000,"fee":749,"currency":"USD"}],"payout_rules":"The dedicated page says payouts every 14 days, up to 90% with scaling. General payout article confirms 14 days.","consistency_rule":"No consistency rule listed.","prohibited_strategies":"High-impact news trading is prohibited on funded accounts within ±2 minutes; EAs allowed. Weekend holding not specified in reviewed source.","drawdown_rule":"6% trailing drawdown locks at initial balance and is fixed at initial balance when payout is requested.","time_limit":"No evaluation deadline was listed in reviewed article.","pricing_note":"Official Help Center base price matrix reviewed 2026-09-28. Homepage selector showed $32.25 vs $43 at $50K and advertised a SEPT code/12% September promotion; live price presentation does not reconcile arithmetically with that code. Promo excluded from base fee data and must be refreshed before display."}'),
  ('Atmos Funded 1-Step Plus', '1-step-plus', 'evaluation', 'One-phase Forex evaluation with a 6% target, no daily loss limit, 3% trailing maximum loss, and a 45% funded consistency rule.', 'in_review', '[10000,25000,50000,100000,150000]', 50::numeric, null::numeric, 'Every 14 days after funding', 3::integer, false, true, '{"account_size_prices":[{"account_size":10000,"fee":37,"currency":"USD"},{"account_size":25000,"fee":71,"currency":"USD"},{"account_size":50000,"fee":109,"currency":"USD"},{"account_size":100000,"fee":149,"currency":"USD"},{"account_size":150000,"fee":175,"currency":"USD"}],"activation_fee":{"10000":65,"25000":65,"50000":125,"100000":125,"150000":125,"currency":"USD","included_in_challenge_price":false},"payout_rules":"Every 14 days; profit share described as up to 90% with scaling.","consistency_rule":"Funded phase: no single day may exceed 45% of total profit (equity based).","prohibited_strategies":"High-impact news trading is prohibited on funded accounts within ±2 minutes; EAs/copy trading allowed. Weekend holding not specified.","drawdown_rule":"3% trailing drawdown locks at initial balance and resets on payout.","publication_note":"Keep in review until checkout confirms activation fee applicability and whether it is separately charged for each available size."}'),
  ('Atmos Funded 2-Step Standard', '2-step-standard', 'evaluation', 'Two-phase Forex evaluation with 10% then 5% targets, 5% daily loss, 10% static maximum loss, and three qualifying days per phase.', 'in_review', '[5000,10000,25000,50000,100000,200000]', 50::numeric, null::numeric, 'Every 14 days after funding', 3::integer, false, true, '{"account_size_prices":[{"account_size":5000,"fee":63,"currency":"USD"},{"account_size":10000,"fee":94,"currency":"USD"},{"account_size":25000,"fee":214,"currency":"USD"},{"account_size":50000,"fee":329,"currency":"USD"},{"account_size":100000,"fee":549,"currency":"USD"},{"account_size":200000,"fee":989,"currency":"USD"}],"payout_rules":"General payout article and overview say 14 days. The detailed plan page''s payout section instead says every 30 days, scaling to biweekly; resolve before publishing.","consistency_rule":"No consistency rule listed.","prohibited_strategies":"High-impact news trading is prohibited on funded accounts within ±2 minutes; EAs allowed. Weekend holding not specified.","drawdown_rule":"5% daily and 10% overall static limits.","publication_note":"Fee table and risk rules are from current dedicated article. In review because the same article contains conflicting payout intervals."}'),
  ('Atmos Funded 2-Step Plus', '2-step-plus', 'evaluation', 'Two-phase Forex evaluation with 6% targets in both phases, 3% daily loss, 6% static maximum loss, and first funded payout on demand.', 'published', '[5000,10000,25000,50000,100000]', 50::numeric, null::numeric, 'First payout on demand, then every 14 days', 3::integer, false, true, '{"account_size_prices":[{"account_size":5000,"fee":28,"currency":"USD"},{"account_size":10000,"fee":51,"currency":"USD"},{"account_size":25000,"fee":95,"currency":"USD"},{"account_size":50000,"fee":189,"currency":"USD"},{"account_size":100000,"fee":379,"currency":"USD"}],"payout_rules":"First payout is available on demand after funding; subsequent payouts every 14 days. Profit share up to 90% with scaling.","consistency_rule":"No consistency rule listed.","prohibited_strategies":"High-impact news trading is prohibited on funded accounts within ±2 minutes; EAs allowed. Weekend holding not specified.","drawdown_rule":"3% daily and 6% overall static limits.","pricing_note":"Official Help Center base price matrix reviewed 2026-09-28. September homepage selector showed a different promotional amount for the 50K Standard plan; exact plan discounts and coupon stacking were not consistent across the captured presentation."}'),
  ('Atmos Funded Instant Funding', 'instant-funding', 'instant_funding', 'Immediate simulated Forex funding with no evaluation, 3% daily loss, 5% trailing maximum loss, and a 20% consistency rule.', 'published', '[5000,10000,25000,50000,100000]', 50::numeric, null::numeric, 'Every 14 days after funding', null::integer, false, true, '{"account_size_prices":[{"account_size":5000,"fee":75,"currency":"USD"},{"account_size":10000,"fee":124,"currency":"USD"},{"account_size":25000,"fee":240,"currency":"USD"},{"account_size":50000,"fee":374,"currency":"USD"},{"account_size":100000,"fee":649,"currency":"USD"}],"payout_rules":"14-day cycle; profit share up to 90% with scaling. Requesting payout locks drawdown at initial balance; full withdrawal can breach the account.","consistency_rule":"No single day may exceed 20% of total profit, equity based.","prohibited_strategies":"High-impact news trading prohibited within ±2 minutes; EAs allowed. Weekend holding not specified.","drawdown_rule":"3% daily loss and 5% trailing maximum loss; locks at initial balance upon payout.","allocation_note":"Dedicated product page states maximum allocation $200,000 although homepage promotes scaling up to $400,000 overall.","pricing_note":"Official Help Center base fees reviewed 2026-09-28; current homepage selector shows promotional price and a coupon. Promo not mixed into base fee schedule."}'),
  ('Atmos Funded NOVA', 'nova', 'evaluation', 'Pay-after-pass single-phase Forex challenge with a $5 entry fee, 5% target, 4% daily loss, 8% trailing maximum loss, and a separate size-based funded activation fee.', 'in_review', '[10000,25000,50000]', 50::numeric, null::numeric, 'On demand after funding', null::integer, false, true, '{"account_size_prices":[{"account_size":10000,"fee":5,"currency":"USD","fee_type":"challenge_entry"},{"account_size":25000,"fee":5,"currency":"USD","fee_type":"challenge_entry"},{"account_size":50000,"fee":5,"currency":"USD","fee_type":"challenge_entry"}],"funded_activation_fees":[{"account_size":10000,"fee":79,"currency":"USD"},{"account_size":25000,"fee":184,"currency":"USD"},{"account_size":50000,"fee":345,"currency":"USD"}],"payout_rules":"Funded payouts on demand; seven qualifying profitable days of at least 0.5% of starting balance. Profit share varies with scaling; no fixed base percentage normalized.","consistency_rule":"No challenge consistency listed; per-symbol overall risk (closed and floating) cannot exceed 1% in a day while funded.","prohibited_strategies":"High-impact news trading prohibited within ±2 minutes; EAs allowed. Weekend holding not specified.","drawdown_rule":"4% daily and 8% trailing total loss; funded drawdown locks at initial balance when payout is requested.","publication_note":"Dedicated Help Center page lists only $10K/$25K/$50K funded-fee tiers, while the main account selector displays sizes through $200K and promotes NOVA. Keep in review until supported sizes and activation fees are confirmed in live checkout."}')
) as item(name, slug, program_type, description, status, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details)
  on true
where firms.slug = 'atmos-funded'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = excluded.status, currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details,
    published_at = case when excluded.status = 'published' then coalesce(bullish_banana.programs.published_at, now()) else null end,
    updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select programs.id, phases.phase_number, phases.name, phases.target, phases.daily_loss,
       phases.max_loss, phases.drawdown_type, phases.min_days, phases.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'atmos-funded'
join (values
  ('1-step-standard',1,'Evaluation',10::numeric,3::numeric,6::numeric,'trailing',3::integer,'{"profitable_day_threshold":"0.5%","trailing_drawdown_locks_at_initial_balance":true}'),
  ('1-step-plus',1,'Evaluation',6::numeric,null::numeric,3::numeric,'trailing',3::integer,'{"profitable_day_threshold":"0.5%","funded_drawdown_resets_on_payout":true,"funded_consistency_percent":45}'),
  ('2-step-standard',1,'Phase 1',10::numeric,5::numeric,10::numeric,'static',3::integer,'{"profitable_day_threshold":"0.5%"}'),
  ('2-step-standard',2,'Phase 2',5::numeric,5::numeric,10::numeric,'static',3::integer,'{"profitable_day_threshold":"0.5%"}'),
  ('2-step-plus',1,'Phase 1',6::numeric,3::numeric,6::numeric,'static',3::integer,'{"profitable_day_threshold":"0.5%"}'),
  ('2-step-plus',2,'Phase 2',6::numeric,3::numeric,6::numeric,'static',3::integer,'{"profitable_day_threshold":"0.5%"}'),
  ('nova',1,'Evaluation',5::numeric,4::numeric,8::numeric,'trailing',null::integer,'{"entry_fee_usd":5,"profitable_day_threshold":"none","funded_fee_varies_by_size":true}')
) as phases(slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, min_days, raw_rules)
on phases.slug = programs.slug
where not exists (
  select 1 from bullish_banana.program_phases existing
  where existing.program_id = programs.id and existing.phase_number = phases.phase_number
);

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://atmosfunded.com/','Atmos Funded official homepage and plan selector','Current account selector shows sizes from $5K to $200K, Standard/Plus types, step selectors, live promotional pricing, and NOVA promotion. Homepage legal footer identifies website operator and company disclosure.'),
  ('https://atmosfunded.com/rules/','Atmos Funded official rules','Official rules cover platform, trading conduct, simulated-account model, product rules, and risk disclosures.'),
  ('https://help.atmosfunded.com/en/articles/12380567-compare-challenges-which-one-is-right-for-me','Atmos Help Center challenge comparison','Comparison page dated 2026-08-19 lists six current product families: 1-Step Standard, 1-Step Plus, 2-Step Standard, 2-Step Plus, Instant Funding, and NOVA.'),
  ('https://help.atmosfunded.com/en/articles/12380605-how-payouts-work','Atmos Help Center payout schedule','General payout source dated 2026-08-19: standard 1-Step and 2-Step plans every 14 days; 2-Step Plus first payout on demand then every 14 days; Instant every 14 days; NOVA on demand.')
) as source(url,label,notes) on true
where firms.slug = 'atmos-funded'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'atmos-funded'
join (values
  ('1-step-standard','https://help.atmosfunded.com/en/articles/12380551-1-step-standard-challenge','Atmos 1-Step Standard rules and price table','Official article updated August 2026. Base fee schedule and risk terms recorded. Homepage selector promotion does not reconcile cleanly with its advertised 12% code; promo is kept separate.'),
  ('1-step-plus','https://help.atmosfunded.com/en/articles/12380556-1-step-plus-challenge','Atmos 1-Step Plus rules and price table','Official article updated August 2026 lists $65 activation fee for $10K-$25K and $125 for $50K-$150K; fee treatment should be confirmed in checkout.'),
  ('2-step-standard','https://help.atmosfunded.com/en/articles/12380559-2-step-standard-challenge','Atmos 2-Step Standard rules and price table','Official article updated August 2026 lists base fees and 10%/5% targets. Its overview says payout every 14 days but its payout subsection says 30 days scaling to biweekly; general payout page says every 14 days.'),
  ('2-step-plus','https://help.atmosfunded.com/en/articles/12380560-2-step-plus-challenge','Atmos 2-Step Plus rules and price table','Official article updated August 2026 lists base fees, 6%/6% targets, static limits, and first payout on demand then every 14 days.'),
  ('instant-funding','https://help.atmosfunded.com/en/articles/12380563-instant-funding','Atmos Instant Funding rules and price table','Official article updated August 2026 lists $5K-$100K fee matrix, 3% daily/5% trailing limits, 20% consistency, and $200K maximum allocation.'),
  ('nova','https://help.atmosfunded.com/en/articles/13959447-nova-challenge','Atmos NOVA rules and funded-fee table','Official page dated March 30, 2026 lists $5 entry fee, 5% target, $10K/$25K/$50K funded fees, and payout/risk rules. Homepage promotes NOVA; current selectable funded sizes remain to be verified.')
) as source(slug,url,label,notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed Atmos official homepage, legal disclosure, product comparison, current challenge articles, payout rules, and restrictions on 2026-09-28. Six current product families are captured. Promotions, activation fees, and inconsistent payout/size disclosures remain explicitly documented; draft not applied.'
from bullish_banana.firms where slug = 'atmos-funded';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed the current Atmos first-party program rule and pricing article on 2026-09-28. Base fees and supported rules are recorded; see commercial_details for current promo or source conflicts.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'atmos-funded'
where programs.slug in ('1-step-standard','1-step-plus','2-step-standard','2-step-plus','instant-funding','nova');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'View ' || programs.name,
  case programs.slug
    when '1-step-standard' then 'https://help.atmosfunded.com/en/articles/12380551-1-step-standard-challenge'
    when '1-step-plus' then 'https://help.atmosfunded.com/en/articles/12380556-1-step-plus-challenge'
    when '2-step-standard' then 'https://help.atmosfunded.com/en/articles/12380559-2-step-standard-challenge'
    when '2-step-plus' then 'https://help.atmosfunded.com/en/articles/12380560-2-step-plus-challenge'
    when 'instant-funding' then 'https://help.atmosfunded.com/en/articles/12380563-instant-funding'
    else 'https://help.atmosfunded.com/en/articles/13959447-nova-challenge'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'atmos-funded'
  and programs.slug in ('1-step-standard','1-step-plus','2-step-standard','2-step-plus','instant-funding','nova')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');
