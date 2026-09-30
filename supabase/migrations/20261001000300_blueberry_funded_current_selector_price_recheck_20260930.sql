-- Record a fresh official selector price check for Blueberry Funded's written-current offers.
-- All 64 supported MT5/TradeLocker variants matched staged fees on 2026-09-30.
-- API data was read-only; no checkout or database write occurred during research.
set search_path = bullish_banana, extensions, public;

update bullish_banana.sources
set notes = concat_ws(E'\n', nullif(notes, ''),
  'Rechecked 2026-09-30 using the public WooCommerce Store API product collection and each variation product resource. Five Help Center-current Forex offer types (1-Step, Flex 1-Step, Prime, Instant Lite, Instant Elite) yielded 64 purchasable USD variations across supported MT5 and TradeLocker platforms; all had no sale flag and matched staged fee values exactly. Platform totals: 12/12/14/14/12 variants respectively. DXtrade selector variants remain excluded because first-party platform guidance says DXtrade is unsupported. Flex $200K remains in review: selector lists it while written Flex rules cap at $100K.'
)
from bullish_banana.firms
where firms.id = sources.firm_id
  and firms.slug = 'blueberry-funded'
  and sources.source_url = 'https://blueberryfunded.com/wp-json/wc/store/v1/products?slug=bbf-challenges';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), check_result.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('one-step','2026-09-30 Store API check: all 12 MT5/TradeLocker variations across six sizes are purchasable, not on sale, and match staged fees.'),
  ('flex-one-step','2026-09-30 Store API check: all 12 MT5/TradeLocker variations across six sizes are purchasable, not on sale, and match staged fees. Selector offers $200K/$1,600 although written rules cap Flex at $100K; keep that variant/program in review.'),
  ('prime','2026-09-30 Store API check: all 14 MT5/TradeLocker variations across seven sizes are purchasable, not on sale, and match staged fees.'),
  ('instant-lite','2026-09-30 Store API check: all 14 MT5/TradeLocker variations across seven sizes are purchasable, not on sale, and match staged fees.'),
  ('instant-elite','2026-09-30 Store API check: all 12 MT5/TradeLocker variations across six sizes are purchasable, not on sale, and match staged fees.')
) as check_result(program_slug, notes) on check_result.program_slug = programs.slug
where firms.slug = 'blueberry-funded';
