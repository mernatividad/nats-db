-- Refresh Crypto Fund Trader offer availability after a 2026-09-30 live selector/shop review.
-- The current site still documents 3-Phase rules in Terms/FAQ, but no 3-Phase SKU
-- appeared in the home selector or the three-page shop listing; hold it in review.
-- Break remains in review because the Break page says SOLD OUT, the shop lists it,
-- embedded home price cards differ from the shop/Terms, and daily-loss rules conflict.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set status = 'in_review',
    published_at = null,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_conflict', '2026-09-30: Official Terms/FAQ describe the Three-Phase Evaluation and publish rules/prices, but the live homepage selector and three-page official shop listing did not show a 3-Phase SKU. Confirm current checkout availability before publication.',
      'review_note', 'Candidate offer retained with sourced rules and fees; publication held until a current first-party purchase path confirms the SKU.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'crypto-fund-trader'
  and p.slug = '3-phase-evaluation';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_conflict', '2026-09-30: The Break landing page presents SOLD OUT, while the official paginated shop lists Break Evaluation and activation-fee products. Keep current orderability unconfirmed.',
      'price_source_conflict', '2026-09-30: Official shop and Terms list $25K/$70, $50K/$140, $100K/$200; the embedded homepage selector displays $25K/$70, $50K/$139, $100K/$199. Preserve the shop/Terms list prices and record the selector discrepancy.',
      'daily_loss_source_conflict', 'The Break page advertises no daily loss limit, while Terms impose size-specific daily loss caps of 4% ($25K), 4% ($50K), and 3% ($100K). Keep the rule in review.',
      'review_note', 'Do not publish as a fully verified active offer until orderability, evaluation price, and daily-loss rules are reconciled across current first-party pages.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'crypto-fund-trader'
  and p.slug = 'break-evaluation';

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.url, x.label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'crypto-fund-trader'
join (values
  ('https://cryptofundtrader.com/shop/', 'Crypto Fund Trader live shop (2026-09-30)', 'Three-page live shop listing reviewed; 3-Phase SKU not found. The current shop lists Break evaluation and activation products.'),
  ('https://cryptofundtrader.com/', 'Crypto Fund Trader homepage selector (2026-09-30)', 'Current visible offer selector exposes Instant, 1 Phase and 2 Phases; no 3-Phase SKU appears in the selector.'),
  ('https://cryptofundtrader.com/terms-and-conditions/', 'Crypto Fund Trader Terms (2026-09-30)', 'Terms still contain a Three-Phase fee schedule; retained as sourced candidate evidence, not as proof of current checkout availability.'),
  ('https://cryptofundtrader.com/faq/', 'Crypto Fund Trader FAQ (2026-09-30)', 'Current FAQ still describes Three-Phase rules, leverage, and reward timing; retained as candidate evidence pending orderability confirmation.')
) as x(url, label, notes) on p.slug = '3-phase-evaluation'
where not exists (
  select 1 from bullish_banana.sources s
  where s.program_id = p.id and s.source_url = x.url
);

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://cryptofundtrader.com/shop/', 'Crypto Fund Trader Break products in official shop (2026-09-30)',
       'The shop lists Break Evaluation products at $70/$140/$200 and activation products at $138/$198/$328 for $25K/$50K/$100K. The embedded homepage selector shows $139/$199 for the $50K/$100K evaluation price cards; the Break page presents SOLD OUT. Keep pricing and availability conflicts in review.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'crypto-fund-trader'
where p.slug = 'break-evaluation'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = 'https://cryptofundtrader.com/shop/'
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id and f.slug = 'crypto-fund-trader'
join (values
  ('3-phase-evaluation', '2026-09-30 live homepage selector and complete paginated official shop review did not confirm a current purchasable 3-Phase SKU. Current FAQ/Terms still document the product rules and price schedule. Reclassified the candidate to in_review until checkout availability is confirmed.'),
  ('break-evaluation', '2026-09-30 official Break page says SOLD OUT and claims no daily loss limit; official shop lists Break evaluations/activation products, and Terms specify size-dependent daily limits. Official shop/Terms list evaluation prices $70/$140/$200, while the embedded homepage selector displays $70/$139/$199. Keep the program in_review and retain source-specific prices/rule conflicts.')
) as x(program_slug, notes) on x.program_slug = p.slug
where not exists (
  select 1 from bullish_banana.data_verifications v
  where v.program_id = p.id and v.notes = x.notes
);
