begin;

-- The six currently offered For Traders Forex products have current first-party
-- offer pages, size/price records, product rules and dated verification. Open
-- price, platform and legal-source caveats remain visible on public details.
update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'for-traders'
  and p.market_type = 'forex'
  and p.slug in ('fast-1-step', 'fast-static-1-step', 'classic-2-step', 'pay-after-pass-1-step', 'instant-forex', 'instant-pro-forex')
  and p.status = 'in_review';

update bullish_banana.firms
set status = 'published',
    published_at = coalesce(published_at, now()),
    archived_at = null,
    updated_at = now()
where slug = 'for-traders' and status = 'in_review';

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, null, 'official_site', 'Visit For Traders official site', 'https://fortraders.com/challenges?step=1', true, 'active'
from bullish_banana.firms f
where f.slug = 'for-traders'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.status = 'active'
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:02:00Z'::timestamptz,
  'Published the six currently offered Forex programs after reviewing current official offer pages, rules and live-selector captures. Public records preserve unresolved selector/marketing price differences, per-size platform availability, the Terms/footer company and country-list discrepancies, temporary promotions, and terms the firm does not state; verify order-specific terms at checkout.'
from bullish_banana.firms f
where f.slug = 'for-traders'
  and not exists (
    select 1 from bullish_banana.data_verifications v
    where v.firm_id = f.id and v.program_id is null and v.verified_at = '2026-09-30T13:02:00Z'::timestamptz
  );

commit;
