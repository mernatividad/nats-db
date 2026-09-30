begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'The current official Growth page lists unlimited time for this evaluation plan.',
      'time_limit_scope', 'Offer-specific Growth plan selector',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'the5ers'
  and p.slug in ('pro-growth','hyper-growth');

update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'The official Bootcamp FAQ states that the evaluation phase has no time limit.',
      'time_limit_scope', 'Bootcamp evaluation stages',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'the5ers' and p.slug = 'bootcamp';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id,
       case when p.slug = 'bootcamp' then 'https://the5ers.com/faqs/how-does-the-bootcamp-program-work/'
            else 'https://the5ers.com/hyper-growth/' end,
       'The5ers current evaluation duration — ' || p.name || ' — 2026-10-01',
       case when p.slug = 'bootcamp'
         then 'The current Bootcamp FAQ explicitly states that there is no time limit to pass the evaluation stages.'
         else 'The current Growth page lists both Pro Growth and Hyper Growth selector options and states unlimited time for both plans.'
       end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug in ('pro-growth','hyper-growth','bootcamp')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'The5ers current evaluation duration — ' || p.name || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T02:00:00Z'::timestamptz,
  case when p.slug = 'bootcamp'
    then 'Rechecked the current official Bootcamp FAQ, which explicitly states no time limit to pass the evaluation stages.'
    else 'Rechecked the current official Growth page. Its current selector presents Pro Growth and Hyper Growth and lists unlimited evaluation time for both.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug in ('pro-growth','hyper-growth','bootcamp')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id
    and v.verified_at = '2026-10-01T02:00:00Z'::timestamptz);

commit;
