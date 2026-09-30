begin;

update bullish_banana.program_phases ph
set name = 'GOAT Blitz Evaluation',
    profit_target_percent = 3,
    daily_drawdown_percent = 3,
    maximum_drawdown_percent = 5,
    drawdown_type = 'trailing',
    minimum_trading_days = 5,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'valid_day_threshold', '0.5% profit per day',
      'maximum_loss_per_trade_percent', 2,
      'availability', 'Official Help Center says the model is released on two weekends per month; current purchase availability is intermittent.',
      'source_note', 'Current official GOAT Blitz model FAQ and trading-day FAQ reviewed 2026-09-30.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'goat-funded-trader' and p.slug = 'goat-blitz';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'profit_target_rule', 'The current unified official checkout capture does not expose valid phase target percentages. Earlier phase figures are from an article explicitly marked old version; current targets remain unverified.',
  'source_note', 'Current official unified checkout and current challenge overview reviewed 2026-09-30; phase-specific target percentages remain unpublished in the captured current source.'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'top-one-trader' and p.slug = '2-step-standard';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('goat-funded-trader','goat-blitz','https://help.goatfundedtrader.com/en/articles/11111955-goat-blitz-model','GOAT Blitz model FAQ','Current official FAQ lists a 3% evaluation target, 3% static daily limit, 5% trailing overall limit, five valid trading days, and limited weekend release availability; reviewed 2026-09-30.'),
  ('goat-funded-trader','goat-blitz','https://help.goatfundedtrader.com/en/articles/13860595-what-are-the-minimum-trading-days','Minimum trading days FAQ','Official FAQ requires five valid days during GOAT Blitz evaluation, each meeting the stated profit threshold; reviewed 2026-09-30.'),
  ('top-one-trader','2-step-standard','https://checkout.toponetrader.com/product/top-one-trader-challenges/','Current unified challenge checkout','Current checkout lists the 2-Step product and shared rule categories but did not expose valid phase-specific target values in the captured response; older product-specific article is labeled old version. Reviewed 2026-09-30.')
) as x(firm_slug, program_slug, source_url, source_label, notes)
  on x.firm_slug = f.slug and x.program_slug = p.slug
where not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.source_url);

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Phase detail rechecked against the current official GOAT Blitz and Top One Trader 2-Step sources on 2026-09-30. GOAT Blitz current evaluation limits and days were normalized; Top One phase targets remain explicitly unstated in the current checkout capture.')
where v.program_id in (
  select p.id from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
  where (f.slug = 'goat-funded-trader' and p.slug = 'goat-blitz')
     or (f.slug = 'top-one-trader' and p.slug = '2-step-standard')
);

commit;
