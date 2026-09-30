begin;
set search_path = bullish_banana, extensions, public;

-- AquaFunded's current official page says Try Aqua has ended. Retain the
-- legacy offer rows for history and remove them from active public surfaces.
update bullish_banana.programs p
set status = 'archived', archived_at = coalesce(p.archived_at, now()),
    published_at = null, updated_at = now(),
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'availability_status', 'ended; not currently offered',
      'archived_reason', 'AquaFunded’s current official Try Aqua page states the offer has ended. A legacy product subdomain still exposes an old selector, which is not treated as evidence of current availability.',
      'archived_reviewed_at', '2026-10-01',
      'archived_source', 'https://www.aquafunded.com/try-aqua'
    )
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'aquafunded'
  and p.slug in ('tryaqua-1', 'tryaqua-10') and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

update bullish_banana.affiliate_destinations d
set status = 'inactive', updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where d.program_id = p.id and f.slug = 'aquafunded'
  and p.slug in ('tryaqua-1', 'tryaqua-10');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://www.aquafunded.com/try-aqua',
  'AquaFunded Try Aqua ended availability status — 2026-10-01',
  'The current official AquaFunded Try Aqua page says the offer has ended and directs visitors to other challenges. A legacy product subdomain still shows a $1–$10 selector; it is retained as historical context, not treated as a current offer.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'aquafunded' and p.slug in ('tryaqua-1', 'tryaqua-10')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'AquaFunded Try Aqua ended availability status — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked AquaFunded’s current official Try Aqua page: the offer is marked ended. Archived the legacy row and disabled its destination; the old subdomain selector is not used to represent a current product.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'aquafunded' and p.slug in ('tryaqua-1', 'tryaqua-10')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked AquaFunded’s current official Try Aqua page: the offer is marked ended. Archived the legacy row and disabled its destination; the old subdomain selector is not used to represent a current product.');

-- Current FTMO 1-Step fees in the provider's EUR price presentation.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', jsonb_build_array(
        jsonb_build_object('account_size', 10000, 'currency', 'EUR', 'fee', 79),
        jsonb_build_object('account_size', 25000, 'currency', 'EUR', 'fee', 199),
        jsonb_build_object('account_size', 50000, 'currency', 'EUR', 'fee', 319),
        jsonb_build_object('account_size', 100000, 'currency', 'EUR', 'fee', 399, 'regular_fee', 499, 'promotional', true),
        jsonb_build_object('account_size', 200000, 'currency', 'EUR', 'fee', 999)
      ),
      'pricing_note', 'Official FTMO EUR price page lists one-time fees of €79/€199/€319/€399/€999 for $10K/$25K/$50K/$100K/$200K. The $100K page shows €399 alongside €499; the lower value is recorded as the displayed promotion. The 1-Step fee is non-refundable. Currency and checkout availability may vary by market.'
    ), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'ftmo' and p.slug = 'ftmo-1-step'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://promo.ftmo.com/u26a-your-1-step/',
  'FTMO 1-Step official EUR fee matrix — 2026-10-01',
  'Current official FTMO 1-Step page lists EUR one-time fees by simulated account size: €79, €199, €319, €399 (displayed with €499), and €999 for $10K, $25K, $50K, $100K, and $200K. Official fee FAQ confirms the 1-Step payment is not refunded after passing. Regional checkout currency can vary.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'ftmo' and p.slug = 'ftmo-1-step' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'FTMO 1-Step official EUR fee matrix — 2026-10-01');

-- Goat Funded Trader's current model-specific Help Center publishes its $1 fee.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', jsonb_build_array(jsonb_build_object(
        'account_size', 1000, 'currency', 'USD', 'fee', 1, 'verified_at', '2026-10-01'
      )),
      'pricing_note', 'The current official Goat $1 model guide lists a one-time $1 price for the only available $1,000 size. Confirm the live purchase selector before buying.'
    ), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'goat-funded-trader'
  and p.slug = 'goat-1-dollar' and p.market_type = 'forex'
  and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.goatfundedtrader.com/en/articles/11769239-goat-1-model',
  'Goat Funded Trader $1 model price and size — 2026-10-01',
  'The current official Help Center article lists a $1 price and $1,000 account size, and states it is the only available size. The purchase selector remains the final availability check.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'goat-funded-trader' and p.slug = 'goat-1-dollar' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'Goat Funded Trader $1 model price and size — 2026-10-01');

-- Hyper Growth's public plan matrix shows a dash for its one-time fee; the
-- adjacent Pro Growth fee belongs to a different offer.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'pricing_note', 'The current official plan comparison shows a dash for Hyper Growth’s one-time fee and lists bonuses from $15; the adjacent $74 one-time fee belongs to Pro Growth. The dash is not treated as proof of a free checkout. Confirm any amount and current starting size in the provider checkout.'
    ), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'the5ers' and p.slug = 'hyper-growth'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://the5ers.com/hyper-growth/',
  'The5ers Hyper Growth current fee disclosure — 2026-10-01',
  'Current official plan matrix shows a dash in the Hyper Growth one-time-fee column, while the neighboring Pro Growth offer lists $74. The page separately lists Hyper Growth bonuses from $15. No Hyper Growth entry fee is inferred from the neighboring offer.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'hyper-growth' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'The5ers Hyper Growth current fee disclosure — 2026-10-01');

-- Refresh High Stakes fee evidence only where the current public page is
-- explicit; do not preserve the unsupported old $100K price.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', jsonb_build_array(
        jsonb_build_object('account_size', 2500, 'currency', 'USD', 'fee', 19, 'price_scope', 'public plan table'),
        jsonb_build_object('account_size', 100000, 'currency', 'USD', 'fee', 149, 'promotional', true, 'price_scope', 'limited-time page banner')
      ),
      'pricing_note', 'The current official page displays $19 for its selected $2.5K plan and a separate limited-time $100K offer for $149. It does not expose a complete fee matrix for the $5K, $10K, $25K, and $50K selectors in the captured public page. The $100K banner may expire; verify size-specific totals at checkout.'
    ), updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'the5ers' and p.slug = 'high-stakes'
  and p.market_type = 'forex' and p.status in ('published', 'in_review');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://the5ers.com/high-stakes/',
  'The5ers High Stakes current public price evidence — 2026-10-01',
  'Current official High Stakes page shows a $2.5K selected configuration at $19 and separately advertises a limited-time $100K offer for $149. The captured page does not supply fees for all other selectable sizes; these values are not extrapolated.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'the5ers' and p.slug = 'high-stakes' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s where s.program_id = p.id
    and s.source_label = 'The5ers High Stakes current public price evidence — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked the current official price source. Only directly displayed account-size prices are stored; promotions, regional currency and unpublished size-specific fees remain explicitly scoped.'
from bullish_banana.programs p join bullish_banana.firms f on f.id = p.firm_id
where p.market_type = 'forex' and p.status in ('published', 'in_review')
  and ((f.slug = 'ftmo' and p.slug = 'ftmo-1-step')
    or (f.slug = 'goat-funded-trader' and p.slug = 'goat-1-dollar')
    or (f.slug = 'the5ers' and p.slug in ('hyper-growth', 'high-stakes')))
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked the current official price source. Only directly displayed account-size prices are stored; promotions, regional currency and unpublished size-specific fees remain explicitly scoped.');

commit;
