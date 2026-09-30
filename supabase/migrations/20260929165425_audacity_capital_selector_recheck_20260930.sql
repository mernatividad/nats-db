-- Refresh Audacity Capital offer verification from its interactive first-party selector.
-- Preserve the prior review status while capturing current purchase options.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles
set profile_details = profile_details || '{"account_size_note":"Interactive official selector rechecked 2026-09-30: Ability Challenge initial sizes are $5K-$200K; Ability One initial choices are $5K-$100K, while its product/FAQ describe funding or allocation up to $200K; FTP choices are $5K-$50K. Do not equate maximum allocation with an available initial purchase size.","selector_capture_note":"The pricing section has separate interactive tabs for Ability Challenge, Ability One and FTP. Each tab was selected and its listed sizes/prices verified in the browser on 2026-09-30. The page''s server-rendered default can show Ability Challenge prices regardless of URL; attribute prices only after selecting the intended program tab."}'::jsonb,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'audacity-capital');

update bullish_banana.programs
set commercial_details = commercial_details || case slug
  when 'ability-challenge-2-step' then '{"pricing_capture":"Rechecked in the official multi-program selector on 2026-09-30 by selecting the Ability Challenge tab. USD prices are $42/$49, $68/$79, $168/$195, $283/$329, $472/$549, and $902/$1,049 for $5K, $10K, $25K, $50K, $100K, and $200K respectively. 14% promotion displayed; end date not stated. GBP/EUR tabs exist but those schedules were not captured."}'::jsonb
  when 'ability-one-1-step' then '{"pricing_capture":"Rechecked in the official multi-program selector on 2026-09-30 by selecting Ability One. Initial USD choices displayed only $5K, $10K, $25K, $50K and $100K at $59/$69, $85/$99, $214/$249, $343/$399 and $601/$699 respectively. 14% promotion displayed; end date not stated. GBP/EUR tabs exist but those schedules were not captured.","allocation_cap_note":"Product page and FAQ describe funding/allocation up to $200K, but the current purchase selector stops at $100K. A $200K initial purchase was not available in the selected tab; keep the discrepancy explicit."}'::jsonb
  when 'ftp-instant-funding' then '{"pricing_capture":"Rechecked in the official multi-program selector on 2026-09-30 by selecting FTP (Instant Funding). Initial USD choices displayed $5K, $10K, $25K and $50K at $102/$119, $240/$279, $386/$449 and $1,117/$1,299 respectively. 14% promotion displayed; end date not stated. GBP/EUR tabs exist but those schedules were not captured."}'::jsonb
  else '{}'::jsonb end,
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'audacity-capital')
  and slug in ('ability-challenge-2-step', 'ability-one-1-step', 'ftp-instant-funding');

update bullish_banana.sources source
set notes = case program.slug
  when 'ability-challenge-2-step' then 'Current official multi-program selector was rechecked 2026-09-30 with the Ability Challenge tab selected. It displayed six initial sizes from $5K through $200K and USD promo/list fee pairs matching the staged matrix. Promotion end date and GBP/EUR matrices remain unstated.'
  when 'ability-one-1-step' then 'Current official multi-program selector was rechecked 2026-09-30 with Ability One selected. It displayed five initial sizes through $100K and USD promo/list fee pairs matching the staged matrix. Separate product/FAQ copy describes funding/allocation up to $200K; no $200K initial purchase was present in the selected tab.'
  when 'ftp-instant-funding' then 'Current official multi-program selector was rechecked 2026-09-30 with FTP selected. It displayed four initial sizes from $5K through $50K and USD promo/list fee pairs matching the staged matrix. Promotion end date and GBP/EUR matrices remain unstated.'
  else source.notes end,
  captured_at = now()
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
where source.program_id = program.id
  and firm.slug = 'audacity-capital'
  and source.source_url = 'https://audacity.capital/one-step-prop-firm-ability-one/';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select program.id,
       'https://audacity.capital/one-step-prop-firm-ability-one/',
       'Interactive three-program size and fee selector — 2026-09-30',
       evidence.notes
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
join (values
  ('ability-challenge-2-step', 'Browser-selected Ability Challenge tab displayed six initial sizes from $5K to $200K and USD promotion/list pairs matching the staged matrix.'),
  ('ability-one-1-step', 'Browser-selected Ability One tab displayed five initial sizes from $5K to $100K and USD promotion/list pairs matching the staged matrix; page copy cites funding/allocation up to $200K.'),
  ('ftp-instant-funding', 'Browser-selected FTP tab displayed four initial sizes from $5K to $50K and USD promotion/list pairs matching the staged matrix.')
) as evidence(program_slug, notes) on evidence.program_slug = program.slug
where firm.slug = 'audacity-capital'
  and not exists (
    select 1 from bullish_banana.sources existing
    where existing.program_id = program.id
      and existing.source_url = 'https://audacity.capital/one-step-prop-firm-ability-one/'
      and existing.source_label = 'Interactive three-program size and fee selector — 2026-09-30'
  );

update bullish_banana.data_verifications
set verified_at = now(),
    notes = 'Current official interactive selector and program-specific USD size/price mappings were rechecked 2026-09-30. Ability One purchase options stop at $100K despite copy citing up to $200K funding/allocation. GBP/EUR selector schedules, applicable contracting entity, current Terms conflicts, and full offer/platform eligibility remain unresolved; all three offers stay in review.'
where firm_id = (select id from bullish_banana.firms where slug = 'audacity-capital');

update bullish_banana.data_verifications verification
set verified_at = now(),
    notes = 'Program-specific selector tab and displayed USD initial size/fee schedule were rechecked 2026-09-30 and match the staged matrix. Fee promotion end date and GBP/EUR schedules remain unverified. Program remains in review for outstanding rules, service/legal conflicts, or size/eligibility questions.'
from bullish_banana.programs program
join bullish_banana.firms firm on firm.id = program.firm_id
where verification.program_id = program.id
  and firm.slug = 'audacity-capital'
  and program.slug in ('ability-challenge-2-step', 'ability-one-1-step', 'ftp-instant-funding');
