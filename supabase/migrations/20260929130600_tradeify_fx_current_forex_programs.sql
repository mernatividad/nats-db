-- Tradeify FX current Forex products, sourced from its official site and help center on 2026-09-29.
-- Program prices are the published list prices; temporary LAUNCH pricing is retained as an observation.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type, published_at)
values (
  'Tradeify FX', 'tradeify-fx',
  'A simulated CFD trading program offering one-step and two-step Forex evaluations plus instant simulated funding.',
  'https://www.tradeifyfx.co/', 'published', 'forex', now()
)
on conflict (slug) do update
set name=excluded.name, description=excluded.description, website_url=excluded.website_url,
    status='published', market_type='forex',
    published_at=coalesce(bullish_banana.firms.published_at, now()),
    archived_at=null, updated_at=now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug='tradeify-fx'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (
  firm_id, country_code, legal_entity_name, supported_assets, profile_details
)
select id, 'LC', 'Tradeify Ventures LTD',
       array['Forex','Metals','Energies','Indices','Cryptocurrencies']::text[],
       '{
         "service_model":"Tradeify FX describes evaluation, funded and Live Program accounts as simulated accounts with simulated balances. It states traders do not deposit funds or place orders in live markets.",
         "legal_entity":"Tradeify Ventures LTD, Saint Lucia. The official Terms of Use were last updated 2026-09-29. Novaflame LTD, Cyprus, acts as payment agent.",
         "platforms":["MetaTrader 5"],
         "instruments":"Official materials state 42 instruments across Forex, metals, energies, indices and crypto.",
         "jurisdictions":"Tradeify FX states that the service is unavailable to persons located in or resident in the United States. Other restricted jurisdictions are listed dynamically in its Help Center; this record does not reproduce an unverified list.",
         "trading_conditions":"Evaluation accounts may trade through high-impact news. Funded and Live accounts have a five-minutes-before to five-minutes-after restriction for instruments linked to the event currency/country. Overnight and weekend holding are allowed subject to account rules. Self-built EAs and copying among a trader’s own Tradeify FX accounts are allowed; cross-account hedging, unrelated-user copy trading, HFT and latency arbitrage are prohibited.",
         "payouts":"Daily plan: daily payout requests subject to a 4% balance buffer, 1% new-cycle profit requirement after the first payout cycle, and a 3% initial-balance request cap; a full payout is available biweekly. Classic: biweekly. Direct: on demand and subject to a permanent starting-balance payout lock when the first request is made. Standard minimum payout is $100. All payouts are subject to eligibility and verification.",
         "live_program":"The firm says five payouts qualify a trader for its Live Program. The program advertises a 90% starting reward share with a path to 95%; this is a separate funded progression, not an evaluation challenge.",
         "publication_note":"Official profile, legal identity, Forex instruments, plans and rule guides reviewed 2026-09-29. Public list prices are stored as base prices. The LAUNCH 50% banner observed on 2026-09-29 was time-limited through 2026-09-30 11:59 p.m. EST and is not treated as a base fee."
       }'::jsonb
from bullish_banana.firms where slug='tradeify-fx'
on conflict (firm_id) do update
set country_code=excluded.country_code, legal_entity_name=excluded.legal_entity_name,
    supported_assets=excluded.supported_assets,
    profile_details=bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at=now();

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select id, 'US', 'restricted',
       'Official Terms of Use and site footer state Tradeify FX is unavailable to persons located in or resident in the United States; reviewed 2026-09-29.'
from bullish_banana.firms where slug='tradeify-fx'
on conflict (firm_id, country_code) do update
set restriction_type=excluded.restriction_type, note=excluded.note, updated_at=now();

insert into bullish_banana.platforms (name, slug)
values ('MetaTrader 5', 'metatrader-5')
on conflict (slug) do update set name=excluded.name;

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed,
  commercial_details, published_at, archived_at
)
select f.id, x.name, x.slug, x.description, x.program_type, 'forex', 'published', 'USD',
       x.sizes::jsonb, 100, 80, x.payout, null, x.news, true,
       x.details::jsonb, now(), null
