-- Recapture ThinkCapital's current official product-page USD fee matrices.
-- The captured matrices match the existing values; this refresh records the
-- current page selectors, dates, and source trail. Keep programs in_review:
-- current Terms/Demo Agreement conflict with current Dual Step product pages.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = p.commercial_details || jsonb_build_object(
      'account_size_prices', case p.slug
        when 'lightning' then '[
          {"account_size":5000,"fee":59,"currency":"USD"},
          {"account_size":10000,"fee":99,"currency":"USD"},
          {"account_size":25000,"fee":199,"currency":"USD"},
          {"account_size":50000,"fee":299,"currency":"USD"},
          {"account_size":100000,"fee":499,"currency":"USD"}
        ]'::jsonb
        when 'dual-step-intraday' then '[
          {"account_size":5000,"fee":59,"currency":"USD"},
          {"account_size":10000,"fee":99,"currency":"USD"},
          {"account_size":25000,"fee":199,"currency":"USD"},
          {"account_size":50000,"fee":299,"currency":"USD"},
          {"account_size":100000,"fee":499,"currency":"USD"}
        ]'::jsonb
        when 'dual-step-swing' then '[
          {"account_size":5000,"fee":82,"currency":"USD"},
          {"account_size":10000,"fee":138,"currency":"USD"},
          {"account_size":25000,"fee":278,"currency":"USD"},
          {"account_size":50000,"fee":418,"currency":"USD"},
          {"account_size":100000,"fee":698,"currency":"USD"}
        ]'::jsonb
        when 'nexus' then '[
          {"account_size":5000,"fee":39,"currency":"USD"},
          {"account_size":10000,"fee":79,"currency":"USD"},
          {"account_size":25000,"fee":139,"currency":"USD"},
          {"account_size":50000,"fee":199,"currency":"USD"},
          {"account_size":100000,"fee":349,"currency":"USD"}
        ]'::jsonb
        when 'bolt-instant-funding' then '[
          {"account_size":2500,"fee":49,"currency":"USD"},
          {"account_size":5000,"fee":89,"currency":"USD"},
          {"account_size":10000,"fee":159,"currency":"USD"},
          {"account_size":25000,"fee":349,"currency":"USD"},
          {"account_size":50000,"fee":599,"currency":"USD"}
        ]'::jsonb
      end,
      'pricing_capture','Full visible USD size/fee matrix recaptured from the current official product-page selector on 2026-09-30. Prices match the earlier selector snapshot. This is list-price evidence; no promotion or coupon was applied.',
      'pricing_capture_date','2026-09-30',
      'price_configuration','Five sizes are displayed for this program by the current official selector. Price is recorded in USD. Fee matrix is selector list price, before any checkout code or optional add-on.'
    ),
    updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='thinkcapital'
  and p.slug in ('lightning','dual-step-intraday','dual-step-swing','nexus','bolt-instant-funding');

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes
from bullish_banana.firms f
join (values
  ('https://www.thinkcapital.com/lightning/','Lightning visible size/fee matrix recheck — 2026-09-30','Current selector exposes $5K/$59, $10K/$99, $25K/$199, $50K/$299 and $100K/$499 USD list prices. Page also lists a 10% target, 3% balance-based daily loss, 6% trailing maximum loss, 80% split and payout add-ons. Governing Terms/Demo Agreement conflicts remain.'),
  ('https://www.thinkcapital.com/dual-step/','Dual Step visible size/fee matrix recheck — 2026-09-30','Current selector exposes Intraday $5K/$59, $10K/$99, $25K/$199, $50K/$299, $100K/$499 and Swing $5K/$82, $10K/$138, $25K/$278, $50K/$418, $100K/$698 USD list prices. Current product page objectives conflict with Terms/Demo Agreement.'),
  ('https://www.thinkcapital.com/nexus/','Nexus visible size/fee matrix recheck — 2026-09-30','Current selector exposes $5K/$39, $10K/$79, $25K/$139, $50K/$199 and $100K/$349 USD list prices. Price matrix matches the earlier staged capture; rule reconciliation remains.'),
  ('https://www.thinkcapital.com/instant-funding/','Bolt visible size/fee matrix recheck — 2026-09-30','Current selector exposes $2.5K/$49, $5K/$89, $10K/$159, $25K/$349 and $50K/$599 USD list prices. The Bolt page still has conflicting drawdown-lock descriptions; price data does not resolve that conflict.')
) as x(url,label,notes) on true
where f.slug='thinkcapital'
  and not exists (
    select 1 from bullish_banana.sources s where s.firm_id=f.id
      and s.source_url=x.url and s.source_label=x.label
  );

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,'Current visible USD fee matrix — 2026-09-30',x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
  ('lightning','https://www.thinkcapital.com/lightning/','Selector matrix: $5K/$59, $10K/$99, $25K/$199, $50K/$299, $100K/$499. Current Terms/Demo Agreement conflict with some product-page trading conditions.'),
  ('dual-step-intraday','https://www.thinkcapital.com/dual-step/','Selector matrix: $5K/$59, $10K/$99, $25K/$199, $50K/$299, $100K/$499. Product-page target and challenge maximum-loss values conflict with current Terms/Demo Agreement.'),
  ('dual-step-swing','https://www.thinkcapital.com/dual-step/','Selector matrix: $5K/$82, $10K/$138, $25K/$278, $50K/$418, $100K/$698. Product-page target and challenge maximum-loss values conflict with current Terms/Demo Agreement.'),
  ('nexus','https://www.thinkcapital.com/nexus/','Selector matrix: $5K/$39, $10K/$79, $25K/$139, $50K/$199, $100K/$349. Price refresh does not resolve any current rule/agreement conflicts.'),
  ('bolt-instant-funding','https://www.thinkcapital.com/instant-funding/','Selector matrix: $2.5K/$49, $5K/$89, $10K/$159, $25K/$349, $50K/$599. Price refresh does not resolve conflicting drawdown-lock explanations.')
) as x(program_slug,url,notes) on x.program_slug=p.slug
where f.slug='thinkcapital'
  and not exists (
    select 1 from bullish_banana.sources s where s.program_id=p.id
      and s.source_url=x.url and s.source_label='Current visible USD fee matrix — 2026-09-30'
  );

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),
       'Official current program-page selectors for Lightning, Dual Step, Nexus and Bolt rechecked 2026-09-30. All five visible USD price matrices are complete and match the existing fee data. Current Terms/Demo Agreement conflicts for Dual Step and Bolt remain unresolved; all programs stay in_review.'
from bullish_banana.firms f where f.slug='thinkcapital';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),
       'Current official product-page selector fee matrix recaptured 2026-09-30; all visible USD account sizes and base fees are recorded. Price values match the earlier staged snapshot. Program remains in_review pending current rule, agreement, platform and eligibility reconciliation.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='thinkcapital'
  and p.slug in ('lightning','dual-step-intraday','dual-step-swing','nexus','bolt-instant-funding');
