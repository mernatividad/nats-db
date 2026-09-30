-- Refresh FundedElite from its public challenge selector and first-party help pages.
-- Captured 2026-09-28. The selector returned 49 enabled account templates across
-- seven fixed offer families. A Custom Challenge builder is also advertised but is
-- not represented by a fixed template; it is retained as an in-review offer family.
-- Do not publish until checkout variants and conflicts with older FAQ pages are reconciled.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firms
set name = 'FundedElite',
    description = 'FundedElite offers simulated Forex evaluation, instant funding, activation, and customizable challenge products.',
    website_url = 'https://fundedelite.com/',
    status = 'published', published_at = coalesce(published_at, now()), archived_at = null, updated_at = now()
where slug = 'fundedelite';

insert into bullish_banana.firm_markets (firm_id, market_type)
select id, 'forex' from bullish_banana.firms where slug = 'fundedelite'
on conflict (firm_id, market_type) do nothing;

insert into bullish_banana.firm_profiles (firm_id, country_code, legal_entity_name, supported_assets, profile_details)
select id, 'IT', 'Quantum SRL', array['Forex']::text[],
  '{"service_model":"Simulated trading accounts; challenge and funded-account rules vary by product and selected options.","headquarters_country":"Italy","entity_note":"FundedElite terms identify Quantum SRL, Italy, trading as Funded Elite. Confirm whether the entity named in the terms is the contracting entity for every current offer."}'::jsonb
from bullish_banana.firms where slug = 'fundedelite'
on conflict (firm_id) do update
set country_code = excluded.country_code, legal_entity_name = excluded.legal_entity_name,
    supported_assets = excluded.supported_assets,
    profile_details = bullish_banana.firm_profiles.profile_details || excluded.profile_details,
    updated_at = now();

insert into bullish_banana.programs (
  firm_id, name, slug, description, program_type, status, currency, account_sizes,
  max_leverage, profit_split_percent, payout_frequency, minimum_trading_days,
  commercial_details, published_at, archived_at
)
select f.id, p.name, p.slug, p.description, p.program_type, 'in_review', 'USD', p.account_sizes::jsonb,
       p.max_leverage, p.profit_split_percent, p.payout_frequency, p.minimum_trading_days,
       p.commercial_details::jsonb, null, null