from bullish_banana.firms f
join (values
  (
    'Daily (1-Step)', 'daily-1-step',
    'One-phase simulated Forex evaluation with a 10% target and a 5% trailing max-loss floor.',
    'evaluation', '[10000,25000,50000,100000]', 'Daily', true,
    '{
      "account_size_prices":[{"account_size":10000,"fee":89,"currency":"USD"},{"account_size":25000,"fee":149,"currency":"USD"},{"account_size":50000,"fee":249,"currency":"USD"},{"account_size":100000,"fee":429,"currency":"USD"}],
      "evaluation_rules":"One phase; target 10%; no daily loss limit; 5% trailing maximum loss recalculated at the 22:00 UTC close from closed balance, with live-equity breach checks; consistency limit is 40% of total realized profits for the evaluation only; unlimited time; 30-day inactivity rule.",
      "funded_rules":"80% reward share; 5% trailing max-loss continues and locks at starting balance; no funded consistency rule; no payout lock. Daily payout requests require profits above a 4% of initial balance buffer and, after the first payout cycle, at least 1% new-cycle profit. Request cap is 3% of initial account size; a full payout can be requested biweekly. $100 standard minimum.",
      "payout_frequency_detail":"Daily, subject to buffer/cycle rules; full payout biweekly.",
      "trading_rules":"Evaluation trading is not restricted around high-impact news. Funded/Live news window is 5 minutes before through 5 minutes after, on instruments tied to the event currency or country. FX leverage 1:100.",
      "fees_and_addons":"One-time list price. Official page displayed a 50% LAUNCH discount through 2026-09-30 11:59 p.m. EST on 2026-09-29; promotional amount excluded from base fee. Optional 90% reward-share add-on advertised at 25% of plan price.",
      "commissions":"Official pricing guide lists $3 per lot per side on Forex, metals and energies; swap rates are shown in MT5.",
      "verification_note":"Official account-size article and Daily guide reviewed 2026-09-29. Daily guide was marked updated in the last hour."
    }'
  ),
  (
    'Classic (2-Step)', 'classic-2-step',
    'Two-phase simulated Forex evaluation with 5% then 10% targets, a 3% daily limit and 10% static maximum loss.',
    'evaluation', '[5000,10000,25000,50000,100000]', 'Biweekly', true,
    '{
      "account_size_prices":[{"account_size":5000,"fee":55,"currency":"USD"},{"account_size":10000,"fee":109,"currency":"USD"},{"account_size":25000,"fee":249,"currency":"USD"},{"account_size":50000,"fee":419,"currency":"USD"},{"account_size":100000,"fee":749,"currency":"USD"}],
      "evaluation_rules":"Phase 1 target 5%; Phase 2 target 10%. Both phases have a 3% daily loss limit measured from a 22:00 UTC snapshot and 10% static maximum drawdown from starting balance. Breaches use live equity. Unlimited time; 30-day inactivity rule.",
      "funded_rules":"80% reward share; 3% daily and 10% static maximum loss. No funded consistency rule or minimum trading/profitable-day requirement before the first payout. No payout lock.",
      "payout_frequency_detail":"Biweekly; $100 standard minimum payout.",
      "trading_rules":"Evaluation trading is not restricted around high-impact news. Funded/Live news window is 5 minutes before through 5 minutes after, on instruments tied to the event currency or country. FX leverage 1:100.",
      "fees_and_addons":"One-time list price. Official page displayed a 50% LAUNCH discount through 2026-09-30 11:59 p.m. EST on 2026-09-29; promotional amount excluded from base fee. Optional 90% reward-share add-on advertised at 25% of plan price.",
      "commissions":"Official pricing guide lists $3 per lot per side on Forex, metals and energies; swap rates are shown in MT5.",
      "verification_note":"Official account-size article and Classic guide reviewed 2026-09-29. Classic guide was marked updated today."
    }'
  ),
  (
    'Direct (Instant Funding)', 'direct-instant-funding',
    'Instant simulated Forex funded account with no evaluation profit target, 3% daily loss, 6% trailing max loss and payout lock.',
    'instant_funding', '[5000,10000,25000,50000,100000]', 'On demand', false,
    '{
      "account_size_prices":[{"account_size":5000,"fee":85,"currency":"USD"},{"account_size":10000,"fee":119,"currency":"USD"},{"account_size":25000,"fee":209,"currency":"USD"},{"account_size":50000,"fee":579,"currency":"USD"},{"account_size":100000,"fee":999,"currency":"USD"}],
      "account_model":"No evaluation phases or profit target. Funded simulated account begins after purchase and required KYC/account setup.",
      "funded_rules":"80% reward share; 3% daily loss limit measured from daily snapshot; 6% trailing max drawdown recalculated at 22:00 UTC and capped/locked at starting balance; 20% best-day consistency rule applies to payout eligibility. The first payout request permanently locks the max-loss floor at starting balance. FX leverage 1:100.",
      "payout_frequency_detail":"On demand; $100 standard minimum. Payout requires KYC and consistency eligibility; no stated maximum.",
      "trading_rules":"Funded/Live news window is 5 minutes before through 5 minutes after high-impact news for instruments tied to event currency/country. Overnight/weekend holding is allowed subject to rules.",
      "fees_and_addons":"One-time list price. Official page displayed a 50% LAUNCH discount through 2026-09-30 11:59 p.m. EST on 2026-09-29; promotional amount excluded from base fee. Optional 90% reward-share add-on advertised at 25% of plan price.",
      "commissions":"Official pricing guide lists $3 per lot per side on Forex, metals and energies; swap rates are shown in MT5.",
      "verification_note":"Official account-size article and Direct guide reviewed 2026-09-29. Direct guide was marked updated today."
    }'
  )
) as x(name,slug,description,program_type,sizes,payout,news,details) on true
where f.slug='tradeify-fx'
on conflict (firm_id, slug) do update
set name=excluded.name, description=excluded.description, program_type=excluded.program_type,
    market_type=excluded.market_type, status='published', currency=excluded.currency,
    account_sizes=excluded.account_sizes, max_leverage=excluded.max_leverage,
    profit_split_percent=excluded.profit_split_percent, payout_frequency=excluded.payout_frequency,
    minimum_trading_days=excluded.minimum_trading_days, news_allowed=excluded.news_allowed,
    weekend_holding_allowed=excluded.weekend_holding_allowed,
    commercial_details=bullish_banana.programs.commercial_details || excluded.commercial_details,
    published_at=coalesce(bullish_banana.programs.published_at, now()), archived_at=null, updated_at=now();

