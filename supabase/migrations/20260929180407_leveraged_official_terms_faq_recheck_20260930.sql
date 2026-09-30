-- Leveraged first-party recheck captured 2026-09-30.
-- Corrects ONE $100K selector fee and clarifies Turbo activation credit; keep unresolved capacity conflicts in review.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = p.commercial_details || case p.slug
  when 'leveraged-one' then '{"account_size_prices":[{"account_size":100000,"fee":188,"currency":"USD","platform":"MT5","sku":"leveragedone100k_mt5","verified_at":"2026-09-30"}],"price_conflict":null,"price_capture":"Official read-only checkout selection Leveraged ONE + $100K + MT5 returned SKU leveragedone100k_mt5 at $188 on 2026-09-30, agreeing with current ONE page. This supersedes the prior $99 observation; other size fees were not rechecked."}'::jsonb
  when 'turbo' then '{"pricing_note":"The current official FAQ explicitly states that the $8.88 initial fee is credited toward activation. Preserve these as payment stages and do not add the initial fee a second time to the activation fee.","allocation_conflict":"Official FAQ and selector show up to $200K; Terms cap aggregate active Turbo balance at $150K. Keep in review."}'::jsonb
  when 'sprint' then '{"allocation_conflict":"Official FAQ and product page show up to $100K, but Terms cap Sprint allocation at $10K. Keep in review."}'::jsonb
  else '{}'::jsonb end,
updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='leveraged'
and p.slug in ('leveraged-one','turbo','sprint');

update bullish_banana.sources s
set notes='Read-only checkout check 2026-09-30: selected Leveraged ONE + $100K + MT5; observed SKU leveragedone100k_mt5 at $188, agreeing with the current ONE page. This supersedes the prior $99 observation. No cart action.'
from bullish_banana.firms f
where s.firm_id=f.id and f.slug='leveraged'
and s.source_url='https://checkout.getleveraged.com/product/leveraged/';

update bullish_banana.sources s
set notes='Refreshed 2026-09-30. FAQ confirms the $8.88 initial payment is credited against activation. Sizes/activation fees remain listed; FAQ capacity up to $200K conflicts with Terms cap of $150K.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where s.program_id=p.id and f.slug='leveraged' and p.slug='turbo'
and s.source_url='https://getleveraged.com/faq/what-is-the-turbo-program/';

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes from bullish_banana.firms f
join (values
 ('https://getleveraged.com/one/','Leveraged ONE page recheck 2026-09-30','Current page advertises $188 for $100K and current ONE rules.'),
 ('https://getleveraged.com/faq/what-is-the-turbo-program/','Turbo activation fee credit recheck 2026-09-30','FAQ states initial $8.88 is credited toward activation; Turbo $200K FAQ capacity conflicts with Terms $150K cap.'),
 ('https://getleveraged.com/faq/what-is-the-sprint-program/','Sprint allocation recheck 2026-09-30','FAQ lists sizes through $100K; Terms still state $10K maximum.'),
 ('https://getleveraged.com/faq/what-is-the-maximum-capital-allocation/','Maximum allocation recheck 2026-09-30','FAQ states Turbo $200K, Sprint $100K and Jr PM $5K; Turbo/Sprint conflict with Terms.')
) as x(url,label,notes) on true
where f.slug='leveraged'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url and s.notes like '%2026-09-30%');

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'Official ONE page, Turbo/Sprint FAQs, maximum-allocation FAQ and read-only ONE $100K MT5 selector rechecked 2026-09-30. ONE price now agrees at $188; Turbo initial fee credit clarified; Turbo/Sprint allocation conflicts with Terms persist. Programs remain in review.'
from bullish_banana.firms f where f.slug='leveraged';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),case p.slug
 when 'leveraged-one' then 'Read-only official checkout selected Leveraged ONE + $100K + MT5; SKU leveragedone100k_mt5 returned $188 on 2026-09-30, agreeing with the current ONE page. Other size/platform prices and restrictions remain open.'
 when 'turbo' then 'Current official FAQ confirms the initial $8.88 is credited toward activation. $200K FAQ capacity conflicts with $150K Terms cap; program remains in review.'
 when 'sprint' then 'Current official FAQ/product page confirms up to $100K, conflicting with $10K Terms cap; program remains in review.'
 else 'Official FAQ and Terms rechecked 2026-09-30; preserve the material allocation conflict and keep in review.' end
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='leveraged' and p.slug in ('leveraged-one','turbo','sprint','jr-portfolio-manager','sr-portfolio-manager','exec-portfolio-manager');
