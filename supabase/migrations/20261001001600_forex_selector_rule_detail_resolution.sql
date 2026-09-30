begin;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily loss limit during the 1-Step Plus evaluation. The current official challenge rules list Max Daily Loss as None.',
  'source_note', 'Official AtmosFunded 1-Step Plus challenge rules reviewed 2026-09-30.'
)
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'atmos-funded' and p.slug = '1-step-plus';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily loss limit during the NOVA evaluation; the official NOVA FAQ lists the evaluation daily limit as 0%. The funded stage has a 3% daily limit.',
  'source_note', 'Current official Top One Trader NOVA Account Overview and Daily Loss Limit Rule reviewed 2026-09-30.'
)
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'top-one-trader' and p.slug = '1-step-nova';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'profit_target_rule', 'The target depends on selected account size, timeframe, and multiplier. The official builder capture shows a $10,000 / 4-hour / 2x example with a $60 target (0.6%).',
  'daily_drawdown_rule', 'The reviewed Sprint rules list a configurable maximum loss but do not state a separate daily loss limit.',
  'maximum_drawdown_rule', 'Maximum loss is set by the selected size, timeframe, and multiplier. The captured $10,000 / 4-hour / 2x example shows $30 (0.3%); do not generalize that value to other configurations.',
  'source_note', 'Current official Moneta Funded Sprint builder and FAQ reviewed 2026-09-30; only the displayed example is captured as a numeric example.'
)
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'moneta-funded' and p.slug = 'sprint-challenge';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('atmos-funded','1-step-plus','https://help.atmosfunded.com/en/articles/12380556-1-step-plus-challenge','1-Step Plus challenge rules','Current official challenge rules list no daily loss limit for evaluation; reviewed 2026-09-30.'),
  ('top-one-trader','1-step-nova','https://help.toponetrader.com/en/articles/13832165-nova-account-overview','NOVA account overview','Current official overview lists 5% evaluation target, 6% trailing max loss, no daily loss limit in evaluation, and size-specific activation fees; reviewed 2026-09-30.'),
  ('top-one-trader','1-step-nova','https://help.toponetrader.com/en/articles/13833346-nova-daily-loss-limit-rule','NOVA daily loss rule','Official stage table lists 0% evaluation daily loss and 3% funded daily loss; reviewed 2026-09-30.'),
  ('moneta-funded','sprint-challenge','https://www.monetafunded.com/sprint-challenge/','Sprint Challenge builder and rules','Current official page lists configurable $10K/$25K account sizes, 1/2/4/8-hour duration, 2x/5x multiplier, and example output; reviewed 2026-09-30.'),
  ('aquafunded','pay-after-pass','https://help.aquafunded.com/en/articles/13322298-pay-after-pass-model','Pay After Pass Model','Current official article reviewed 2026-09-30. The 3% daily limit is explicitly labeled funded-stage-only; evaluation daily and total drawdown scope remains unresolved.')
) as x(firm_slug, program_slug, source_url, source_label, notes) on x.firm_slug = f.slug and x.program_slug = p.slug
where not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.source_url);

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Selector-dependent challenge terms refreshed from current official sources on 2026-09-30. Numeric examples are explicitly scoped to their configuration; unresolved product/service publication issues remain in review.')
where v.program_id in (
  select p.id from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
  where (f.slug, p.slug) in (
    ('atmos-funded','1-step-plus'), ('top-one-trader','1-step-nova'),
    ('moneta-funded','sprint-challenge'), ('aquafunded','pay-after-pass')
  )
);

commit;
