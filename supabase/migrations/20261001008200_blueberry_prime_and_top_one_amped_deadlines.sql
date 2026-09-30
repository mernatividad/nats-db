begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = case when ph.phase_number <= x.evaluation_phase_count then x.time_limit_days else null end,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', case when ph.phase_number <= x.evaluation_phase_count then x.time_limit_label else 'Not applicable — funded stage' end,
      'time_limit_label', case when ph.phase_number <= x.evaluation_phase_count then x.time_limit_label else 'Funded stage' end,
      'time_limit_unit', case when ph.phase_number <= x.evaluation_phase_count then x.time_limit_unit else 'not_applicable' end,
      'time_limit_note', case when ph.phase_number <= x.evaluation_phase_count then x.evaluation_note else 'This is the post-evaluation funded stage. Challenge completion deadlines apply to evaluation phases only.' end,
      'time_limit_scope', case when ph.phase_number <= x.evaluation_phase_count then 'Evaluation phase' else 'Funded phase; not an evaluation deadline' end,
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('blueberry-funded', 'prime', 2, 0, 'No time limit', 'unlimited', 'Blueberry Funded’s current official Prime Challenge page lists the Time Limit as Unlimited for its two-step evaluation. Funded-stage terms are separate.'),
  ('top-one-trader', '2-step-amped', 2, null, 'Not stated', 'undisclosed', 'The current official 2-Step Amped rules overview does not publish an overall evaluation completion deadline. It separately lists a 30-day inactivity limit; that inactivity condition is not a challenge deadline.')
) as x(firm_slug, program_slug, evaluation_phase_count, time_limit_days, time_limit_label, time_limit_unit, evaluation_note)
  on x.firm_slug = f.slug and x.program_slug = p.slug
where ph.program_id = p.id and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('blueberry-funded', 'prime', 'https://blueberryfunded.com/prime/', 'Blueberry Funded Prime challenge deadline — 2026-10-01', 'The current official Prime Challenge page lists Time Limit: Unlimited alongside its two-phase evaluation objectives. Reviewed 2026-10-01.'),
  ('top-one-trader', '2-step-amped', 'https://help.toponetrader.com/en/articles/14432028-2-step-amped-overview', 'Top One Trader 2-Step Amped evaluation deadline — 2026-10-01', 'The current official 2-Step Amped overview lists the evaluation rules and a separate 30-day inactivity limit but does not state a maximum evaluation completion deadline. Reviewed 2026-10-01.')
) as x(firm_slug, program_slug, source_url, source_label, notes)
  on x.firm_slug = f.slug and x.program_slug = p.slug
where p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz, x.verification_note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('blueberry-funded', 'prime', 'Rechecked Blueberry Funded’s current official Prime Challenge page; its two-step evaluation lists an unlimited time limit.'),
  ('top-one-trader', '2-step-amped', 'Rechecked Top One Trader’s current official 2-Step Amped rules overview. It does not state an overall evaluation deadline; its separate 30-day inactivity limit is not treated as one.')
) as x(firm_slug, program_slug, verification_note)
  on x.firm_slug = f.slug and x.program_slug = p.slug
where p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = x.verification_note);

commit;
