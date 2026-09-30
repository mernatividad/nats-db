begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = case when ph.phase_number <= 2 then 0 else null end,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit', case when ph.phase_number <= 2 then 'Unlimited' else 'Not applicable — funded stage' end,
      'time_limit_label', case when ph.phase_number <= 2 then 'No time limit' else 'Funded stage' end,
      'time_limit_unit', case when ph.phase_number <= 2 then 'unlimited' else 'not_applicable' end,
      'time_limit_note', case
        when ph.phase_number <= 2 then x.evaluation_note
        else 'This is the post-evaluation funded stage. Challenge completion deadlines apply to evaluation phases only.'
      end,
      'time_limit_scope', case
        when ph.phase_number <= 2 then 'Evaluation phase; no maximum completion deadline'
        else 'Funded phase; not an evaluation deadline'
      end,
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('2-step-challenge', 'Moneta Funded’s current official Two Step page states that traders have unlimited time to complete all Moneta Funded challenges. This covers both evaluation phases; funded-stage terms are separate.'),
  ('1-step-daily', 'Moneta Funded’s current official One Step Daily page explicitly lists no time limit for the evaluation challenge. Funded-stage terms are separate.')
) as x(program_slug, evaluation_note) on x.program_slug = p.slug
where ph.program_id = p.id and f.slug = 'moneta-funded'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('2-step-challenge', 'https://www.monetafunded.com/two-step/', 'Moneta Funded Two Step evaluation deadline — 2026-10-01', 'The current official Two Step page FAQ states that traders have unlimited time to complete all Moneta Funded challenges. Reviewed 2026-10-01.'),
  ('1-step-daily', 'https://www.monetafunded.com/one-step-daily/', 'Moneta Funded One Step Daily evaluation deadline — 2026-10-01', 'The current official One Step Daily challenge page explicitly lists No Time Limit for the evaluation offer. Reviewed 2026-10-01.')
) as x(program_slug, source_url, source_label, notes) on x.program_slug = p.slug
where f.slug = 'moneta-funded' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz, x.verification_note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('2-step-challenge', 'Rechecked Moneta Funded’s current official Two Step page. It states unlimited time for all Moneta Funded challenges.'),
  ('1-step-daily', 'Rechecked Moneta Funded’s current official One Step Daily challenge page. It explicitly lists no time limit.')
) as x(program_slug, verification_note) on x.program_slug = p.slug
where f.slug = 'moneta-funded' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = x.verification_note);

commit;
