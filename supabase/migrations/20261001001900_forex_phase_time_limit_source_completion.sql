begin;

-- Normalize only explicit unlimited-duration claims. Blue Guardian's reviewed
-- rules omit an overall duration, so retain a disclosure without inferring one.
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', 'Unlimited',
      'time_limit_source_reviewed', '2026-09-30'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and (
  (f.slug = 'alpha-capital-group' and p.slug = 'alpha-pro-8')
  or (f.slug = 'ftmo' and p.slug in ('ftmo-1-step', 'ftmo-2-step'))
  or (f.slug = 'fundednext' and p.slug = 'stellar-2-step')
  or (f.slug = 'the5ers' and p.slug = 'high-stakes')
);

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'The reviewed current official rules do not state an overall maximum evaluation duration. A separate 30-day inactivity rule applies; it is not an evaluation deadline.',
      'time_limit_source_reviewed', '2026-09-30'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'blue-guardian' and p.slug = '2-step-standard';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('alpha-capital-group','alpha-pro-8','https://alphacapitalgroup.uk/resources/what-is-a-qualified-trading-account-a-uk-guide-for-2026','Alpha Capital evaluation duration','Official guide states Alpha evaluation accounts have no maximum duration; reviewed 2026-09-30.'),
  ('ftmo','ftmo-1-step','https://ftmo.com/en/faq/how-long-does-it-take-to-become-an-ftmo-trader/','FTMO evaluation duration FAQ','Official FAQ states there is no maximum time to complete the 1-Step Challenge; reviewed 2026-09-30.'),
  ('ftmo','ftmo-2-step','https://ftmo.com/en/faq/how-long-does-it-take-to-become-an-ftmo-trader/','FTMO evaluation duration FAQ','Official FAQ states there is no maximum time to complete the 2-Step Challenge; reviewed 2026-09-30.'),
  ('fundednext','stellar-2-step','https://fundednext.com/usa/cfds/stellar-2-step','FundedNext Stellar 2-Step','Official program page states there is no time limit to complete the challenge; reviewed 2026-09-30.'),
  ('fundednext','stellar-2-step','https://fundednext.com/general-rules/cfds/trading-objectives','FundedNext CFD trading objectives','Official trading objectives state there is no time limit; reviewed 2026-09-30.'),
  ('the5ers','high-stakes','https://the5ers.com/faqs/what-are-the-general-rules-for-the-high-stakes-program/','The5ers High Stakes general rules','Current official FAQ states High Stakes has unlimited time; reviewed 2026-09-30.'),
  ('blue-guardian','2-step-standard','https://help.blueguardian.com/en/articles/14062291-2-step-standard-rules','Blue Guardian 2-Step Standard rules','Reviewed current official rules do not state an overall evaluation duration; reviewed 2026-09-30.'),
  ('blue-guardian','2-step-standard','https://help.blueguardian.com/en/articles/15618204-general-information-rules','Blue Guardian general information rules','States a separate 30-day inactivity rule; does not state an overall evaluation duration; reviewed 2026-09-30.')
) as x(firm_slug, program_slug, source_url, source_label, notes)
  on x.firm_slug = f.slug and x.program_slug = p.slug
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id and s.source_url = x.source_url
);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30'::timestamptz,
  case when f.slug = 'blue-guardian'
    then 'Reviewed current 2-Step Standard and general rules. The rules do not state an overall evaluation duration; the separate 30-day inactivity rule is not an evaluation deadline.'
    else 'Evaluation duration checked against current official first-party material on 2026-09-30; explicit unlimited duration is normalized on each evaluation phase.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where (f.slug = 'alpha-capital-group' and p.slug = 'alpha-pro-8')
   or (f.slug = 'ftmo' and p.slug in ('ftmo-1-step', 'ftmo-2-step'))
   or (f.slug = 'fundednext' and p.slug = 'stellar-2-step')
   or (f.slug = 'the5ers' and p.slug = 'high-stakes')
   or (f.slug = 'blue-guardian' and p.slug = '2-step-standard');

commit;
