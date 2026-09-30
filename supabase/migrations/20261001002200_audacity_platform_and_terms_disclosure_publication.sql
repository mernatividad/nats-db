begin;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'platform_scope_note', 'Official platform page lists MT5 and DXtrade. It does not map platform availability to each offer, account size, or country. The current legal footer says U.S. residents may participate only via DXtrade where permitted.',
      'publication_note', 'Published with open disclosures: the current site footer and older Terms differ in their provider and contracting-party descriptions, and fee-refund language differs between marketing and Terms. Review the cited source notes; no refund or contracting term is guaranteed beyond the stated evidence.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'audacity-capital';

update bullish_banana.firms f
set status = 'published',
    published_at = coalesce(f.published_at, now()),
    archived_at = null,
    updated_at = now()
where f.slug = 'audacity-capital' and f.status = 'in_review';

update bullish_banana.programs p
set status = 'published',
    published_at = coalesce(p.published_at, now()),
    archived_at = null,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'platform_availability_note', 'Audacity Capital’s current official platform page lists MT5 and DXtrade, but does not map availability by offer, size, or country. Its legal footer says U.S. residents may participate only via DXtrade where permitted; verify platform availability for this specific account before purchase.',
      'review_note', 'Published with disclosed source conflicts: current marketing describes funded-account rewards and conditional fee benefits, while older Terms use different provider language and state started fees are non-refundable. Do not assume a fee refund; verify the purchase-specific terms.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'audacity-capital'
  and p.slug in ('ability-challenge-2-step', 'ability-one-1-step', 'ftp-instant-funding')
  and p.status = 'in_review';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://audacity.capital/trading-platforms/', 'Audacity Capital trading platforms',
  'Current official platform page lists MetaTrader 5 and DXtrade. It does not map platform availability by offer, size, or country; the legal footer limits U.S. residents to DXtrade where permitted. Checked 2026-09-30.'
from bullish_banana.firms f
where f.slug = 'audacity-capital'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url='https://audacity.capital/trading-platforms/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://audacity.capital/trading-platforms/', 'Audacity Capital trading platforms',
  'The current official platform page lists MT5 and DXtrade but does not map availability by offer, size, or country. Current legal footer says U.S. residents may participate only via DXtrade where permitted. Checked 2026-09-30.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='audacity-capital' and p.slug in ('ability-challenge-2-step','ability-one-1-step','ftp-instant-funding')
  and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url='https://audacity.capital/trading-platforms/');

update bullish_banana.data_verifications v
set notes = concat_ws(' ',v.notes,'Rechecked the current official platform page on 2026-09-30. MT5 and DXtrade are listed generally; program, size, and country mapping remains unavailable. Existing provider and fee-refund source conflicts remain expressly disclosed.')
from bullish_banana.firms f
where v.firm_id=f.id and f.slug='audacity-capital';

update bullish_banana.data_verifications v
set notes = concat_ws(' ',v.notes,'Rechecked current program selector and platform page on 2026-09-30. MT5/DXtrade are firm-level options only; offer-specific platform mapping and older Terms conflicts remain disclosed on the published record.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where v.program_id=p.id and f.slug='audacity-capital'
  and p.slug in ('ability-challenge-2-step','ability-one-1-step','ftp-instant-funding');

commit;
