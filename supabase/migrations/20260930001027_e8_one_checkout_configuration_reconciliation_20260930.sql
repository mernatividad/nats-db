-- Reconcile the E8 One Forex standard account against E8's live public configurator.
-- The old Help Center article still publishes conflicting preset rules; preserve
-- that discrepancy in the public detail instead of silently dropping the source.

update bullish_banana.programs p
set status='published',
    profit_split_percent=80,
    commercial_details=p.commercial_details || jsonb_build_object(
      'price_configuration',
      'The official no-discount base price matrix is paired with the standard checkout configuration: 80% payout, 6% dynamic drawdown and 4% daily drawdown. E8''s live Forex configurator shows the $100K example at $488 base, 6% dynamic drawdown ($6,000), 4% daily drawdown ($4,000), and a $9,000 target. The page currently advertises a separate first-order promo; it is excluded from base fees.',
      'challenge_rules',
      'Standard Forex checkout: one phase; 9% target with 6% dynamic drawdown and 4% daily drawdown. The live configurator describes the target as 1.5x selected drawdown and daily drawdown as 66% of selected drawdown. Available dynamic drawdown selections are 4%, 6%, 8%, 10% and 14%; corresponding daily limits are 3%, 4%, 5.3%, 6.6% and 9.2%, with targets 6%, 9%, 12%, 15% and 21%. No time limit; at least one trade must be opened and closed every 60 days.',
      'open_fields',
      'Published standard checkout is supported by the current official configurator and base-price article. The separate E8 One Help Center rules article still labels 6% target, 3% daily and 4% dynamic drawdown as preset; this conflicts with the current configurator and pricing article, so retain the discrepancy as a source note. Custom settings change price and rules.',
      'verified_at', '2026-09-30'
    ),
    published_at=coalesce(p.published_at,now()),
    updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='e8-markets' and p.slug='e8-one-forex';

update bullish_banana.program_phases ph
set profit_target_percent=9,
    daily_drawdown_percent=4,
    maximum_drawdown_percent=6,
    drawdown_type='dynamic',
    raw_rules=coalesce(ph.raw_rules,'{}'::jsonb) || jsonb_build_object(
      'standard_checkout', jsonb_build_object('payout_percent',80,'dynamic_drawdown_percent',6,'daily_drawdown_percent',4,'profit_target_percent',9),
      'custom_drawdown_options', jsonb_build_array(4,6,8,10,14),
      'custom_daily_drawdown_options', jsonb_build_array(3,4,5.3,6.6,9.2),
      'custom_profit_target_options', jsonb_build_array(6,9,12,15,21),
      'source_conflict', 'Current official configurator and base-price article show the standard checkout as 9% target / 4% daily / 6% dynamic. The Help Center rules article still calls 6% target / 3% daily / 4% dynamic the preset. Keep this conflict disclosed.'
    )
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where ph.program_id=p.id and p.slug='e8-one-forex' and f.slug='e8-markets' and ph.phase_number=1;

update bullish_banana.firm_profiles fp
set profile_details=fp.profile_details || jsonb_build_object(
      'verification_note', 'Firm and challenge profile reviewed 2026-09-30. The current E8 One Forex configurator and its base-price article agree on the standard checkout settings; the Help Center rules page retains a conflicting preset description.'
    ),
    updated_at=now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='e8-markets';

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,'https://e8markets.com/e8-one','E8 One live Forex configurator',
       'Official current product/configurator reviewed 2026-09-30. Its $100K standard selection displays $488 base price, 6% dynamic drawdown, $4,000 daily drawdown, $9,000 target and 80% payout; current site also advertises a separate first-order promotion. Supports standard checkout mapping and configurable ranges.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where f.slug='e8-markets' and p.slug='e8-one-forex'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url='https://e8markets.com/e8-one');

update bullish_banana.sources s
set notes='Official Help Center article reviewed 2026-09-30. It lists E8 One configurable drawdown/target ranges and the no-discount base price matrix, and states that standard checkout is 80% payout, 6% dynamic drawdown and 4% daily drawdown. Its separate E8 One rules article still labels 6% target, 3% daily and 4% dynamic drawdown as preset; this discrepancy is preserved in the catalog detail.'
from bullish_banana.programs p
where s.program_id=p.id and p.slug='e8-one-forex'
and s.source_url='https://help.e8markets.com/en/articles/8880316-what-is-the-custom-account';

update bullish_banana.data_verifications v
set verified_at=now(),
    notes='Rechecked 2026-09-30 against the current official E8 One Forex configurator, base-price/custom-account article and E8 One rules article. The live configurator and pricing article support publishing the standard 80% payout, 6% dynamic, 4% daily and 9% target mapping; the Help Center rules article still shows a conflicting preset. Conflict is disclosed in commercial details.'
from bullish_banana.programs p join bullish_banana.firms f on f.id=p.firm_id
where v.program_id=p.id and p.slug='e8-one-forex' and f.slug='e8-markets';
