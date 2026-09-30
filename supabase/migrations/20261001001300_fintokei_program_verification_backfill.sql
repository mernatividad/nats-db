begin;

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), case p.slug
  when 'fintokei-starttrader' then 'Program details reviewed against the current Fintokei programs catalog and StartTrader rules FAQ on 2026-09-30. Challenge phases, displayed USD sizes/prices, core rules and payout references are source-linked. The firm remains in review because current catalog asset availability conflicts with an older official instruments FAQ; this verification does not resolve that firm-level conflict.'
  when 'fintokei-swifttrader' then 'Program details reviewed against the current Fintokei programs catalog, SwiftTrader product FAQ and payout-ratio FAQ on 2026-09-30. Purchase-date-dependent reward terms and displayed USD sizes/prices are source-linked. The firm remains in review because current catalog asset availability conflicts with an older official instruments FAQ; this verification does not resolve that firm-level conflict.'
  when 'fintokei-protrader' then 'Program details reviewed against the current Fintokei programs catalog, ProTrader rules FAQ, and ProTrader-versus-Swing loss-calculation FAQ on 2026-09-30. Phase terms, EOD equity calculation, displayed USD sizes/prices and payout references are source-linked. The firm remains in review because current catalog asset availability conflicts with an older official instruments FAQ; this verification does not resolve that firm-level conflict.'
  when 'fintokei-protrader-swing' then 'Program details reviewed against the current Fintokei programs catalog, ProTrader rules FAQ, and ProTrader-versus-Swing loss-calculation FAQ on 2026-09-30. Phase terms, EOD balance calculation, purchase-date swap-free condition, displayed USD sizes/prices and payout references are source-linked. The firm remains in review because current catalog asset availability conflicts with an older official instruments FAQ; this verification does not resolve that firm-level conflict.'
end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing')
  and not exists (
    select 1 from bullish_banana.data_verifications v where v.program_id = p.id
  );

commit;
