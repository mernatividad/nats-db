-- Current high-level Lightning offer claims from the official product page.
-- Keep the program in_review: detailed rules, full matrix, and terms are absent.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set max_leverage = null,
    profit_split_percent = 90,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'starting_price_account_size', 10000,
      'starting_price_base_fee', 59,
      'price_capture', 'Official Lightning product page states starting cost $59 for a $10K evaluation; it does not expose a complete live size/fee matrix.',
      'phase_summary', 'Official product page describes a one-step evaluation with a 5% target and says traders can meet objectives in five days. It does not specify the target calculation, minimum-day semantics, or max duration.',
      'funded_rules', 'Page advertises up to 90% performance split; default split and payout schedule are not stated.',
      'trading_conditions', 'Product page identifies Platform 5. FXIFY''s How It Works page expands this as Trading Platform 5 (TP5); do not map it to MetaTrader 5. Leverage, price feed, instruments, news/weekend/EA/copy-trading terms are not stated for Lightning.',
      'open_items', '["Complete current size and base-fee matrix","Confirm five-day objective semantics and minimum days","daily and maximum drawdown","default split and payout terms","Forex-specific selector availability","leverage, feed and trading conditions","refund and account contract terms"]'::jsonb
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'fxify'
  and p.slug = 'lightning-challenge';

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/programs/lightning-challenge/',
       'Lightning product page high-level offer recheck — 2026-09-30',
       'The current page states one-step evaluation, 5% target, five-day objective, sizes up to $100K, up to 90% split, Platform 5, and starting cost $59 for a $10K evaluation. It does not provide the full size/fee matrix or detailed drawdown, payout, leverage, feed, restrictions, and refund terms. A lower embedded section contains unrelated One Phase copy; it was not attributed to Lightning. Keep in_review.',
       '2026-09-30 00:00:00+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'lightning-challenge'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://fxify.com/programs/lightning-challenge/' and s.source_label = 'Lightning product page high-level offer recheck — 2026-09-30');

insert into bullish_banana.sources (program_id, source_url, source_label, notes, captured_at)
select p.id,
       'https://fxify.com/how-it-works/',
       'FXIFY Trading Platform 5 naming clarification — 2026-09-30',
       'The official page expands TP5 as Trading Platform 5 and describes TP4/TP5 as platform labels. This does not establish MetaTrader 5 for Lightning; no MetaTrader association is added.',
       '2026-09-30 00:00:00+00'::timestamptz
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'lightning-challenge'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id and s.source_url = 'https://fxify.com/how-it-works/' and s.source_label = 'FXIFY Trading Platform 5 naming clarification — 2026-09-30');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id,
       '2026-09-30 00:00:00+00'::timestamptz,
       'Rechecked official Lightning product page 2026-09-30. Captured one-step, 5% target, five-day objective, up to $100K, up to 90% split, Platform 5, and $59 starting price for a $10K evaluation. Official How It Works material expands this label to Trading Platform 5 (TP5); do not infer MetaTrader 5. Full account matrix and detailed commercial/rule terms remain unstated; retain in_review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fxify' and p.slug = 'lightning-challenge'
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30 00:00:00+00'::timestamptz and v.notes like 'Rechecked official Lightning product page 2026-09-30.%');