from bullish_banana.firms f
join (values
  ('Lite 1-Step', 'lite-1-step', 'Single-phase Forex evaluation. The current public selector lists eight account sizes and a configurable rule set.', 'evaluation', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 5, '{"account_size_prices":[{"account_size":5000,"fee":49,"currency":"USD"},{"account_size":10000,"fee":65,"currency":"USD"},{"account_size":15000,"fee":69,"currency":"USD"},{"account_size":25000,"fee":109,"currency":"USD"},{"account_size":50000,"fee":229,"currency":"USD"},{"account_size":100000,"fee":369,"currency":"USD"},{"account_size":200000,"fee":729,"currency":"USD"},{"account_size":300000,"fee":1099,"currency":"USD"}],"current_promotion":{"code":"NEW50","displayed_discount_percent":50,"captured_on":"2026-09-28","note":"Selector displayed 50% off eligible new-user purchases; availability may change."},"base_rules":{"phase_one_target_percent":10,"daily_loss_percent":3,"maximum_loss_percent":6,"drawdown":"static","funded_minimum_profitable_days":3,"default_profit_split_percent":80,"default_payout_days":14},"configurable_options":{"maximum_loss_percent":[5,6,7,8,10],"phase_one_target_percent":[8,10,12],"profit_split_percent":[60,70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100],"weekend_trading":"Optional paid variant; verify selected checkout configuration.","scalping":"Optional paid variant; exact current restrictions require checkout confirmation."},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. Values are default template configurations and vary by account size/options."}'),
  ('Lite 2-Step', 'lite-2-step', 'Two-phase Forex evaluation with a 5% Phase 2 target. The current public selector lists eight account sizes and configurable rule variants.', 'evaluation', '[{"account_size":5000,"currency":"USD"},{"account_size":10000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 5, '{"account_size_prices":[{"account_size":5000,"fee":39,"currency":"USD"},{"account_size":10000,"fee":55,"currency":"USD"},{"account_size":15000,"fee":59,"currency":"USD"},{"account_size":25000,"fee":89,"currency":"USD"},{"account_size":50000,"fee":199,"currency":"USD"},{"account_size":100000,"fee":299,"currency":"USD"},{"account_size":200000,"fee":589,"currency":"USD"},{"account_size":300000,"fee":899,"currency":"USD"}],"current_promotion":{"code":"NEW50","displayed_discount_percent":50,"captured_on":"2026-09-28","note":"Selector displayed 50% off eligible new-user purchases; availability may change."},"base_rules":{"phase_one_target_percent":8,"phase_two_target_percent":5,"daily_loss_percent":4,"maximum_loss_percent":8,"drawdown":"static","minimum_trading_days_per_phase":5,"default_profit_split_percent":80,"default_payout_days":14},"configurable_options":{"maximum_loss_percent":[6,8,10],"phase_one_target_percent":[6,7,8,10,12],"profit_split_percent":[60,70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100],"weekend_trading":"Optional paid variant; verify selected checkout configuration.","scalping":"Optional paid variant; exact current restrictions require checkout confirmation."},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. This current selector configuration differs from the older FAQ minimum-day description; verify the live purchase flow before publication."}'),
  ('1-Step + Free Retry', '1-step-free-retry', 'Single-phase Forex evaluation with a free retry and a second-chance account path.', 'evaluation', '[{"account_size":7000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 5, '{"account_size_prices":[{"account_size":7000,"fee":95,"currency":"USD"},{"account_size":15000,"fee":130,"currency":"USD"},{"account_size":25000,"fee":225,"currency":"USD"},{"account_size":50000,"fee":329,"currency":"USD"},{"account_size":100000,"fee":569,"currency":"USD"},{"account_size":200000,"fee":1085,"currency":"USD"},{"account_size":300000,"fee":1599,"currency":"USD"}],"current_promotion":{"code":"NEW50","displayed_discount_percent":50,"captured_on":"2026-09-28","note":"Selector displayed 50% off eligible new-user purchases; availability may change."},"base_rules":{"phase_one_target_percent":10,"daily_loss_percent":3,"maximum_loss_percent":8,"drawdown":"static","minimum_trading_days":5,"default_profit_split_percent":80,"default_payout_days":14},"retry_rules":{"included_second_chance":true,"second_chance_default_split_percent":50,"second_chance_minimum_profitable_days":3,"reset_fee_note":"Checkout shows paid resets after the included retry; exact reset schedule is account-specific."},"configurable_options":{"maximum_loss_percent":[5,6,8,10],"phase_one_target_percent":[8,10,12],"profit_split_percent":[60,70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100]},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. Current size-specific default templates; second-chance rules are represented separately from the initial evaluation."}'),
  ('2-Step + Free Retry', '2-step-free-retry', 'Two-phase Forex evaluation with an included retry and a second-chance account path.', 'evaluation', '[{"account_size":7000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days', 5, '{"account_size_prices":[{"account_size":7000,"fee":89,"currency":"USD"},{"account_size":15000,"fee":129,"currency":"USD"},{"account_size":25000,"fee":219,"currency":"USD"},{"account_size":50000,"fee":329,"currency":"USD"},{"account_size":100000,"fee":519,"currency":"USD"},{"account_size":200000,"fee":989,"currency":"USD"},{"account_size":300000,"fee":1499,"currency":"USD"}],"current_promotion":{"code":"NEW50","displayed_discount_percent":50,"captured_on":"2026-09-28","note":"Selector displayed 50% off eligible new-user purchases; availability may change."},"base_rules":{"phase_one_target_percent":8,"phase_two_target_percent":5,"daily_loss_percent":5,"maximum_loss_percent":8,"drawdown":"static","minimum_trading_days_per_phase":5,"default_profit_split_percent":80,"default_payout_days":14},"retry_rules":{"included_second_chance":true,"second_chance_default_daily_loss_percent":3,"second_chance_default_profit_split_percent":50,"second_chance_minimum_profitable_days":3,"reset_fee_note":"Checkout shows paid resets after the included retry; exact reset schedule is account-specific."},"configurable_options":{"maximum_loss_percent":[5,6,8,9,10],"phase_one_target_percent":[6,7,8,10,12],"profit_split_percent":[60,70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100]},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. Current size-specific default templates; some older FAQ variants state different trading-day requirements."}'),
  ('Instant Funding', 'instant-funding', 'Immediate simulated Forex funding with no evaluation phase.', 'instant_funding', '[{"account_size":7000,"currency":"USD"},{"account_size":15000,"currency":"USD"},{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"}]', 30::numeric, 70::numeric, 'Every 21 days by default; configurable', 4, '{"account_size_prices":[{"account_size":7000,"fee":120,"currency":"USD"},{"account_size":15000,"fee":150,"currency":"USD"},{"account_size":25000,"fee":190,"currency":"USD"},{"account_size":50000,"fee":390,"currency":"USD"},{"account_size":100000,"fee":890,"currency":"USD"},{"account_size":200000,"fee":1690,"currency":"USD"}],"current_promotion":{"code":"NEW50","displayed_discount_percent":50,"captured_on":"2026-09-28","note":"Selector displayed 50% off eligible new-user purchases; availability may change."},"base_rules":{"daily_loss_percent":3,"maximum_loss_percent":6,"drawdown":"trailing equity","minimum_profitable_days":4,"consistency_percent":25,"default_profit_split_percent":70,"payout_days":[3,7,14,21]},"configurable_options":{"profit_split_percent":[70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100]},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. $200K option appears in the current selector although older Help Center text describes lower caps; verify account availability before publication."}'),
  ('Instant Elite', 'instant-elite', 'Immediate simulated Forex funding under the Elite rule set, with no evaluation phase.', 'instant_funding', '[{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"},{"account_size":400000,"currency":"USD"}]', 30::numeric, 70::numeric, 'Every 21 days by default; configurable', 4, '{"account_size_prices":[{"account_size":50000,"fee":890,"currency":"USD"},{"account_size":100000,"fee":1490,"currency":"USD"},{"account_size":200000,"fee":2600,"currency":"USD"},{"account_size":300000,"fee":3900,"currency":"USD"},{"account_size":400000,"fee":5200,"currency":"USD"}],"current_promotions":[{"code":"NEW50","displayed_discount_percent":50,"eligible_sizes":[50000,100000,200000],"captured_on":"2026-09-28"},{"code":"ELITE50","displayed_discount_percent":50,"eligible_sizes":[300000,400000],"captured_on":"2026-09-28"}],"base_rules":{"daily_loss_percent":3,"maximum_loss_percent":6,"drawdown":"trailing equity","minimum_profitable_days":4,"default_profit_split_percent":70,"payout_days":[3,7,14,21]},"configurable_options":{"profit_split_percent":[70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100]},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. This $400K maximum conflicts with older public marketing descriptions; confirm active checkout sizes before publication."}'),
  ('Flash Activation', 'flash-activation', 'Single-phase simulated Forex evaluation with a $5 entry price and a separate post-pass activation charge.', 'evaluation', '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"},{"account_size":100000,"currency":"USD"},{"account_size":200000,"currency":"USD"},{"account_size":300000,"currency":"USD"},{"account_size":400000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days by default; configurable', 0, '{"account_size_prices":[{"account_size":25000,"fee":5,"activation_fee":159,"currency":"USD"},{"account_size":50000,"fee":5,"activation_fee":329,"currency":"USD"},{"account_size":100000,"fee":5,"activation_fee":499,"currency":"USD"},{"account_size":200000,"fee":5,"activation_fee":989,"currency":"USD"},{"account_size":300000,"fee":5,"activation_fee":1499,"currency":"USD"},{"account_size":400000,"fee":5,"activation_fee":1999,"currency":"USD"}],"current_promotion":{"code":"FLASH5","description":"Buy 1 Get 4 Free","captured_on":"2026-09-28","note":"Promotion is checkout-controlled and may change."},"base_rules":{"phase_one_target_percent":6,"daily_loss_percent":3,"maximum_loss_percent":6,"drawdown":"static in evaluation; trailing equity after funding","evaluation_minimum_trading_days":0,"funded_minimum_profitable_days":3,"default_profit_split_percent":80,"default_payout_days":14,"consistency_percent":30},"configurable_options":{"phase_one_target_percent":[2,3,4,5,6],"maximum_loss_percent":[6,8,10],"profit_split_percent":[60,70,80,95],"payout_days":[3,7,14,21],"leverage":[30,50,100],"weekend_trading":"Optional paid variant.","scalping":"Optional paid variant; confirm restrictions in checkout."},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. Current selector includes $300K and $400K sizes; older Help Center articles describe a smaller range."}'),
  ('Catalyst', 'catalyst', 'Direct-funded simulated Forex accounts with payout-stage scaling and increasing profit share.', 'funded_account', '[{"account_size":25000,"currency":"USD"},{"account_size":50000,"currency":"USD"}]', 30::numeric, 80::numeric, 'Every 14 days initially; stage schedule varies', 5, '{"account_size_prices":[{"account_size":25000,"fee":499,"currency":"USD"},{"account_size":50000,"fee":899,"currency":"USD"}],"current_promotion":{"code":"NEW50","displayed_discount_percent":50,"captured_on":"2026-09-28","note":"Displayed promotion may change."},"scaling_ladders":{"25000_start":[25000,50000,100000,200000,400000,800000,1000000],"50000_start":[50000,100000,200000,400000,800000,1000000]},"base_rules":{"profit_target_percent_per_stage":8,"daily_loss_percent":3,"initial_maximum_loss_percent":6,"later_stage_maximum_loss_percent":5,"minimum_profitable_days_per_stage":5,"profit_split_percent_increases_by_stage":[80,85,90,95],"payout_days_initial":14,"later_payout_days":7},"selector_capture":"Public first-party app.fundedelite.com challenge-template selector, 2026-09-28. This ladder is a series of funded stages, not an evaluation phase sequence; the dedicated public page displays the current selected stage."}'),
  ('Custom Challenge', 'custom-challenge', 'Officially advertised configurable Forex challenge builder. The public pages do not expose one fixed price, size, or rule set.', 'other', '[]', null::numeric, null::numeric, null, null, '{"availability":"Advertised on the first-party challenges page; no fixed challenge template was returned by the public selector response captured on 2026-09-28.","details":"User-selected account size, targets, loss limits, payouts, leverage, and profit split; capture a representative completed checkout before publishing specific terms."}')
) as p(name, slug, description, program_type, account_sizes, max_leverage, profit_split_percent, payout_frequency, minimum_trading_days, commercial_details) on true
where f.slug = 'fundedelite'
on conflict (firm_id, slug) do update
set name = excluded.name, description = excluded.description, program_type = excluded.program_type,
    status = 'in_review', currency = excluded.currency, account_sizes = excluded.account_sizes,
    max_leverage = excluded.max_leverage, profit_split_percent = excluded.profit_split_percent,
    payout_frequency = excluded.payout_frequency, minimum_trading_days = excluded.minimum_trading_days,
    commercial_details = excluded.commercial_details, published_at = null, archived_at = null, updated_at = now();

-- Only evaluation targets appear as phases. Instant accounts and Catalyst's funded-stage
-- progression are described separately in commercial_details to avoid inventing phases.
insert into bullish_banana.program_phases (
  program_id, phase_number, name, profit_target_percent, daily_drawdown_percent,
  maximum_drawdown_percent, drawdown_type, minimum_trading_days, raw_rules
)
select p.id, x.phase_number, x.name, x.target, x.daily_loss, x.maximum_loss, x.drawdown_type, x.days, x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('lite-1-step', 1, 'Evaluation', 10.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 5, '{"source_note":"Current public size template defaults; configurable target and maximum-loss variants are also offered."}'),
  ('lite-2-step', 1, 'Phase 1', 8.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 5, '{"source_note":"Current public size template default. This differs from the older FAQ minimum-day description; verify checkout before publication."}'),
  ('lite-2-step', 2, 'Phase 2', 5.000::numeric, 4.000::numeric, 8.000::numeric, 'static', 5, '{"source_note":"Current public size template default. This differs from the older FAQ minimum-day description; verify checkout before publication."}'),
  ('1-step-free-retry', 1, 'Evaluation', 10.000::numeric, 3.000::numeric, 8.000::numeric, 'static', 5, '{"source_note":"Initial account default; included retry and second-chance path have separate terms in commercial details."}'),
  ('2-step-free-retry', 1, 'Phase 1', 8.000::numeric, 5.000::numeric, 8.000::numeric, 'static', 5, '{"source_note":"Initial account default; included retry and second-chance path have separate terms in commercial details."}'),
  ('2-step-free-retry', 2, 'Phase 2', 5.000::numeric, 5.000::numeric, 8.000::numeric, 'static', 5, '{"source_note":"Initial account default; included retry and second-chance path have separate terms in commercial details."}'),
  ('flash-activation', 1, 'Evaluation', 6.000::numeric, 3.000::numeric, 6.000::numeric, 'static', 0, '{"source_note":"Current public size template default; target, drawdown, payout, split, leverage and add-on variants are selectable."}')
) as x(program_slug, phase_number, name, target, daily_loss, maximum_loss, drawdown_type, days, rules)
  on x.program_slug = p.slug
where f.slug = 'fundedelite'
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
  ('https://fundedelite.com/challenges', 'FundedElite Challenges', 'Official product navigation and currently marketed challenge families; the page and Help Center do not fully align.'),
  ('https://faq.fundedelite.com/en/collections/18316559-all-our-challenges', 'FundedElite Help Center: Challenges', 'First-party product articles for Lite, Instant, Flash Activation, Free Retry, and related challenge rules; some articles may describe legacy terms.'),
  ('https://fundedelite.com/terms-and-conditions', 'FundedElite Terms and Conditions', 'First-party terms identify Quantum SRL in Italy trading as Funded Elite; verify applicability to every current offer.')
) as x(url, label, notes) on true
where f.slug = 'fundedelite'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = x.url);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('lite-1-step', 'https://fundedelite.com/challenges/lite-account', 'FundedElite Lite Account', 'Official Lite overview plus public size-specific challenge-template data captured 2026-09-28.'),
  ('lite-2-step', 'https://faq.fundedelite.com/en/articles/12683646-lite-2-step-challenge', 'FundedElite Lite 2-Step FAQ', 'Official FAQ describes configurable rules; public size-specific challenge-template defaults were also captured 2026-09-28 and conflict on minimum days.'),
  ('1-step-free-retry', 'https://fundedelite.com/challenges/free-retry', 'FundedElite Free Retry', 'Official product page and public size-specific challenge-template data captured 2026-09-28.'),
  ('2-step-free-retry', 'https://faq.fundedelite.com/en/articles/12683646-lite-2-step-challenge', 'FundedElite Free Retry / Challenge FAQ', 'First-party FAQ for current and legacy rules; public selector response contains size-specific retry templates.'),
  ('instant-funding', 'https://fundedelite.com/challenges/instant-funding', 'FundedElite Instant Funding', 'Official product page plus public size-specific challenge-template data captured 2026-09-28; selector sizes exceed some older FAQ descriptions.'),
  ('instant-elite', 'https://fundedelite.com/challenges/instant-funding', 'FundedElite Instant Elite', 'Official product page plus public size-specific challenge-template data captured 2026-09-28; confirm maximum available size in live checkout.'),
  ('flash-activation', 'https://fundedelite.com/challenges/flash-activation', 'FundedElite Flash Activation', 'Official product page plus public size-specific challenge-template data captured 2026-09-28; selector sizes exceed older FAQ descriptions.'),
  ('catalyst', 'https://www.fundedelite.com/catalyst', 'FundedElite Catalyst', 'Official Catalyst page and public size-specific challenge-template data captured 2026-09-28; the page reflects a selectable current ladder stage.'),
  ('custom-challenge', 'https://fundedelite.com/challenges/custom-challenge', 'FundedElite Custom Challenge', 'Officially marketed configurable builder; no fixed public template, price, or account configuration captured.')
) as x(program_slug, url, label, notes) on x.program_slug = p.slug
where f.slug = 'fundedelite'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.url);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Selector and first-party offer pages reviewed 2026-09-28. Staged in review: verify selected checkout options and reconcile current selector values with older FAQ/product pages before publication.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fundedelite'
  and p.slug in ('lite-1-step','lite-2-step','1-step-free-retry','2-step-free-retry','instant-funding','instant-elite','flash-activation','catalyst','custom-challenge')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, p.id, 'official_site', 'View ' || p.name || ' at FundedElite', x.url, true, 'active'
from bullish_banana.firms f
join bullish_banana.programs p on p.firm_id = f.id
join (values
  ('lite-1-step', 'https://fundedelite.com/challenges/lite-account'),
  ('lite-2-step', 'https://fundedelite.com/challenges/lite-account'),
  ('1-step-free-retry', 'https://fundedelite.com/challenges/free-retry'),
  ('2-step-free-retry', 'https://fundedelite.com/challenges/free-retry'),
  ('instant-funding', 'https://fundedelite.com/challenges/instant-funding'),
  ('instant-elite', 'https://fundedelite.com/challenges/instant-funding'),
  ('flash-activation', 'https://fundedelite.com/challenges/flash-activation'),
  ('catalyst', 'https://www.fundedelite.com/catalyst'),
  ('custom-challenge', 'https://fundedelite.com/challenges/custom-challenge')
) as x(program_slug, url) on x.program_slug = p.slug
where f.slug = 'fundedelite'
  and not exists (select 1 from bullish_banana.affiliate_destinations d where d.program_id = p.id and d.kind = 'official_site');
