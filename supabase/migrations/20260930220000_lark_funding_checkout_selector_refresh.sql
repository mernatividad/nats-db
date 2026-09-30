-- Lark Funding live checkout selector recheck, captured 2026-09-30.
-- Staged for review; do not apply until the catalog release window is authorized.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'account_size_prices', detail.account_size_prices::jsonb,
  'selector_capture', '2026-09-30',
  'price_configuration', detail.price_configuration,
  'platforms_note', 'The live official checkout selector currently offers cTrader, DXtrade, and Match-Trader for this product. Exact availability by residence and account size is not documented in the selector capture; confirm in checkout.',
  'promotion_note', detail.promotion_note
),
updated_at = now()
from (values
  ('1-step-career-evaluation',
   '[{"account_size":10000,"fee":200,"currency":"USD"},{"account_size":25000,"fee":300,"currency":"USD"},{"account_size":50000,"fee":500,"currency":"USD"},{"account_size":100000,"fee":800,"currency":"USD"},{"account_size":200000,"fee":1500,"currency":"USD"}]',
   'Live selector options captured 2026-09-30: Regular account type; cTrader, DXtrade, or Match-Trader; Hold Over The Weekend +10%, Stop Loss +10%, and Weekly Payouts +20%. Base fee excludes optional add-ons. Selector does not show a Swap Free account type for this offer.',
   'The homepage advertises the conditional September free-reset campaign through 2026-09-30 for 1-Step and 3-Step only. It also advertises a free $1,000 Instant account with purchases; that bonus has separate withdrawal rules and is not a paid challenge.'),
  ('3-step-evaluation',
   '[{"account_size":10000,"fee":105,"currency":"USD"},{"account_size":25000,"fee":175,"currency":"USD"},{"account_size":50000,"fee":280,"currency":"USD"},{"account_size":100000,"fee":370,"currency":"USD"},{"account_size":200000,"fee":700,"currency":"USD"}]',
   'Live selector options captured 2026-09-30: Regular or Swap Free account type; cTrader, DXtrade, or Match-Trader; 90% rewards add-on +20%, Hold Over The Weekend +10%, and Weekly Payouts +20%. Base fee excludes optional add-ons. The $200K fee is now $700 in the live selector; the 2026-09-28 selector captured $750; retain that value only as dated history.',
   'The homepage advertises the conditional September free-reset campaign through 2026-09-30 for 1-Step and 3-Step only. It also advertises a free $1,000 Instant account with purchases; that bonus has separate withdrawal rules and is not a paid challenge.'),
  ('instant-master-account',
   '[{"account_size":5000,"fee":200,"currency":"USD"},{"account_size":10000,"fee":400,"currency":"USD"},{"account_size":25000,"fee":1125,"currency":"USD"},{"account_size":50000,"fee":2750,"currency":"USD"},{"account_size":100000,"fee":4500,"currency":"USD"}]',
   'Live selector options captured 2026-09-30: Regular or Swap Free account type; cTrader, DXtrade, or Match-Trader; Hold Over The Weekend +10%. Base fee excludes the optional add-on.',
   'The homepage advertises a free $1,000 Instant account with purchases. Its Help Center sets a separate $100 total withdrawal cap after split, $50 minimum payout, and no $40 processing fee. This conditional bonus is not a paid challenge.')
) as detail(program_slug, account_size_prices, price_configuration, promotion_note)
where p.slug = detail.program_slug
  and exists (select 1 from bullish_banana.firms f where f.id = p.firm_id and f.slug = 'lark-funding');

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'selector_price_history', jsonb_build_array(
    jsonb_build_object('captured_at','2026-09-28','account_size',200000,'fee',750,'currency','USD','source_url','https://dashboard.larkfunding.com/en/challenges'),
    jsonb_build_object('captured_at','2026-09-30','account_size',200000,'fee',700,'currency','USD','source_url','https://dashboard.larkfunding.com/en/challenges')
  )
), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'lark-funding' and p.slug = '3-step-evaluation';

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
  'current_selector_capture', '2026-09-30',
  'current_selector_offers', jsonb_build_array('1-Step Career Evaluation','3-Step Evaluation','Instant'),
  'checkout_platforms_observed', jsonb_build_array('cTrader','DXtrade','Match-Trader'),
  'selector_note', 'Live official checkout selector rechecked 2026-09-30. It offers 1-Step, 3-Step, and Instant. 2-Step remains absent from checkout despite older Help Center references. Platform choices appeared across the three product selections reviewed; size and regional availability is not otherwise mapped.',
  'current_bonus_note', 'The homepage advertises a free $1,000 Instant Account with purchases; bonus-specific withdrawal rules cap total withdrawals at $100 after split, set a $50 minimum, and waive the usual $40 payout processing fee.',
  'free_reset_promotion', 'Conditional September free reset for 1-Step and 3-Step only, advertised through 2026-09-30; Instant excluded.'
), updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'lark-funding';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://dashboard.larkfunding.com/en/challenges', 'Lark Funding live checkout selector', 'Rechecked 2026-09-30 without submitting an order. Confirms current 1-Step, 3-Step and Instant offers, account sizes, selected fees, account-type/platform choices and optional add-on percentages. The $200K 3-Step selector fee is $700, versus $750 in the 2026-09-28 capture.'
from bullish_banana.firms f
where f.slug = 'lark-funding'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://dashboard.larkfunding.com/en/challenges');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://dashboard.larkfunding.com/en/challenges', 'Lark Funding live checkout selector', 'Directly rechecked 2026-09-30 without submitting an order. Current selector fee matrix and checkout configuration options captured for this offer.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'lark-funding'
  and p.slug in ('1-step-career-evaluation','3-step-evaluation','instant-master-account')
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://dashboard.larkfunding.com/en/challenges');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, now(), 'Rechecked official live challenge selector and homepage on 2026-09-30. Confirms three purchasable Forex offer families and current account/platform/add-on choices. The $200K 3-Step fee is $700 now versus $750 in the earlier 2026-09-28 capture. September free-reset offer is date-limited; 2-Step remains absent from the selector.'
from bullish_banana.firms f
where f.slug = 'lark-funding';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Official product selector fee matrix, account types, platforms, add-ons and current campaign notes rechecked on 2026-09-30 without creating an order. The 3-Step $200K price changed from the earlier selector capture; current checkout displays $700.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'lark-funding'
  and p.slug in ('1-step-career-evaluation','3-step-evaluation','instant-master-account');