insert into bullish_banana.program_platforms (program_id, platform_id)
select p.id, pl.id
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join bullish_banana.platforms pl on pl.slug='metatrader-5'
where f.slug='tradeify-fx'
on conflict (program_id, platform_id) do nothing;

insert into bullish_banana.affiliate_destinations (
  firm_id, program_id, kind, label, destination_url, is_primary, status
)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at Tradeify FX',
       'https://www.tradeifyfx.co/#pricing', true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id=f.id
where f.slug='tradeify-fx' and p.slug in ('daily-1-step','classic-2-step','direct-instant-funding')
and not exists (
  select 1 from bullish_banana.affiliate_destinations d
  where d.program_id=p.id and d.kind='official_site'
);

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, time_limit_days, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily, x.maximum, x.drawdown_type,
       null, null, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
  ('daily-1-step',1,'Evaluation',10::numeric,null::numeric,5::numeric,'trailing',
   '{"time_limit":"Unlimited; 30-day inactivity rule applies.","trailing_reference":"Closed balance recalculated at 22:00 UTC; cap at starting balance; breach check uses live equity.","consistency_percent":40,"consistency_applies_to":"Evaluation only"}'),
  ('classic-2-step',1,'Phase 1',5::numeric,3::numeric,10::numeric,'static',
   '{"time_limit":"Unlimited; 30-day inactivity rule applies.","daily_loss_reference":"22:00 UTC snapshot; live-equity breach check."}'),
  ('classic-2-step',2,'Phase 2',10::numeric,3::numeric,10::numeric,'static',
   '{"time_limit":"Unlimited; 30-day inactivity rule applies.","daily_loss_reference":"22:00 UTC snapshot; live-equity breach check."}')
) as x(program_slug,phase_number,name,target,daily,maximum,drawdown_type,rules)
  on x.program_slug=p.slug
