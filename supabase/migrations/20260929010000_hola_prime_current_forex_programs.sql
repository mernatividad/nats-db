-- Add Hola Prime's current Forex challenge models and separate Direct account.
-- Reviewed 2026-09-28 against official product pages, rules, T&Cs, and live plan UI.
-- Per-size challenge fees are not exposed on the public pages; do not infer them
-- from starting prices. Prime X is retained in review because current English UI omits it.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, published_at)
values (
  'Hola Prime', 'hola-prime',
  'Hola Prime offers simulated Forex evaluations in Prime and Pro models, plus a direct funded account with distinct risk, payout, and trading restrictions.',
  'https://holaprime.com/forex/', 'published', now()
)
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'published', published_at = coalesce(bullish_banana.firms.published_at, now()), updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'hola-prime'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'futures' from bullish_banana.firms where slug = 'hola-prime'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'HK', 'Hola Prime Limited (Hong Kong)', array['Forex', 'Cryptocurrencies', 'Indices', 'Commodities']::text[],
  '{"service_model":"Hola Prime describes the challenge and Hola Prime (Sim. Funded) account as simulated trading and educational services. Its site states Hola Prime does not act as a broker or accept deposits.","platform_options":["MetaTrader 4","MetaTrader 5","cTrader","Match-Trader","DXtrade","TradeLocker"],"platform_notes":"Official platform source says platform access may vary by account and country. Match-Trader and TradeLocker are identified as U.S.-available choices in the FAQ; confirm exact account compatibility at checkout.","website_owner":"The website states it belongs exclusively to Hola Prime Limited, Hong Kong.","related_service_entities":"The website legal footer identifies Hola Prime Limited (Cyprus, registration HE 454359) as a wholly owned subsidiary; MT4/MT5 services are provided by Hola Prime Ltd Mauritius (registration 220248; FSC license GB24203729); Match-Trader and DXtrade services identify Gooey Trade, GT Tech LLC (Florida). These are described as service providers/group companies, not the website owner.","separate_markets":"Hola Prime operates separate Forex and Futures offerings; this migration records firm membership in both markets but includes only Forex products.","allocation_note":"The Forex comparison and rules show standard allocation limits of up to $400K, with a $90K country-specific cap for named jurisdictions. A Prime Circle benefit can increase allocation above standard limits. Do not present the promotional $4M ceiling as standard Forex account availability.","restricted_countries":["Afghanistan","Belarus","Burundi","China","Cuba","Democratic Republic of the Congo","Sudan","Sri Lanka","North Korea","Yemen"],"country_limit_countries":["Nigeria","Malaysia","Indonesia","Cambodia","Israel","Thailand","Botswana","Mongolia","Kazakhstan","Jamaica","Mozambique"],"country_limit_note":"Terms impose a lower $90K Forex allocation for the listed countries; these are not listed as fully restricted jurisdictions."}'::jsonb
from bullish_banana.firms where slug = 'hola-prime'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select firms.id, country.country_code, 'restricted', 'Hola Prime website customer disclosure lists this jurisdiction as unavailable (reviewed 2026-09-28).'
from bullish_banana.firms
cross join (values ('AF'),('BY'),('BI'),('CN'),('CU'),('CD'),('SD'),('LK'),('KP'),('YE')) as country(country_code)
where firms.slug = 'hola-prime'
on conflict (firm_id, country_code) do update
set restriction_type = excluded.restriction_type, note = excluded.note, updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  news_allowed, weekend_holding_allowed, commercial_details, published_at
)
select firms.id, item.name, item.slug, item.description, item.program_type, item.status, 'USD', item.account_sizes::jsonb,
       item.max_leverage, null::numeric, item.payout_frequency, item.minimum_trading_days,
       item.news_allowed, item.weekend_holding_allowed, item.commercial_details::jsonb,
       case when item.status = 'published' then now() else null end
