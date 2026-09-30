begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
  'restricted_jurisdictions', jsonb_build_array(
    'Afghanistan','American Samoa','Australia','Belarus','Cuba','Guam','Iran','Iraq',
    'Myanmar','North Korea','Russia','Somalia','Syria','United States',
    'US Minor Outlying Islands','Yemen'
  ),
  'jurisdiction_notes', 'Blueberry Funded Help Center states on 2026-07-02 that new evaluation purchases are currently restricted from Afghanistan, American Samoa, Australia, Belarus, Cuba, Guam, Iran, Iraq, Myanmar, North Korea, Russia, Somalia, Syria, the United States, US Minor Outlying Islands, and Yemen. The terms schedule is older and contains a different list; this profile preserves the current purchase FAQ scope. Check current checkout availability.',
  'jurisdiction_source_reviewed', '2026-09-30'
), updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'blueberry-funded';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id,
  'https://help.blueberryfunded.com/en/articles/9550574-are-any-countries-restricted-from-purchasing-an-evaluation',
  'Current evaluation purchase restriction FAQ — reviewed 2026-09-30',
  'Official Help Center article dated 2026-07-02 lists 16 locations currently blocked from evaluation purchases. The list is distinguished from an older contractual schedule; availability should be checked in current checkout.'
from bullish_banana.firms f
where f.slug = 'blueberry-funded'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id = f.id and s.source_url = 'https://help.blueberryfunded.com/en/articles/9550574-are-any-countries-restricted-from-purchasing-an-evaluation');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T14:20:00Z'::timestamptz,
  'Rechecked the official Help Center purchase restriction article. Its current list is dated 2026-07-02 and differs from the older agreement schedule; the source-specific scopes are preserved.'
from bullish_banana.firms f
where f.slug = 'blueberry-funded'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T14:20:00Z'::timestamptz);

commit;
