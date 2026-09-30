-- Current AquaFunded Forex selector price-pair snapshot observed on 2026-09-30.
-- Selector showed two unlabeled amounts per size and conflicting sale banners; preserve both as observations.
-- Do not publish a single fee until the first/second amount and promotion semantics are confirmed.
set search_path = bullish_banana, extensions, public;

with snapshot(slug, sizes, price_pairs) as (
  values
  ('1-step-standard', array[5000,10000,25000,50000,100000,200000]::numeric[], '[{"account_size":5000,"selector_price_1":40,"selector_price_2":67},{"account_size":10000,"selector_price_1":67,"selector_price_2":113},{"account_size":25000,"selector_price_1":136,"selector_price_2":227},{"account_size":50000,"selector_price_1":196,"selector_price_2":327},{"account_size":100000,"selector_price_1":316,"selector_price_2":527},{"account_size":200000,"selector_price_1":610,"selector_price_2":1017}]'::jsonb),
  ('1-step-pro', array[5000,10000,25000,50000,100000,200000]::numeric[], '[{"account_size":5000,"selector_price_1":35,"selector_price_2":59},{"account_size":10000,"selector_price_1":59,"selector_price_2":99},{"account_size":25000,"selector_price_1":119,"selector_price_2":199},{"account_size":50000,"selector_price_1":173,"selector_price_2":289},{"account_size":100000,"selector_price_1":275,"selector_price_2":459},{"account_size":200000,"selector_price_1":539,"selector_price_2":899}]'::jsonb),
  ('2-step-standard', array[5000,10000,25000,50000,100000,200000]::numeric[], '[{"account_size":5000,"selector_price_1":21,"selector_price_2":36},{"account_size":10000,"selector_price_1":53,"selector_price_2":89},{"account_size":25000,"selector_price_1":83,"selector_price_2":139},{"account_size":50000,"selector_price_1":179,"selector_price_2":299},{"account_size":100000,"selector_price_1":281,"selector_price_2":469},{"account_size":200000,"selector_price_1":568,"selector_price_2":947}]'::jsonb),
  ('2-step-pro', array[5000,10000,25000,50000,100000,200000]::numeric[], '[{"account_size":5000,"selector_price_1":17,"selector_price_2":29},{"account_size":10000,"selector_price_1":37,"selector_price_2":63},{"account_size":25000,"selector_price_1":62,"selector_price_2":104},{"account_size":50000,"selector_price_1":129,"selector_price_2":215},{"account_size":100000,"selector_price_1":257,"selector_price_2":429},{"account_size":200000,"selector_price_1":493,"selector_price_2":822}]'::jsonb),
  ('3-step', array[10000,25000,50000,100000,200000]::numeric[], '[{"account_size":10000,"selector_price_1":46,"selector_price_2":77},{"account_size":25000,"selector_price_1":94,"selector_price_2":157},{"account_size":50000,"selector_price_1":142,"selector_price_2":237},{"account_size":100000,"selector_price_1":226,"selector_price_2":377},{"account_size":200000,"selector_price_1":406,"selector_price_2":677}]'::jsonb),
  ('instant-funding-standard', array[2500,5000,10000,25000,50000,100000,200000,250000,300000]::numeric[], '[{"account_size":2500,"selector_price_1":38,"selector_price_2":64},{"account_size":5000,"selector_price_1":70,"selector_price_2":117},{"account_size":10000,"selector_price_1":94,"selector_price_2":158},{"account_size":25000,"selector_price_1":190,"selector_price_2":317},{"account_size":50000,"selector_price_1":285,"selector_price_2":475},{"account_size":100000,"selector_price_1":460,"selector_price_2":767},{"account_size":200000,"selector_price_1":759,"selector_price_2":1265},{"account_size":250000,"selector_price_1":936,"selector_price_2":1560},{"account_size":300000,"selector_price_1":1086,"selector_price_2":1810}]'::jsonb),
  ('instant-funding-pro', array[2500,5000,10000,25000,50000,100000,150000,200000,250000,300000,400000]::numeric[], '[{"account_size":2500,"selector_price_1":36,"selector_price_2":60},{"account_size":5000,"selector_price_1":61,"selector_price_2":102},{"account_size":10000,"selector_price_1":93,"selector_price_2":155},{"account_size":25000,"selector_price_1":186,"selector_price_2":310},{"account_size":50000,"selector_price_1":279,"selector_price_2":465},{"account_size":100000,"selector_price_1":450,"selector_price_2":750},{"account_size":150000,"selector_price_1":588,"selector_price_2":980},{"account_size":200000,"selector_price_1":750,"selector_price_2":1250},{"account_size":250000,"selector_price_1":924,"selector_price_2":1540},{"account_size":300000,"selector_price_1":1259,"selector_price_2":2099},{"account_size":400000,"selector_price_1":1619,"selector_price_2":2699}]'::jsonb)
)
update bullish_banana.programs p
set account_sizes = to_jsonb(snapshot.sizes),
    commercial_details = p.commercial_details || jsonb_build_object(
      'selector_price_pairs', snapshot.price_pairs,
      'price_capture_date', '2026-09-30',
      'price_capture_platform', 'MetaTrader 5 was selected by default in the public configurator.',
      'price_capture_note', 'The public selector displayed two amounts for each selected account size without labeling the relationship. Both are preserved as selector_price_1 and selector_price_2; do not describe either as standard, discounted, or checkout price until confirmed.',
      'promotion_display', 'The page simultaneously showed 40% OFF + BOGO after first payout for CFDs only (code SUMMERCLEAR), 25% OFF (code FALL), and a new-customer 50% OFF + $100 offer (code WELCOME). No code was copied/applied and no checkout was opened. The selector amount pair cannot be confidently attributed to a specific banner.',
      'platform_price_note', 'The current public configurator has Match Trade, TradeLocker, MetaTrader 5, and cTrader selections; page copy says cTrader has an additional fee. This snapshot was taken with MetaTrader 5 selected. Other platform price effects were not checked.'
    ),
    status = 'in_review', published_at = null, updated_at = now()
from snapshot
cross join bullish_banana.firms f
where f.slug = 'aquafunded' and p.firm_id = f.id and p.slug = snapshot.slug;

update bullish_banana.sources s
set source_label = 'AquaFunded Forex selector price snapshot — refreshed',
    notes = 'Public selector successfully rendered on 2026-09-30. Dated account-size and dual-amount price observations were captured for One Step Standard/Pro, Two Step Standard/Pro, Three Step, and Instant Funding Standard/Pro with MetaTrader 5 selected. Amount-pair meaning and promotion attribution are unresolved; no checkout was opened.',
    captured_at = now()
from bullish_banana.firms f
where f.slug = 'aquafunded' and s.firm_id = f.id
  and s.source_url = 'https://www.aquafunded.com/forex-funded-account';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://www.aquafunded.com/forex-funded-account', 'AquaFunded Forex selector price snapshot — refreshed', 'Public selector successfully rendered on 2026-09-30. Dated account-size and dual-amount price observations were captured for One Step Standard/Pro, Two Step Standard/Pro, Three Step, and Instant Funding Standard/Pro with MetaTrader 5 selected. Amount-pair meaning and promotion attribution are unresolved; no checkout was opened.'
from bullish_banana.firms f
where f.slug = 'aquafunded'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://www.aquafunded.com/forex-funded-account');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(), 'The public Forex selector now renders and exposes size/dual-price observations for seven current model variants. Amount labels, promotion attribution, platform price effects, and selector-vs-checkout semantics remain unresolved; programs stay in_review.'
from bullish_banana.firms f where f.slug = 'aquafunded';
