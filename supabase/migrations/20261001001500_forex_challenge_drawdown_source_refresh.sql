begin;

-- Current official product pages resolve previously missing or variant-based
-- phase drawdown disclosures. Firm/program publication status is unchanged.
update bullish_banana.program_phases ph
set daily_drawdown_percent = 3,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', '3% daily loss limit for the current 1 Step Flex model, per the current official model comparison.',
      'source_note', 'Current official FundingPips model comparison reviewed 2026-09-30.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fundingpips' and p.slug = '1-step-flex';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'daily_loss_conflict', 'The current official model comparison reviewed 2026-09-30 maps 1 Step Flex to 3% daily loss. An earlier capture showed multiple variants; this record follows the current model table and remains under review pending offer-configuration confirmation.'
)
from bullish_banana.firms f where p.firm_id = f.id and f.slug = 'fundingpips' and p.slug = '1-step-flex';

update bullish_banana.program_phases ph
set daily_drawdown_percent = 5,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', '5% daily loss limit for the current 2 Step Standard model, per the current official model comparison.',
      'source_note', 'Current official FundingPips model comparison reviewed 2026-09-30.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fundingpips' and p.slug = '2-step-standard';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'daily_loss_conflict', 'The current official model comparison reviewed 2026-09-30 maps 2 Step Standard to 5% daily loss. An earlier capture showed multiple variants; this record follows the current model table and remains under review pending offer-configuration confirmation.'
)
from bullish_banana.firms f where p.firm_id = f.id and f.slug = 'fundingpips' and p.slug = '2-step-standard';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily loss limit during the evaluation. A 3% daily loss limit applies to the funded stage.',
  'maximum_drawdown_rule', '8% trailing maximum total loss during the evaluation; 6% trailing during the funded stage.',
  'source_note', 'Current official Pay Later model FAQ reviewed 2026-09-30.'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'goat-funded-trader' and p.slug = 'pay-later';

update bullish_banana.program_phases ph
set profit_target_percent = 3,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', 'No daily drawdown limit during the evaluation; the official FAQ lists None. A 3% daily limit applies only after funding.',
      'maximum_drawdown_rule', '8% trailing maximum total loss during evaluation; funded stage tightens to 6%.',
      'target_purchase_date_note', 'Current target is 3% for accounts purchased from 2026-09-05; older purchases may retain a 4% target.',
      'source_note', 'Current official Pay Later model FAQ reviewed 2026-09-30.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'goat-funded-trader' and p.slug = 'pay-later';

update bullish_banana.programs p
set account_sizes = '[5000,10000,15000,25000,50000,100000,200000]'::jsonb,
    commercial_details = (coalesce(p.commercial_details, '{}'::jsonb) - 'account_size_price_note') || jsonb_build_object(
      'account_size_prices', '[{"account_size":5000,"fee":5,"post_pass_fee":78,"currency":"USD"},{"account_size":10000,"fee":5,"post_pass_fee":118,"currency":"USD"},{"account_size":15000,"fee":5,"post_pass_fee":168,"currency":"USD"},{"account_size":25000,"fee":5,"post_pass_fee":238,"currency":"USD"},{"account_size":50000,"fee":5,"post_pass_fee":368,"currency":"USD"},{"account_size":100000,"fee":5,"post_pass_fee":598,"currency":"USD"},{"account_size":200000,"fee":5,"post_pass_fee":998,"currency":"USD"}]'::jsonb,
      'pricing_capture', 'Official Pay Later FAQ: $5 entry payment plus the size-specific remaining fee due after passing; reviewed 2026-09-30.'
    ),
    description = 'Single-phase simulated Forex evaluation. Current purchases use a 3% target, no daily loss limit, and an 8% trailing maximum loss; the $5 entry is followed by a size-dependent activation balance after passing.',
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'goat-funded-trader' and p.slug = 'pay-later';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily drawdown limit during the evaluation; the official product page lists Phase 1 as N/A. Funded accounts have a 4% daily limit.',
  'maximum_drawdown_rule', '10% maximum loss during evaluation; funded stage has an 8% maximum loss.',
  'source_note', 'Current official Maven Buy Now, Pay Later product page reviewed 2026-09-30.'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'maven-trading' and p.slug = 'buy-now-pay-later';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
  'daily_drawdown_rule', 'No daily loss limit during Bootcamp evaluation steps. The official source says the 3% daily pause begins only after funding.',
  'source_note', 'Current official The5ers Bootcamp rule article reviewed 2026-09-30.'
)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'the5ers' and p.slug = 'bootcamp';

