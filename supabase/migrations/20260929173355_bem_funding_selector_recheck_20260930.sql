set search_path = bullish_banana, extensions, public;

-- BEM Funding's live homepage selector was rechecked on 2026-09-30.
-- Only default $5K / MT5 fee cards were observed; keep offers in_review and do not infer full matrices.

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "selector_recheck_2026_09_30": {
    "observed_configuration": "$5K MT5 default selection for each of the four current offers",
    "observations": {
      "bem-one": {"base_fee_usd": 47, "displayed_discount": "30%", "displayed_discounted_fee_usd": 32.90},
      "bem-one-only": {"base_fee_usd": 40, "displayed_discount": "40%", "displayed_discounted_fee_usd": 24.00},
      "bem-classic-normal": {"base_fee_usd": 39, "displayed_discount": "20%", "displayed_discounted_fee_usd": 31.20},
      "bem-classic-swing": {"base_fee_usd": 69, "displayed_discount": "5%", "displayed_discounted_fee_usd": 65.55}
    },
    "limitations": "These are one-size, one-platform live selector observations, not complete fee matrices. No checkout was completed. Promotional display is kept separate from base fee. Verify all sizes, platform variants, add-ons, eligibility and checkout price before publication."
  }
}'::jsonb,
updated_at = now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='bem-funding';

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
  'selector_observation_2026_09_30', x.observation::jsonb
), updated_at = now()
from bullish_banana.firms f
join (values
  ('bem-one', '{"account_size_usd":5000,"platform":"MT5","base_fee_usd":47,"displayed_discount_percent":30,"displayed_discounted_fee_usd":32.90,"capture":"Live homepage selector default card; no checkout completed."}'),
  ('bem-one-only', '{"account_size_usd":5000,"platform":"MT5","base_fee_usd":40,"displayed_discount_percent":40,"displayed_discounted_fee_usd":24.00,"capture":"Live homepage selector after selecting One Only; no checkout completed."}'),
  ('bem-classic-normal', '{"account_size_usd":5000,"platform":"MT5","base_fee_usd":39,"displayed_discount_percent":20,"displayed_discounted_fee_usd":31.20,"capture":"Live homepage selector after selecting Classic; no checkout completed."}'),
  ('bem-classic-swing', '{"account_size_usd":5000,"platform":"MT5","base_fee_usd":69,"displayed_discount_percent":5,"displayed_discounted_fee_usd":65.55,"capture":"Live homepage selector after selecting Swing; no checkout completed."}')
) as x(program_slug, observation) on true
where p.firm_id=f.id and f.slug='bem-funding' and p.slug=x.program_slug;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://bemfunding.com/', 'Live selector recheck — 2026-09-30',
       'Selected each of the four current offer types and observed the default $5K MT5 card. Base / displayed discounted amount: BEM One $47 / $32.90 (30%); BEM One Only $40 / $24 (40%); BEM Classic Normal $39 / $31.20 (20%); BEM Classic Swing $69 / $65.55 (5%). Homepage advertised MT5LIVE with up to 40% off this week. These are selector observations, not complete size/platform matrices; no checkout was completed. Retain base and promotional values separately and keep offers in review.'
from bullish_banana.firms f
where f.slug='bem-funding'
and not exists (
  select 1 from bullish_banana.sources s where s.firm_id=f.id
  and s.source_url='https://bemfunding.com/'
  and s.source_label='Live selector recheck — 2026-09-30'
);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(),
       'Live homepage selector rechecked 2026-09-30. All four candidate types and one default $5K MT5 base/discount display were observed. Full size and platform fee matrices, checkout price, program-specific eligibility and remaining payout/rule checks are outstanding. The firm and four programs remain in_review.'
from bullish_banana.firms f where f.slug='bem-funding';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(),
       'Current live selector recheck 2026-09-30 observed the $5K MT5 base and discounted display for this offer. This single configuration is not a complete price matrix and is not checkout confirmation. Program remains in_review pending full price/platform variants and remaining terms/eligibility checks.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='bem-funding'
and p.slug in ('bem-one','bem-one-only','bem-classic-normal','bem-classic-swing');
