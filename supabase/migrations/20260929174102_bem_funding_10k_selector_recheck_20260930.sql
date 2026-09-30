set search_path = bullish_banana, extensions, public;

-- Current $10K fee cards were checked on both platform selections for all four offers.
-- Only this single account size is captured; never extrapolate the rest of a price matrix.

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
  'selector_observation_2026_09_30_10k', x.observation::jsonb
), updated_at = now()
from bullish_banana.firms f
join (values
  ('bem-one', '{"account_size_usd":10000,"platforms_checked":["MT5","cTrader"],"base_fee_usd":89,"displayed_discount_percent":30,"displayed_discounted_fee_usd":62.30,"platform_prices_matched":true,"capture":"Live homepage selector; selected $10K, BEM One, and each platform. No checkout completed."}'),
  ('bem-one-only', '{"account_size_usd":10000,"platforms_checked":["MT5","cTrader"],"base_fee_usd":90,"displayed_discount_percent":40,"displayed_discounted_fee_usd":54.00,"platform_prices_matched":true,"capture":"Live homepage selector; selected $10K, BEM One Only, and each platform. No checkout completed."}'),
  ('bem-classic-normal', '{"account_size_usd":10000,"platforms_checked":["MT5","cTrader"],"base_fee_usd":99,"displayed_discount_percent":20,"displayed_discounted_fee_usd":79.20,"platform_prices_matched":true,"capture":"Live homepage selector; selected $10K, BEM Classic Normal, and each platform. No checkout completed."}'),
  ('bem-classic-swing', '{"account_size_usd":10000,"platforms_checked":["MT5","cTrader"],"base_fee_usd":155,"displayed_discount_percent":5,"displayed_discounted_fee_usd":147.25,"platform_prices_matched":true,"capture":"Live homepage selector; selected $10K, BEM Classic Swing, and each platform. No checkout completed."}')
) as x(program_slug, observation) on true
where p.firm_id=f.id and f.slug='bem-funding' and p.slug=x.program_slug;

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://bemfunding.com/', 'Live selector $10K matrix recheck — 2026-09-30',
       'Selected $10K for each of BEM One, BEM One Only, BEM Classic Normal, and BEM Classic Swing, then checked MT5 and cTrader. Base / displayed discounted amounts were identical by platform: One $89 / $62.30 (30%); One Only $90 / $54.00 (40%); Classic Normal $99 / $79.20 (20%); Classic Swing $155 / $147.25 (5%). The page advertised MT5LIVE with up to 40% off. Selector evidence only; no checkout was completed. Other sizes and configuration-dependent totals remain unverified.'
from bullish_banana.firms f
where f.slug='bem-funding'
and not exists (
  select 1 from bullish_banana.sources s where s.firm_id=f.id
  and s.source_url='https://bemfunding.com/'
  and s.source_label='Live selector $10K matrix recheck — 2026-09-30'
);

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(),
       'Live selector rechecked at $10K on MT5 and cTrader for all four offers on 2026-09-30. Base and promotional displays matched across platforms. $5K and $10K are now individually observed; remaining offered sizes, add-ons, eligibility and exact checkout price remain pending. Firm and offers remain in_review.'
from bullish_banana.firms f where f.slug='bem-funding';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(),
       'The $10K base and displayed promotional amount were observed on both MT5 and cTrader in the current selector. Platform prices matched at $10K; this does not prove equal fees for other sizes. Remaining price matrix and product-term checks are open; program remains in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='bem-funding'
and p.slug in ('bem-one','bem-one-only','bem-classic-normal','bem-classic-swing');
