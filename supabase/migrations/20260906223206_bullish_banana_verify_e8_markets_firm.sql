-- Complete the release evidence for the E8 Markets provider seeded in the
-- preceding catalog migration.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select firms.id, now(), 'Verified the E8 Markets provider against its first-party E8 One Perpetual help-center page; firm-level brand and official destination are present, while unavailable program fields remain explicitly unrepresented.'
from bullish_banana.firms
where firms.slug = 'e8-markets'
  and not exists (
    select 1
    from bullish_banana.data_verifications existing
    where existing.firm_id = firms.id
  );
