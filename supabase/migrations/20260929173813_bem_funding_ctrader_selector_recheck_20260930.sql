set search_path = bullish_banana, extensions, public;

-- The same four default $5K products were selected with cTrader on 2026-09-30.
-- This supplements, and does not replace, the MT5 observations in the prior migration.

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
  'selector_platform_observation_2026_09_30', x.observation::jsonb
), updated_at = now()
from bullish_banana.firms f
join (values
  ('bem-one', '{"account_size_usd":5000,"platform":"cTrader","base_fee_usd":47,"displayed_discount_percent":30,"displayed_discounted_fee_usd":32.90,"capture":"Live homepage selector after selecting BEM One and cTrader; no checkout completed."}'),
  ('bem-one-only', '{"account_size_usd":5000,"platform":"cTrader","base_fee_usd":40,"displayed_discount_percent":40,"displayed_discounted_fee_usd":24.00,"capture":"Live homepage selector after selecting BEM One Only and cTrader; no checkout completed."}'),
  ('bem-classic-normal', '{"account_size_usd":5000,"platform":"cTrader","base_fee_usd":39,"displayed_discount_percent":20,"displayed_discounted_fee_usd":31.20,"capture":"Live homepage selector after selecting BEM Classic Normal and cTrader; no checkout completed."}'),
  ('bem-classic-swing', '{"account_size_usd":5000,"platform":"cTrader","base_fee_usd":69,"displayed_discount_percent":5,"displayed_discounted_fee_usd":65.55,"capture":"Live homepage selector after selecting BEM Classic Swing and cTrader; no checkout completed."}')
) as x(program_slug, observation) on true
where p.firm_id=f.id and f.slug='bem-funding' and p.slug=x.program_slug;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://bemfunding.com/', 'Live selector cTrader recheck — 2026-09-30',
       'Selected cTrader on the live homepage selector for each current offer at the default $5K size. Base / displayed discounted amount: BEM One $47 / $32.90 (30%); BEM One Only $40 / $24 (40%); BEM Classic Normal $39 / $31.20 (20%); BEM Classic Swing $69 / $65.55 (5%). Values match the separately captured $5K MT5 cards. This confirms platform availability and price only for the default $5K configuration; it does not establish equality across other sizes or checkout totals. No purchase or checkout was completed.'
from bullish_banana.firms f
where f.slug='bem-funding'
and not exists (
  select 1 from bullish_banana.sources s where s.firm_id=f.id
  and s.source_url='https://bemfunding.com/'
  and s.source_label='Live selector cTrader recheck — 2026-09-30'
);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(),
       'Rechecked cTrader selection for all four current offers at the default $5K configuration on 2026-09-30. Base and displayed discounted prices matched the separately observed $5K MT5 cards. Do not infer same pricing at other sizes; full size/platform matrix and checkout details remain pending. Firm and programs remain in_review.'
from bullish_banana.firms f where f.slug='bem-funding';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(),
       'cTrader selector observation added for this offer at $5K only on 2026-09-30; base and displayed discount matched $5K MT5. Other sizes, full platform matrix and checkout details are unverified. Program remains in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='bem-funding'
and p.slug in ('bem-one','bem-one-only','bem-classic-normal','bem-classic-swing');
