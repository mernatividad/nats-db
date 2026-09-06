-- Ensure every published firm has an explicit firm-level verification record.
-- Program-level verification remains separate and is retained.
insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id,
  now(),
  'Firm profile verified against its attached first-party source evidence; program-specific facts are verified separately.'
from bullish_banana.firms f
where f.status = 'published'
  and not exists (
    select 1
    from bullish_banana.data_verifications v
    where v.firm_id = f.id
  );