from bullish_banana.firms
join (values
  ('Hola Prime 1-Step Prime','1-step-prime','evaluation','Single-phase Forex evaluation with a 10% target, 3% daily loss calculated from the previous day close, 6% static maximum loss, and two minimum trading days.','in_review','[2000,5000,10000,25000,50000,100000,200000]',50::numeric,'Multiple options: biweekly 80%, monthly 95%, or on-demand 80%',2::integer,true,true,'{"starting_fee_usd":39,"account_size_prices":[],"account_size_price_note":"Official Prime page advertises a $39 starting fee; no public per-size fee schedule was captured. The official rules selector lists $2K/$5K/$10K/$25K/$50K/$100K/$200K across its Forex rules view; confirm exact sizes and fees for this model in checkout before publishing.","payout_rules":"Funded account offers biweekly at 80%, monthly at 95%, or on-demand at 80%; on-demand requires 40% consistency and minimum 2% profit, while biweekly requires 3 profitable days and monthly 7. Current page says requests are processed within one hour after review; review may take up to 24 business hours.","consistency_rule":"No challenge consistency rule. Funded on-demand payout option has 40% consistency; direct account payout options have separate requirements.","challenge_fee_refund":"100% refund paid in four installments of 25% with the first four payouts.","prohibited_strategies":"Prime model permits news trading and weekend holding in challenge and funded stages. Funded maximum risk per trade idea is 2% and stop loss is mandatory. 30-day inactivity suspension.","commission_details":"Forex and Gold: $3 per lot per side per official challenge FAQ; confirm platform-specific pricing.","drawdown_rule":"6% fixed maximum loss from initial balance; 3% daily loss based on previous-day closing balance.","time_limit":"Unlimited evaluation duration.","publication_note":"Keep in review until current checkout confirms model-specific account-size availability, per-size prices, selected payout configuration and add-ons."}'),
  ('Hola Prime 2-Step Prime','2-step-prime','evaluation','Two-phase Forex evaluation with 8% then 5% targets, 5% daily loss (4% on $200K), 10% static total loss (8% on $200K), and three trading days per phase.','in_review','[2000,5000,10000,25000,50000,100000,200000]',50::numeric,'Multiple options: biweekly 80%, monthly 95%, or on-demand 80%',3::integer,true,true,'{"starting_fee_usd":39,"account_size_prices":[],"account_size_price_note":"Official Prime page advertises a $39 starting fee. Public Forex rules selector lists sizes from $2K to $200K but does not provide a per-size price table. Confirm model-specific size/price availability in checkout.","payout_rules":"Funded account offers biweekly at 80%, monthly at 95%, or on-demand at 80%; on-demand requires 40% consistency and minimum 2% profit, while biweekly requires 3 profitable days and monthly 7. Current T&Cs identify a 40% funded consistency score for on-demand payout.","consistency_rule":"No challenge consistency rule. Funded on-demand payout option has 40% consistency.","challenge_fee_refund":"100% refund paid in four installments of 25% with the first four payouts.","prohibited_strategies":"Prime model permits news trading and weekend holding in challenge and funded stages. Funded maximum risk per trade idea is 2%, and a stop loss is mandatory. 30-day inactivity suspension.","commission_details":"Forex and Gold: $3 per lot per side per official challenge FAQ; confirm platform-specific pricing.","drawdown_rule":"5% daily loss from previous day closing balance (4% for $200K); 10% static total loss (8% for $200K).","time_limit":"Unlimited evaluation duration.","publication_note":"Keep in review until current checkout confirms model-specific account-size availability and exact fee matrix."}'),
  ('Hola Prime 2-Step Pro','2-step-pro','evaluation','Two-phase Forex evaluation with 8% then 5% targets, 5% daily loss (4% on $200K), 10% static total loss (8% on $200K), and two trading days per phase.','in_review','[5000,10000,25000,50000,100000,200000]',100::numeric,'Multiple options: biweekly 80%, monthly 95%, or on-demand 80%',2::integer,null::boolean,null::boolean,'{"starting_fee_usd":59,"account_size_prices":[],"account_size_price_note":"Official Pro page advertises a $59 starting fee and size choices from $5K through $200K; no per-size challenge fee schedule was captured. Confirm full matrix in checkout.","payout_rules":"Funded account offers biweekly at 80%, monthly at 95%, or on-demand at 80%; payout requirements vary by selected cycle. The comparison page lists 40% consistency for on-demand and 3/7 profitable days for biweekly/monthly.","consistency_rule":"No challenge consistency rule. Funded on-demand payout option has 40% consistency.","challenge_fee_refund":"100% refund paid in four installments of 25% with the first four payouts.","prohibited_strategies":"Challenge news and weekend holding are allowed. Funded accounts restrict trades during high-impact news ±5 minutes and close positions before Friday 15:45 EST; EAs are allowed. Funded maximum risk per trade idea is 2% with mandatory stop loss. 30-day inactivity suspension.","commission_details":"Forex and Gold: $3 per lot per side per official challenge FAQ; confirm platform-specific pricing.","drawdown_rule":"5% daily loss from previous day close (4% on $200K); 10% static total loss (8% on $200K).","time_limit":"Unlimited evaluation duration.","publication_note":"Keep in review until current checkout confirms size/fee schedule and selected funded payout terms."}'),
  ('Hola Prime 2-Step Prime X','2-step-prime-x','evaluation','Two-phase Forex evaluation with 10% then 5% targets, five minimum days per phase, 5% daily loss, 10% static maximum loss, and an 80% reward share.','in_review','[5000,10000,25000,50000,100000]',50::numeric,'Biweekly; current Prime X-specific payout terms require verification',5::integer,null::boolean,null::boolean,'{"starting_fee_usd":39,"account_size_prices":[],"account_size_price_note":"Official Prime X page advertises a $39 starting fee and sizes $5K/$10K/$25K/$50K/$100K. No per-size fee matrix was captured.","availability_conflict":"Prime X appears in the official Forex homepage, dedicated Prime X page, Terms & Conditions, and a Spanish-language Forex comparison. The current English Forex Trading Rules controls expose 1-Step Prime, 2-Step Prime, 2-Step Pro, and Direct only; the English comparison omits Prime X. Keep this candidate in review until its current English checkout availability is confirmed.","payout_rules":"Terms identify a biweekly payout cycle and 50% funded consistency score for 2-Step Prime X. Detailed payout eligibility, split and refund conditions need confirmation from current checkout/rules.","prohibited_strategies":"Prime X challenge news trading is allowed; funded accounts restrict execution on affected instruments within ±5 minutes of high-impact events. Weekend holding allowed. Official Prime X marketing says no mandatory stop loss and no 10-minute trade re-entry window; firm-wide funded terms still describe a 2% risk per trade idea, so reconcile the interaction before publishing.","commission_details":"Forex and Gold: $3 per lot per side per official challenge FAQ; confirm platform-specific pricing.","drawdown_rule":"10% static maximum loss; 5% daily limit according to official comparison.","time_limit":"Unlimited evaluation duration per localized official comparison.","profit_split_note":"Dedicated page advertises 80:20; do not conflate with Prime/Pro options up to 95%."}'),
  ('Hola Prime Direct Forex','direct-forex','funded_account','Direct simulated Forex account with no evaluation or target, 3% daily loss, 7% end-of-day trailing maximum loss, and configurable funded payout options.','in_review','[5000,10000,25000,50000,100000]',50::numeric,'Biweekly; selectable 80% or 90% payout split',null::integer,false,false,'{"account_size_prices":[{"account_size":100000,"fee":1259,"currency":"USD","price_context":"Official Direct page showed $1,259 base and $1,007.20 with WELCOME20 promo when reviewed 2026-09-28."}],"account_size_price_note":"The official Direct page exposes $5K/$10K/$25K/$50K/$100K choices but only the captured $100K price is recorded; promotion may expire. Other sizes require checkout verification.","payout_rules":"Biweekly 80% or biweekly 90% options were visible; payout choice changes cost. Direct funded payout consistency is 20%. Processing may be within one hour after review; review may take up to 24 business hours.","consistency_rule":"20% for all Direct account payout cycles.","prohibited_strategies":"News trading and weekend holding are not allowed on Direct funded accounts; EAs are not allowed. Risk per trade idea max 2%, stop loss mandatory. 30-day inactivity suspension.","drawdown_rule":"3% daily loss and 7% EOD trailing maximum loss.","time_limit":"No evaluation; immediate simulated funded access.","commission_details":"Forex and Gold: $3 per lot per side per Direct account FAQ; platform-specific schedule should be confirmed.","publication_note":"Direct is a current Forex program but is not an evaluation challenge. Keep separate in comparisons and confirm complete size-specific pricing before publication."}')
) as item(name, slug, program_type, description, status, account_sizes, max_leverage, payout_frequency, minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details)
  on true
