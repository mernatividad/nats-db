-- Add Audacity Capital's current Forex offers as review records.
-- First-party pages and interactive USD selector captured 2026-09-28.
-- Legal/provider, news-rule, and one-step size conflicts remain explicit.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.firms (name, slug, description, website_url, status, market_type)
values ('Audacity Capital', 'audacity-capital', 'Audacity Capital offers Forex evaluations and a direct-funded account program with size-dependent rules and rewards.', 'https://audacity.capital/', 'in_review', 'forex')
on conflict (slug) do update
set name = excluded.name, description = excluded.description, website_url = excluded.website_url,
    status = 'in_review', updated_at = now();

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'audacity-capital'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'KM', 'AudaCity Global LTD', array['Forex']::text[],
  '{"established_year":2012,"service_model_note":"Current legal footer describes simulated trading and skills assessment; product marketing also refers to live-funded accounts. Older Terms use legacy provider/program language, so legal operating model and offer-level contracting entity need reconciliation.","operator_disclosure":"Current footer names AudaCity Global LTD, registration 15850, licensed under International Brokerage and Clearing House Licence L15850/WL issued by the Union of Comoros, as trading operator. AudaCity International FZCO, Dubai Silicon Oasis, license DSO-FZCO 38282, is described as payment facilitator only. Propmetry Limited, Cyprus company HE469039, is an additional payment partner.","platforms_disclosed_at_firm_level":["MetaTrader 5","DXtrade"],"platform_scope_note":"Official offer pages name MT5 and DXtrade, but availability by offer, size, and country is not fully mapped. Current footer restricts U.S. residents to DXtrade where legally permitted.","instrument_scope_note":"Current per-offer instrument lists were not found. Older terms name major and minor Forex pairs and describe some instrument exclusions; confirm before presenting those legacy terms as current.","eligibility_note":"Knowledge Center states age 18+. Legal footer says service is unavailable where restricted or prohibited, explicitly including Syria, Iran, and North Korea; examples are not exhaustive. U.S. participation is limited to DXtrade where permitted.","account_size_note":"Current USD offer selector shows Ability Challenge $5K-$200K, Ability One $5K-$100K, and FTP $5K-$50K. Ability One product marketing/FAQ also refers to $200K; verify the unavailable $200K selector option before publication.","offer_scope_note":"Current paid Forex offers captured from interactive selector: Ability Challenge (2-step), Ability One (1-step), and FTP (direct-funded). Free Trial is not represented as a paid challenge."}'::jsonb
from bullish_banana.firms where slug = 'audacity-capital'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, market_type, status, currency,
  account_sizes, max_leverage, profit_split_percent, payout_frequency,
  minimum_trading_days, news_allowed, weekend_holding_allowed, commercial_details,
  published_at, archived_at
)
select f.id, p.name, p.slug, p.description, p.program_type, 'forex', 'in_review', 'USD',
       p.account_sizes::jsonb, null::numeric, p.profit_split_percent, p.payout_frequency,
       p.minimum_trading_days, true, true, p.commercial_details::jsonb, null, null
