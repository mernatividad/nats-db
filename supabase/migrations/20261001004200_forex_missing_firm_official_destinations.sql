begin;
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.affiliate_destinations
  (firm_id, kind, label, destination_url, is_primary, status)
select f.id, 'official_site', 'Visit ' || f.name, f.website_url, true, 'active'
from bullish_banana.firms f
where f.slug in ('hantec-trader','instant-funding','leveraged','thinkcapital')
  and f.website_url like 'https://%'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.kind = 'official_site'
  );

commit;