where firms.slug = 'hola-prime'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = excluded.status, currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    news_allowed = excluded.news_allowed, weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, published_at = null, updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select programs.id, phase.phase_number, phase.name, phase.target, phase.daily_loss,
       phase.max_loss, phase.drawdown_type, phase.minimum_days, phase.raw_rules::jsonb
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'hola-prime'
join (values
  ('1-step-prime',1,'Evaluation',10::numeric,3::numeric,6::numeric,'static',2::integer,'{"daily_loss_basis":"previous day closing balance"}'),
  ('2-step-prime',1,'Phase 1',8::numeric,5::numeric,10::numeric,'static',3::integer,'{"daily_loss_basis":"previous day closing balance","200k_daily_loss_percent":4,"200k_max_loss_percent":8}'),
  ('2-step-prime',2,'Phase 2',5::numeric,5::numeric,10::numeric,'static',3::integer,'{"daily_loss_basis":"previous day closing balance","200k_daily_loss_percent":4,"200k_max_loss_percent":8}'),
  ('2-step-pro',1,'Phase 1',8::numeric,5::numeric,10::numeric,'static',2::integer,'{"daily_loss_basis":"previous day closing balance","200k_daily_loss_percent":4,"200k_max_loss_percent":8}'),
  ('2-step-pro',2,'Phase 2',5::numeric,5::numeric,10::numeric,'static',2::integer,'{"daily_loss_basis":"previous day closing balance","200k_daily_loss_percent":4,"200k_max_loss_percent":8}'),
  ('2-step-prime-x',1,'Phase 1',10::numeric,5::numeric,10::numeric,'static',5::integer,'{"availability_status":"in_review","source_language_conflict":true}'),
  ('2-step-prime-x',2,'Phase 2',5::numeric,5::numeric,10::numeric,'static',5::integer,'{"availability_status":"in_review","source_language_conflict":true}')
) as phase(program_slug, phase_number, name, target, daily_loss, max_loss, drawdown_type, minimum_days, raw_rules)
on phase.program_slug = programs.slug
where not exists (
  select 1 from bullish_banana.program_phases existing
  where existing.program_id = programs.id and existing.phase_number = phase.phase_number
);

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select firms.id, source.url, source.label, source.notes
from bullish_banana.firms
join (values
  ('https://holaprime.com/forex/','Hola Prime official Forex homepage and legal disclosures','Homepage identifies Prime X and Forex offering; footer says the website belongs to Hola Prime Limited, Hong Kong, discloses service entities and simulated service model.'),
  ('https://holaprime.com/forex/challenge-comparison/','Hola Prime Forex challenge and funded account comparison','Current English comparison lists 1-Step Prime, 2-Step Prime, 2-Step Pro, and Direct funded account terms; excludes Prime X, which appears on localized page and dedicated product page.'),
  ('https://holaprime.com/forex/forex-trading-rules/','Hola Prime interactive Forex trading rules','Interactive rules selectors reviewed 2026-09-28 for 1-Step Prime, 2-Step Prime, and 2-Step Pro. Global selector lists $2K-$200K; model-specific targets, limits, and stage restrictions captured.'),
  ('https://holaprime.com/terms-conditions/','Hola Prime Terms and Conditions','Official terms list Forex/Futures market rules, firm-wide restrictions, risk-per-trade policy, payout consistency, maximum allocation and country-specific reduced allocation details.'),
  ('https://holaprime.com/forex/trading-platforms/','Hola Prime Forex trading platforms','Official page lists MT5, cTrader, Match Trader, DXtrade, and TradeLocker; platform access and underlying service entities vary by location/provider.'),
  ('https://holaprime.com/forex/faq/trading-infrastructure/what-trading-platforms-and-instruments-does-hola-prime-provide/','Hola Prime official platform and instrument FAQ','Current FAQ lists six platform families, supported asset classes, and U.S./UK availability notes; use as firm-level compatibility reference, not proof every program supports each platform.')
) as source(url,label,notes) on true
where firms.slug = 'hola-prime'
  and not exists (select 1 from bullish_banana.sources existing where existing.firm_id = firms.id and existing.source_url = source.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, source.url, source.label, source.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'hola-prime'
join (values
  ('1-step-prime','https://holaprime.com/forex/prime-challenge/','Hola Prime Prime Challenge models and starting fee','Official Prime page identifies active 1-Step and 2-Step Prime models, $39 starting fee, $5K-$200K promotional account-size choices, Prime features and refund messaging. Per-size challenge prices were not published.'),
  ('1-step-prime','https://holaprime.com/forex/forex-trading-rules/?plan=1-step-prime','Hola Prime 1-Step Prime objectives and rules','Interactive official rules reviewed 2026-09-28: 10% target, 2 minimum trading days, 3% previous-close daily limit, 6% static max loss, no time limit, 50:1 FX leverage; Prime funded restrictions and payouts are sourced separately.'),
  ('2-step-prime','https://holaprime.com/forex/prime-challenge/','Hola Prime Prime Challenge models and starting fee','Official Prime page identifies active 1-Step and 2-Step Prime models, $39 starting fee, and Prime account terms. Per-size challenge prices were not published.'),
  ('2-step-prime','https://holaprime.com/forex/forex-trading-rules/?plan=2-step-prime','Hola Prime 2-Step Prime objectives and rules','Interactive official rules reviewed 2026-09-28: 8%/5% targets, 3 minimum days per phase, 5% daily (4% at $200K), 10% maximum loss (8% at $200K), no time limit, 50:1 FX leverage.'),
  ('2-step-pro','https://holaprime.com/forex/pro-challenge/','Hola Prime Pro Challenge offer and starting fee','Official Pro page identifies 2-Step Pro, $59 starting fee, size choices up to $200K, 100:1 leverage and fee refund. Per-size challenge price schedule was not public.'),
  ('2-step-pro','https://holaprime.com/forex/forex-trading-rules/?plan=2-step-pro','Hola Prime 2-Step Pro objectives and rules','Interactive official rules reviewed 2026-09-28: 8%/5% targets, 2 minimum days per phase, 5% daily (4% at $200K), 10% max loss (8% at $200K), 100:1 FX leverage; funded news/weekend rules are stricter.'),
  ('2-step-pro','https://holaprime.com/forex/faq/hola-prime-challenges/hola-prime-2-step-pro-challenge/','Hola Prime 2-Step Pro FAQ','Official FAQ covers refund, commissions, platforms, instruments, and model leverage. Challenge fee is refunded as four 25% payout installments.'),
  ('2-step-prime-x','https://holaprime.com/forex/2-step-prime-x/','Hola Prime 2-Step Prime X offer page','Dedicated official page promotes 10%/5% target, five minimum days per phase, 10% max loss, $39 starting fee, sizes $5K-$100K, 80% share, and absent mandatory SL; English model-selector availability conflicts.'),
  ('2-step-prime-x','https://holaprime.com/es/forex/challenge-comparison/','Hola Prime Spanish Forex comparison including Prime X','Official localized comparison lists 2-Step Prime X with 10%/5% targets, five days per phase, 5% daily and 10% overall drawdown; English comparison omits it.'),
  ('2-step-prime-x','https://holaprime.com/terms-conditions/','Hola Prime Terms for Prime X','Current Terms identify Prime X payout cycle/consistency and risk conditions; compare against current English purchase controls before publication.'),
  ('direct-forex','https://holaprime.com/forex/direct-account/','Hola Prime Direct Forex account offer and configurator','Current official page exposes Direct as a separate no-evaluation product, $5K-$100K account choices, 80% or 90% biweekly payout settings, platform choices and one captured $100K price schedule with temporary WELCOME20 promo.'),
  ('direct-forex','https://holaprime.com/forex/faq/hola-prime-challenges/hola-prime-direct-account/','Hola Prime Direct account rules FAQ','Official FAQ lists Direct account instruments, platform families, commissions and leverage; general Direct rules provide 3% daily loss, 7% EOD trailing total loss, no targets, 20% consistency and trading restrictions.')
) as source(slug,url,label,notes) on source.slug = programs.slug
where not exists (select 1 from bullish_banana.sources existing where existing.program_id = programs.id and existing.source_url = source.url);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Reviewed Hola Prime official Forex website, interactive model rules, English and localized comparisons, terms, platform disclosures, and dedicated offer/FAQ pages on 2026-09-28. Current English selector confirms three challenge models and Direct; Prime X remains an in-review candidate because the localized/product pages and English selector disagree. Fees and model-specific size matrices are not publicly exposed.'
from bullish_banana.firms where slug = 'hola-prime';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), 'Reviewed Hola Prime first-party product, rules, comparison, and Terms sources on 2026-09-28. Starting fee or one current configured Direct price is recorded; full price matrix remains unavailable and is explicitly marked in commercial_details.'
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id and firms.slug = 'hola-prime'
where programs.slug in ('1-step-prime','2-step-prime','2-step-pro','2-step-prime-x','direct-forex');

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select firms.id, programs.id, 'official_site', 'View ' || programs.name,
  case programs.slug
    when '1-step-prime' then 'https://holaprime.com/forex/prime-challenge/'
    when '2-step-prime' then 'https://holaprime.com/forex/prime-challenge/'
    when '2-step-pro' then 'https://holaprime.com/forex/pro-challenge/'
    when '2-step-prime-x' then 'https://holaprime.com/forex/2-step-prime-x/'
    else 'https://holaprime.com/forex/direct-account/'
  end,
  true, 'active'
from bullish_banana.firms
join bullish_banana.programs on programs.firm_id = firms.id
where firms.slug = 'hola-prime'
  and programs.slug in ('1-step-prime','2-step-prime','2-step-pro','2-step-prime-x','direct-forex')
  and not exists (select 1 from bullish_banana.affiliate_destinations existing where existing.program_id = programs.id and existing.kind = 'official_site');