from bullish_banana.firms f
join (values
  ('Ability Challenge (2-Step)', 'ability-challenge-2-step', 'Two-phase Forex evaluation with 10% and 5% targets, static phase loss limits, and no time limit.', 'evaluation', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 75::numeric, 'Every 14 days', 4, '{"account_size_prices":[{"account_size":5000,"fee":42,"list_fee":49,"currency":"USD"},{"account_size":10000,"fee":68,"list_fee":79,"currency":"USD"},{"account_size":25000,"fee":168,"list_fee":195,"currency":"USD"},{"account_size":50000,"fee":283,"list_fee":329,"currency":"USD"},{"account_size":100000,"fee":472,"list_fee":549,"currency":"USD"},{"account_size":200000,"fee":902,"list_fee":1049,"currency":"USD"}],"pricing_capture":"Interactive official selector, USD, captured 2026-09-28. Displayed 14% discount; promotion end date not stated. GBP/EUR price tabs were not captured.","promotion_note":"Current selector displayed a 14% offer against the listed regular price on 2026-09-28. End date and ongoing eligibility were not stated; recheck at checkout.","payout_rules":"First funded-phase request is available 14 days after the first live-phase trade; following requests are biweekly. Reward share starts at 75%; the official Knowledge Center describes 85% when profit exceeds 10% within 30 days and up to 90% after scaling milestones. Marketing advertises a fee refund up to 100% with a qualifying first payout, while the Terms say fees are non-refundable after service begins; benefit wording and eligibility need reconciliation.","fee_refund_policy":"Conflicting wording: product marketing advertises up to 100% fee refund with the first qualifying payout, while Terms state registration fees are non-refundable after service starts. Keep in review and do not state an unconditional refund.","news_weekend_note":"Current product marketing says news trading and weekend holding are allowed subject to rules. Older Terms include event restrictions; confirm the currently binding rule before publication.","ea_rule":"Current product FAQ says EAs are allowed subject to program rules; exact personal/commercial EA restrictions were not established for this offer.","copy_trading_rule":"Current product FAQ says copy trading is allowed subject to program rules; exact account-source and third-party restrictions were not established for this offer.","commission_details":"Offer-specific Forex commission, spreads, swaps, and leverage were not stated in the reviewed current sources.","prohibited_strategies":"Official prohibited-practices policy identifies HFT/latency arbitrage and manipulative or toxic trading as prohibited. Program-specific additional restrictions need confirmation.","offer_conflicts":"Older Terms contain provider/program language that does not align cleanly with the current legal footer and current marketing description of simulated versus live-funded services."}'),
  ('Ability One (1-Step)', 'ability-one-1-step', 'Single-phase Forex evaluation with a 10% target, 3% daily drawdown, and 6% static maximum loss.', 'evaluation', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"}]', 75::numeric, 'Every 14 days', 3, '{"account_size_prices":[{"account_size":5000,"fee":59,"list_fee":69,"currency":"USD"},{"account_size":10000,"fee":85,"list_fee":99,"currency":"USD"},{"account_size":25000,"fee":214,"list_fee":249,"currency":"USD"},{"account_size":50000,"fee":343,"list_fee":399,"currency":"USD"},{"account_size":100000,"fee":601,"list_fee":699,"currency":"USD"}],"pricing_capture":"Interactive official Ability One selector, USD, captured 2026-09-28. Displayed 14% discount. Selector choices ended at $100K, despite product marketing/FAQ references to a $200K maximum. Promotion end date not stated; GBP/EUR tabs not captured.","promotion_note":"Current selector displayed a 14% offer against the listed regular price on 2026-09-28. End date and ongoing eligibility were not stated; recheck at checkout.","payout_rules":"First funded-phase request is available 14 days after the first funded-phase trade; subsequent requests are biweekly. Reward share starts at 75%; the official Knowledge Center describes 85% when profits reach 10% and up to 90% under the scaling plan.","fee_refund_policy":"Knowledge Center calls the first-payment benefit a reward bonus equal to the initial registration fee; older Terms state fees are non-refundable after service starts. This is not recorded as an unconditional fee refund.","news_weekend_note":"Current product page allows news trading and weekend holding, subject to trading conditions. Older Terms contain event restrictions; verify the current binding rule.","ea_rule":"Personally developed EAs are permitted; third-party or commercial EAs are not allowed, per current Ability One product rules.","copy_trading_rule":"The current product page advertises copy trading as allowed; exact account-source conditions were not established for Ability One.","commission_details":"Offer-specific Forex commission, spreads, swaps, and leverage were not stated in the reviewed current sources.","prohibited_strategies":"Official prohibited-practices policy identifies HFT/latency arbitrage and manipulative or toxic trading as prohibited. Program-specific additional restrictions need confirmation.","offer_conflicts":"Live selector lists initial account choices only through $100K, while Ability One product marketing and FAQ refer to a $200K program cap. Older Terms also contain legacy provider/program language."}'),
  ('FTP (Instant Funding)', 'ftp-instant-funding', 'Direct-funded Forex account with no evaluation phase; payout eligibility and scaling depend on a 10% milestone.', 'instant_funding', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"}]', 50::numeric, 'Milestone-based; every 10% profit milestone', 5, '{"account_size_prices":[{"account_size":5000,"fee":102,"list_fee":119,"currency":"USD"},{"account_size":10000,"fee":240,"list_fee":279,"currency":"USD"},{"account_size":25000,"fee":386,"list_fee":449,"currency":"USD"},{"account_size":50000,"fee":1117,"list_fee":1299,"currency":"USD"}],"pricing_capture":"Interactive official FTP selector, USD, captured 2026-09-28. Displayed 14% discount. Promotion end date not stated; GBP/EUR tabs not captured.","promotion_note":"Current selector displayed a 14% offer against the listed regular price on 2026-09-28. End date and ongoing eligibility were not stated; recheck at checkout.","payout_rules":"No evaluation is required to access the account. Payout eligibility is described at a 10% profit milestone after at least five trading days; the risk review is described as taking 1-3 working days. Reward share varies by account size, scaling stage, and time to milestone, with official schedules between 50% and 80%. The milestone is for payout/scaling, not a challenge pass target.","direct_funding_note":"Direct-funded from purchase, without a challenge or verification phase. The 10% profit milestone is a payout/scaling condition only. Daily drawdown is 5% trailing from the highest recorded equity during each day and resets at 00:00 MT5 server time; the 10% maximum total drawdown is a static hard floor from starting balance.","commission_details":"Knowledge Center states FTP accounts are commission-free. Offer-specific leverage and full spread/swap costs were not stated in the reviewed current sources.","news_weekend_note":"Current product marketing permits news trading and weekend holding. Older Terms describe event restrictions; confirm the currently binding rule before publication.","ea_rule":"Current FTP rules allow personally developed EAs; third-party/commercial EAs are not allowed.","copy_trading_rule":"Copy trading is allowed between the trader''s own accounts under program rules; do not imply unrestricted third-party copying.","prohibited_strategies":"Official prohibited-practices policy identifies HFT/latency arbitrage and manipulative or toxic trading as prohibited. Program-specific additional restrictions need confirmation.","offer_conflicts":"Current marketing calls FTP immediate funded access and states up to 80% rewards; the Knowledge Center makes clear that 10% milestones and five trading days govern payouts/scaling. Older Terms contain event restrictions and legacy provider/program language."}')
) as p(name, slug, description, program_type, account_sizes, profit_split_percent, payout_frequency, minimum_trading_days, commercial_details) on true
where f.slug = 'audacity-capital'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    market_type = excluded.market_type, status = 'in_review', currency = excluded.currency,
    account_sizes = excluded.account_sizes, max_leverage = excluded.max_leverage,
    profit_split_percent = excluded.profit_split_percent, payout_frequency = excluded.payout_frequency,
    minimum_trading_days = excluded.minimum_trading_days, news_allowed = excluded.news_allowed,
    weekend_holding_allowed = excluded.weekend_holding_allowed,
    commercial_details = excluded.commercial_details, archived_at = null, published_at = null,
    updated_at = now();

insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.maximum_loss,
       x.drawdown_type, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('ability-challenge-2-step', 1, 'Challenge', 10.000::numeric, 7.500::numeric, 15.000::numeric, 'static', 4, '{"time_limit":"unlimited","daily_reset":"00:00 MT5 server time; seasonal GMT+2/GMT+3","daily_limit_basis":"higher of balance or equity at rollover; threshold fixed for the day","maximum_limit_basis":"static against initial balance; equity inclusive of open and closed positions, commission and swaps","source_note":"Official Ability Challenge rules and Knowledge Center captured 2026-09-28."}'),
  ('ability-challenge-2-step', 2, 'Verification', 5.000::numeric, 5.000::numeric, 10.000::numeric, 'static', 4, '{"time_limit":"unlimited","daily_reset":"00:00 MT5 server time; seasonal GMT+2/GMT+3","daily_limit_basis":"higher of balance or equity at rollover; threshold fixed for the day","maximum_limit_basis":"static against initial balance; equity inclusive of open and closed positions, commission and swaps","source_note":"Official Ability Challenge rules and Knowledge Center captured 2026-09-28."}'),
  ('ability-one-1-step', 1, 'Challenge', 10.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 3, '{"time_limit":"unlimited","daily_reset":"midnight MT5 server time; seasonal GMT+2/GMT+3","daily_limit_basis":"higher of balance or equity at rollover","maximum_limit_basis":"static against initial account balance","source_note":"Official Ability One rules and Knowledge Center captured 2026-09-28."}'),
  ('ftp-instant-funding', 1, 'Funded account rules', null::numeric, 5.000::numeric, 10.000::numeric, 'daily trailing; maximum static', 5, '{"evaluation":"none","payout_milestone_percent":10,"minimum_trading_days_before_payout":5,"time_limit":"unlimited","daily_drawdown_basis":"trailing from highest recorded equity during the day; floor does not move back down when equity declines","daily_reset":"00:00 MT5 server time","maximum_drawdown_basis":"static lifetime floor from starting balance","source_note":"Official FTP product and Knowledge Center captured 2026-09-28; 10% is a payout/scaling milestone, not an entry evaluation target."}')
) as x(program_slug, phase_number, name, target, daily_loss, maximum_loss, drawdown_type, days, rules)
  on x.program_slug = p.slug
where f.slug = 'audacity-capital'
on conflict (program_id, phase_number) do update
set name = excluded.name, profit_target_percent = excluded.profit_target_percent,
    daily_drawdown_percent = excluded.daily_drawdown_percent,
    maximum_drawdown_percent = excluded.maximum_drawdown_percent,
    drawdown_type = excluded.drawdown_type, minimum_trading_days = excluded.minimum_trading_days,
    raw_rules = excluded.raw_rules, updated_at = now();

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, x.url, x.label, x.notes
from bullish_banana.firms f
join (values
  ('https://audacity.capital/', 'Audacity Capital official site and legal disclosure', 'Current legal footer identifies operator, payment facilitator, licensing disclosure, simulated-service framing, jurisdiction notes and U.S.-via-DXtrade condition. Captured 2026-09-28.'),
  ('https://audacity.capital/about/', 'Audacity Capital About page', 'Official company background; the site states operations since 2012. Captured 2026-09-28.'),
  ('https://audacity.capital/terms-and-conditions/', 'Audacity Capital Terms and Conditions', 'First-party terms include older provider/program wording and fee/event language that conflict with or are not fully reconciled to current product pages and footer. Retained as an explicit review source.'),
  ('https://audacity.capital/prohibited-trading-practices/', 'Audacity Capital prohibited trading practices', 'First-party prohibited-strategy policy includes HFT/latency arbitrage and manipulative or toxic trading. Captured 2026-09-28.'),
  ('https://audacity.capital/trading-platforms/', 'Audacity Capital trading platforms', 'Official platform list; exact availability by offer, account size, and region needs confirmation.'),
  ('https://audacity.capital/knowledge-center/getting-started/', 'Audacity Capital getting-started Knowledge Center', 'First-party account sizes, age eligibility, platform and payment/refund information. Account-size statements conflict with the Ability One live selector.'),
  ('https://audacity.capital/two-step-prop-firm-ability-challenge/', 'Ability Challenge (2-Step) product page and live selector', 'Live USD account-size choices and displayed promotional/regular price pairs; current product-level marketing terms. Captured 2026-09-28.'),
  ('https://audacity.capital/one-step-prop-firm-ability-one/', 'Ability One (1-Step) product page and live selector', 'Live USD selector displayed sizes through $100K, while product marketing/FAQ refer to $200K. Captured 2026-09-28.'),
  ('https://audacity.capital/instant-funding-prop-firm/', 'FTP instant-funding product page and live selector', 'Live USD size and price options; page describes direct-funded access, news/weekend holding, EAs/copy trading and up to 80% reward share. Captured 2026-09-28.'),
  ('https://audacity.capital/knowledge-center/ftp/', 'FTP rules and payout Knowledge Center', 'Detailed 5% daily trailing and 10% static maximum drawdown, 10% payout milestone, five trading-day minimum, stage/size-dependent split, commission and EA/copy rules. Captured 2026-09-28.')
) as x(url, label, notes) on true
where f.slug = 'audacity-capital'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('ability-challenge-2-step', 'https://audacity.capital/two-step-prop-firm-ability-challenge/', 'Ability Challenge product and selector', 'Current 2-step Forex offer, selector sizes and USD sale/list prices; promotion end date not stated. Captured 2026-09-28.'),
  ('ability-challenge-2-step', 'https://audacity.capital/knowledge-center/ability-challenge/', 'Ability Challenge detailed rules and payouts', 'Phase objectives, static total and daily loss mechanics, minimum days, payout timing/splits, fee benefit, and news/weekend/EA/copy statements. Captured 2026-09-28.'),
  ('ability-one-1-step', 'https://audacity.capital/one-step-prop-firm-ability-one/', 'Ability One product and selector', 'Current 1-step Forex offer, selector sizes and USD sale/list prices; selector stops at $100K while marketing/FAQ cite a $200K cap. Captured 2026-09-28.'),
  ('ability-one-1-step', 'https://audacity.capital/knowledge-center/ability-one/', 'Ability One detailed rules and payouts', '10% target, 3% daily limit, 6% static maximum, minimum days, reset, payout steps, conditional reward bonus and personally developed EA restrictions. Captured 2026-09-28.'),
  ('ftp-instant-funding', 'https://audacity.capital/instant-funding-prop-firm/', 'FTP instant-funding product and selector', 'Direct-funded offer, selected USD sizes/prices, public news/weekend and strategy statements. Captured 2026-09-28.'),
  ('ftp-instant-funding', 'https://audacity.capital/knowledge-center/ftp/', 'FTP detailed rules and payout schedule', 'No evaluation; 5% daily trailing and 10% static hard floor; five days and 10% milestone for payout; size/stage/time-varying split; zero commission; EA/copy limitations. Captured 2026-09-28.'),
  ('ftp-instant-funding', 'https://audacity.capital/terms-and-conditions/', 'FTP terms conflict review', 'Older Terms include major-event restrictions and legacy provider/program wording that do not align cleanly with current product marketing. Captured 2026-09-28.'),
  ('ability-challenge-2-step', 'https://audacity.capital/terms-and-conditions/', 'Ability Challenge fee benefit conflict', 'Current marketing advertises a conditional fee refund, while the Terms say registration fees are non-refundable after service starts. Captured 2026-09-28.'),
  ('ability-one-1-step', 'https://audacity.capital/terms-and-conditions/', 'Ability One reward benefit conflict', 'Knowledge Center describes a first-payout reward bonus equal to the registration fee; Terms say fees are non-refundable after service starts. Captured 2026-09-28.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'audacity-capital'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url and s.source_label = x.label);

insert into bullish_banana.restrictions (firm_id, country_code, restriction_type, note)
select f.id, x.country_code, 'restricted', x.note
from bullish_banana.firms f
join (values
  ('SY', 'Current legal footer explicitly names Syria as unavailable; the list is stated to be non-exhaustive.'),
  ('IR', 'Current legal footer explicitly names Iran as unavailable; the list is stated to be non-exhaustive.'),
  ('KP', 'Current legal footer explicitly names North Korea as unavailable; the list is stated to be non-exhaustive.'),
  ('US', 'Conditional access only: current legal footer says U.S. residents may participate via DXtrade where permitted. This is not an unrestricted country approval.')
) as x(country_code, note) on true
where f.slug = 'audacity-capital'
on conflict (firm_id, country_code) do update
set restriction_type = excluded.restriction_type, note = excluded.note, updated_at = now();

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select id, now(), 'Current legal/footer disclosures, firm identity, operating and payment entities, platforms, eligibility, and restrictions reviewed against first-party sources on 2026-09-28. The firm remains in review for current-versus-legacy Terms conflicts.'
from bullish_banana.firms f
where slug = 'audacity-capital'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Current offer existence, interactive USD size/price schedule, program rules, and official source trail checked on 2026-09-28. GBP/EUR schedules were not captured. Program remains in review for listed legal/offer conflicts; no unsupported values were inferred.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'audacity-capital'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at Audacity Capital', x.destination_url, true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
join (values
  ('ability-challenge-2-step', 'https://audacity.capital/two-step-prop-firm-ability-challenge/'),
  ('ability-one-1-step', 'https://audacity.capital/one-step-prop-firm-ability-one/'),
  ('ftp-instant-funding', 'https://audacity.capital/instant-funding-prop-firm/')
) as x(program_slug, destination_url) on x.program_slug = p.slug
where f.slug = 'audacity-capital'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