update bullish_banana.program_phases ph
set daily_drawdown_percent = null,
    maximum_drawdown_percent = null,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', 'Current official general rules list 4% or 5% daily drawdown for 2-Step, depending on the selected add-on; the offer-specific add-on selection is not mapped in this record.',
      'maximum_drawdown_rule', 'Current official general rules list 8% or 10% static maximum loss for 2-Step, depending on the selected add-on; the offer-specific add-on selection is not mapped in this record.',
      'drawdown_variants', 'The official 2-Step offer varies by add-on; show both choices until the selector configuration is tied to this record.',
      'source_note', 'Current official Moneta Funded general rules reviewed 2026-09-30.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'moneta-funded' and p.slug = '2-step-challenge';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'daily_drawdown_rule', 'The current official Pay After Pass article identifies a 3% daily limit as funded-stage-only but does not establish an evaluation-specific daily threshold. Confirm the evaluation rule with AquaFunded.',
      'maximum_drawdown_rule', 'The official article describes a trailing total-loss rule but the exact evaluation-stage percentage and its application are not stated clearly in the reviewed source. Confirm before publication.',
      'source_note', 'Current official AquaFunded Pay After Pass model article reviewed 2026-09-30; evaluation and funded scope remains unresolved.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'aquafunded' and p.slug = 'pay-after-pass';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('goat-funded-trader','pay-later','https://help.goatfundedtrader.com/en/articles/12822025-pay-later-model','Pay Later model FAQ','Current official FAQ lists the $5 entry and size-specific remaining fees, 3% target for purchases from 2026-09-05, no daily evaluation loss, and 8% trailing evaluation max loss; reviewed 2026-09-30.'),
  ('atmos-funded','1-step-plus','https://help.atmosfunded.com/en/articles/12380556-1-step-plus-challenge','1-Step Plus challenge rules','Current official challenge article lists no daily loss limit, 6% target and 3% trailing max drawdown; reviewed 2026-09-30.'),
  ('fundingpips','1-step-flex','https://help.fundingpips.com/hc/en-us/articles/48368490585105-Compare-Account-Models','Compare Account Models','Current official model comparison reviewed 2026-09-30; 1 Step Flex daily loss is listed as 3%.'),
  ('fundingpips','2-step-standard','https://help.fundingpips.com/hc/en-us/articles/48368490585105-Compare-Account-Models','Compare Account Models','Current official model comparison reviewed 2026-09-30; 2 Step Standard daily loss is listed as 5%.'),
  ('maven-trading','buy-now-pay-later','https://maventrading.com/buy-now-pay-later','Buy Now, Pay Later product page','Current official page reviewed 2026-09-30; the evaluation phase lists daily loss as N/A, while funded daily loss is 4%.'),
  ('the5ers','bootcamp','https://the5ers.com/jp/fixed-vs-dynamic-profit-targets/','Bootcamp daily and maximum loss conditions','Current official company article distinguishes Bootcamp evaluation from funded rules: no daily limit during evaluation, then a 3% daily limit funded; reviewed 2026-09-30.'),
  ('moneta-funded','2-step-challenge','https://www.monetafunded.com/general-rules/','General Rules','Current official general rules list 4% or 5% daily and 8% or 10% static maximum loss for 2-Step, depending on add-on; reviewed 2026-09-30.'),
  ('aquafunded','pay-after-pass','https://help.aquafunded.com/en/articles/13322298-pay-after-pass-model','Pay After Pass Model','Current official article reviewed 2026-09-30. It identifies the 3% daily limit as funded-stage-only but does not clearly resolve the evaluation daily and total drawdown thresholds; those remain under review.')
) as x(firm_slug, program_slug, source_url, source_label, notes) on x.firm_slug = f.slug and x.program_slug = p.slug
where not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = x.source_url);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Phase loss rules reviewed against current official product/help-center source on 2026-09-30. The record reflects the sourced evaluation rule and distinguishes funded-stage limits; remaining firm/platform publication concerns remain unchanged.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where (f.slug, p.slug) in (
  ('goat-funded-trader','pay-later'), ('atmos-funded','1-step-plus'),
  ('fundingpips','1-step-flex'), ('fundingpips','2-step-standard'),
  ('maven-trading','buy-now-pay-later'), ('the5ers','bootcamp'),
  ('moneta-funded','2-step-challenge'), ('aquafunded','pay-after-pass')
)
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id);

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Phase loss rules rechecked against the current official product/help-center source on 2026-09-30. The challenge record separates evaluation rules from funded-stage limits; unresolved offer or entity publication concerns remain in review.')
where v.program_id in (
  select p.id from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
  where (f.slug, p.slug) in (
    ('goat-funded-trader','pay-later'), ('atmos-funded','1-step-plus'),
    ('fundingpips','1-step-flex'), ('fundingpips','2-step-standard'),
    ('maven-trading','buy-now-pay-later'), ('the5ers','bootcamp'),
    ('moneta-funded','2-step-challenge'), ('aquafunded','pay-after-pass')
  )
);

commit;
