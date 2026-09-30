-- Preserve the current dedicated offer page's explicit no-daily-limit rule and
-- the dated disagreement between CTI's offer page and editorial pricing article.
-- The actual checkout total remains unverified; the program stays in_review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', 'No daily drawdown limit. The current official 1-Step product page displays “Max Daily Drawdown None.” Rechecked 2026-09-30.'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id
  and f.slug = 'city-traders-imperium'
  and p.slug = '1-step-challenge'
  and ph.phase_number = 1;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'price_configuration', 'Current dedicated CTI 1-Step offer page rechecked 2026-09-30 lists $29/$49/$79/$159/$299/$449 for $2.5K/$5K/$10K/$25K/$50K/$100K accounts. CTI editorial article “EAs on CTI 1-Step Challenge: What’s Allowed?” updated 2026-09-03 instead lists $269/$469 for $50K/$100K. These official sources conflict; the dedicated current offer page is used for displayed base list prices. Final checkout amount and any promotion were not verified.',
      'account_size_price_note', 'Current dedicated offer page (rechecked 2026-09-30) lists $299/$449 for $50K/$100K. CTI editorial article updated 2026-09-03 lists $269/$469 for those sizes. Official sources conflict; displayed base prices follow the dedicated offer page. Final checkout total and promotion unverified.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'city-traders-imperium'
  and p.slug = '1-step-challenge';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       'https://citytradersimperium.com/eas-on-cti-1-step-challenge-whats-allowed/',
       'CTI 1-Step editorial article — dated price comparison',
       'Rechecked 2026-09-30. This official editorial article, updated 2026-09-03, lists $269 for $50K and $469 for $100K. CTI''s dedicated 1-Step product page rechecked 2026-09-30 lists $299/$449 for those sizes. These official pages disagree; current displayed base prices follow the dedicated offer page. Final checkout total and promotion unverified.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'city-traders-imperium'
  and p.slug = '1-step-challenge'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id
      and s.source_url = 'https://citytradersimperium.com/eas-on-cti-1-step-challenge-whats-allowed/'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       timestamptz '2026-09-30 00:00:00+00',
       'Current official CTI 1-Step product page explicitly states no maximum daily drawdown; the page lists $299/$449 for $50K/$100K accounts. Editorial article updated 2026-09-03 lists $269/$469 for those sizes. Official prices conflict; use dedicated offer page as the current displayed base list, with final checkout and promotion unverified. Program remains in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'city-traders-imperium'
  and p.slug = '1-step-challenge'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id
      and v.notes like '%Current official CTI 1-Step product page explicitly states no maximum daily drawdown%'
  );
