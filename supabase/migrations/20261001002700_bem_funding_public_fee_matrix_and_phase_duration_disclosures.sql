begin;

-- Convert the already-reviewed selector fee captures into the normalized rows
-- used by public detail pages, comparison tools, and the release verifier.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', (
        select jsonb_agg(
          jsonb_build_object('account_size', fee.account_size, 'fee', fee.amount, 'currency', 'USD')
          order by fee.account_size
        )
        from (
          select entry.key::integer as account_size, entry.value::numeric as amount
          from jsonb_each_text(p.commercial_details #> '{selector_fee_matrix_2026_09_30,account_size_fee_usd}') as entry
        ) fee
      ),
      'price_configuration', case p.slug
        when 'bem-one' then 'Official selector base fees: $5K $47; $10K $89; $25K $194; $50K $285; $100K $520; $200K $790. Captured on 2026-09-30; the live selector showed the same base prices on MT5 and cTrader. Current discounts are listed separately and may expire.'
        when 'bem-one-only' then 'Official selector base fees: $5K $40; $10K $90; $25K $180; $50K $270; $100K $460; $200K $750. Captured on 2026-09-30; the live selector showed the same base prices on MT5 and cTrader. Current discounts are listed separately and may expire.'
        when 'bem-classic-normal' then 'Official selector base fees: $5K $39; $10K $99; $25K $211; $50K $321; $100K $519. Captured on 2026-09-30; the live selector showed the same base prices on MT5 and cTrader. Current discounts are listed separately and may expire.'
        when 'bem-classic-swing' then 'Official selector base fees: $5K $69; $10K $155; $25K $296; $50K $447; $100K $890. Captured on 2026-09-30; the live selector showed the same base prices on MT5 and cTrader. Current discounts are listed separately and may expire.'
      end,
      'promotion_note', case p.slug
        when 'bem-one' then 'The 2026-09-30 selector capture displayed a 30% offer.'
        when 'bem-one-only' then 'The 2026-09-30 selector capture displayed a 40% offer.'
        when 'bem-classic-normal' then 'The 2026-09-30 selector capture displayed a 20% offer.'
        when 'bem-classic-swing' then 'The 2026-09-30 selector capture displayed a 5% offer.'
      end,
      'selector_base_fee_capture_date', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'bem-funding'
  and p.market_type = 'forex'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing')
  and jsonb_typeof(p.commercial_details #> '{selector_fee_matrix_2026_09_30,account_size_fee_usd}') = 'object';

-- The reviewed current rules describe challenge phases but publish no maximum
-- evaluation duration. Record that unknown explicitly without claiming it is unlimited.
update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'The current official program rules reviewed on 2026-09-30 do not state a maximum evaluation duration.',
      'time_limit_source_reviewed', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id
  and f.slug = 'bem-funding'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('bem-one', 'https://bemfunding.com/faq/bem-one-what-are-the-rules-for-the-bem-one', 'BEM ONE current evaluation rules', 'Reviewed 2026-09-30. The official FAQ specifies phase objectives and drawdown rules but does not state a maximum evaluation duration.'),
  ('bem-one-only', 'https://bemfunding.com/terms-of-use/bem-one-only', 'BEM ONE ONLY current Terms of Use', 'Reviewed 2026-09-30. The official account terms specify the evaluation phase and its rules but do not state a maximum evaluation duration.'),
  ('bem-classic-normal', 'https://bemfunding.com/faq/bem-classic-normal-what-are-the-rules-for-the-bem-classic-normal', 'BEM Classic Normal current evaluation rules', 'Reviewed 2026-09-30. The official FAQ specifies both evaluation phases and their rules but does not state a maximum evaluation duration.'),
  ('bem-classic-swing', 'https://bemfunding.com/faq/bem-classic-swing-how-does-the-bem-classic-swing-evaluation-work', 'BEM Classic Swing current evaluation rules', 'Reviewed 2026-09-30. The official FAQ specifies both evaluation phases and their rules but does not state a maximum evaluation duration.')
) as x(program_slug, source_url, source_label, notes) on x.program_slug = p.slug
where f.slug = 'bem-funding'
  and not exists (
    select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_url = x.source_url
  );

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:08:00Z'::timestamptz,
  'Current official selector base-fee matrices were normalized for four Forex offers; the captures showed identical fees on MT5 and cTrader, with temporary percentage offers preserved separately. Reviewed official phase rules do not state evaluation duration, so phase notes disclose that unknown. Existing platform operator, eligibility, Terms, and contracting-entity caveats remain visible.'
from bullish_banana.firms f
where f.slug = 'bem-funding'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T13:08:00Z'::timestamptz);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T13:08:00Z'::timestamptz,
  'Official selector base fees by size were captured on both MT5 and cTrader on 2026-09-30 and matched; dated discounts remain separate from base fees. Current official phase rules do not state a maximum evaluation duration. Platform/legal-entity and jurisdiction caveats remain disclosed in the program and firm records.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'bem-funding'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T13:08:00Z'::timestamptz);

update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'bem-funding'
  and p.market_type = 'forex'
  and p.slug in ('bem-one', 'bem-one-only', 'bem-classic-normal', 'bem-classic-swing')
  and p.status = 'in_review';

update bullish_banana.firms
set status = 'published',
    published_at = coalesce(published_at, now()),
    archived_at = null,
    updated_at = now()
where slug = 'bem-funding' and status = 'in_review';

insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, null, 'official_site', 'Visit BEM Funding official site', 'https://bemfunding.com/', true, 'active'
from bullish_banana.firms f
where f.slug = 'bem-funding'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.status = 'active'
  );

commit;