where f.slug='tradeify-fx'
on conflict (program_id, phase_number) do update
set name=excluded.name, profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,
    drawdown_type=excluded.drawdown_type, time_limit_days=excluded.time_limit_days,
    minimum_trading_days=excluded.minimum_trading_days, raw_rules=excluded.raw_rules,
    updated_at=now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://www.tradeifyfx.co/','Official Tradeify FX homepage','Plan selector, instruments, platform, live promotional banner, simulated-account disclosures, payout overview and official company identity reviewed 2026-09-29.'),
  ('https://www.tradeifyfx.co/terms','Official Terms of Use','Last updated 2026-09-29; legal operator, US ineligibility, simulated-service terms and eligibility conditions.'),
  ('https://help.tradeifyfx.co/en/articles/16975771-account-sizes-and-pricing','Account sizes and pricing','Official base fee matrices for Daily, Classic and Direct, one-time billing, commissions and available add-on; updated 2026-09-29.'),
  ('https://help.tradeifyfx.co/en/articles/16975783-account-add-ons','Account add-ons','Official details for the optional 90% reward-share add-on.'),
  ('https://help.tradeifyfx.co/en/articles/16975953-daily-1-step-guide','Daily (1-Step) guide','Detailed evaluation and funded terms, size-target matrix, trailing floor, consistency, payout buffer and cycle rules; updated 2026-09-29.'),
  ('https://help.tradeifyfx.co/en/articles/16976039-classic-2-step-guide','Classic (2-Step) guide','Detailed evaluation/funded terms, phase targets, daily/static limits, payout schedule and account workflow; updated 2026-09-29.'),
  ('https://help.tradeifyfx.co/en/articles/16976051-direct-instant-funding-guide','Direct (Instant Funding) guide','No-evaluation account, daily/trailing limits, payout lock and 20% payout consistency details; updated 2026-09-29.'),
  ('https://help.tradeifyfx.co/en/articles/16976076-trading-rules-overview','Trading rules overview','Current prohibited conduct, news window, holding, EAs, own-account copying, inactivity and fair-play conditions; updated 2026-09-29.'),
  ('https://help.tradeifyfx.co/en/articles/16976062-the-live-program','The Live Program','Payout-count progression to the separate Live Program, reward-share ladder and payout terms.'),
  ('https://help.tradeifyfx.co/en/articles/17176535-trader-check-ins-kyt-and-fair-play','Trader check-ins, KYT and fair play','Current check-in and review conditions that may apply before funded activation.')
) as x(url,label,notes) on true
where f.slug='tradeify-fx'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
  ('daily-1-step','https://help.tradeifyfx.co/en/articles/16975953-daily-1-step-guide','Daily rules and payout guide','Core Daily rules, no time limit, 40% evaluation consistency, 4% payout buffer, daily/biweekly payout limits.'),
  ('classic-2-step','https://help.tradeifyfx.co/en/articles/16976039-classic-2-step-guide','Classic rules guide','Phase 1 5%, Phase 2 10%; 3% daily and 10% static limits in each phase.'),
  ('direct-instant-funding','https://help.tradeifyfx.co/en/articles/16976051-direct-instant-funding-guide','Direct funded-account guide','Instant funding; no target; 3% daily, 6% trailing loss, payout lock and 20% payout consistency.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='tradeify-fx'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id, notes)
select id, 'Official homepage, Help Center pricing/rule guides, and Terms of Use reviewed 2026-09-29. Base fees recorded; limited-time LAUNCH discount excluded.'
from bullish_banana.firms where slug='tradeify-fx';

insert into bullish_banana.data_verifications (program_id, notes)
select p.id, 'Official plan-specific guide and current pricing article reviewed 2026-09-29; limited-time LAUNCH discount excluded from base fee.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='tradeify-fx' and p.slug in ('daily-1-step','classic-2-step','direct-instant-funding');
