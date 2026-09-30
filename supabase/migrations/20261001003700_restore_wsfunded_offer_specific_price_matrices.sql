begin;
set search_path = bullish_banana, extensions, public;

-- Restore each offer's own selector matrix after the Elite-only current-price
-- refresh; do not copy Elite amounts across unrelated Wall Street products.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || x.details::jsonb,
    updated_at = now()
from bullish_banana.firms f
join (values
 ('rapid', $$ {"account_size_prices":[{"account_size":2500,"fee":25,"currency":"USD"},{"account_size":5000,"fee":57,"list_fee":69,"currency":"USD"},{"account_size":10000,"fee":95,"list_fee":105,"currency":"USD"},{"account_size":25000,"fee":199,"list_fee":259,"currency":"USD"},{"account_size":50000,"fee":299,"list_fee":379,"currency":"USD"},{"account_size":100000,"fee":529,"list_fee":589,"currency":"USD"}],"pricing_note":"Current public selector paired prices captured 2026-09-30; $2,500 row showed $25 without a paired list price. Homepage promotion conditions/expiry are unknown and no coupon adjustment is inferred."} $$),
 ('classic', $$ {"account_size_prices":[{"account_size":2500,"fee":27,"list_fee":33,"currency":"USD"},{"account_size":5000,"fee":55,"list_fee":59,"currency":"USD"},{"account_size":10000,"fee":87,"list_fee":99,"currency":"USD"},{"account_size":25000,"fee":193,"list_fee":259,"currency":"USD"},{"account_size":50000,"fee":319,"list_fee":369,"currency":"USD"},{"account_size":100000,"fee":563,"list_fee":579,"currency":"USD"}],"pricing_note":"Current public selector displayed paired list/current amounts captured 2026-09-30. Confirm promotion eligibility and final payable amount at checkout."} $$),
 ('ultra', $$ {"account_size_prices":[{"account_size":2500,"fee":23,"list_fee":33,"currency":"USD"},{"account_size":5000,"fee":49,"list_fee":59,"currency":"USD"},{"account_size":10000,"fee":79,"list_fee":89,"currency":"USD"},{"account_size":25000,"fee":193,"list_fee":209,"currency":"USD"},{"account_size":50000,"fee":299,"list_fee":349,"currency":"USD"},{"account_size":100000,"fee":529,"list_fee":559,"currency":"USD"}],"pricing_note":"Current public selector displayed paired list/current amounts captured 2026-09-30. Confirm promotion eligibility and final payable amount at checkout."} $$),
 ('elite', $$ {"account_size_prices":[{"account_size":2500,"fee":39,"currency":"USD"},{"account_size":5000,"fee":59,"currency":"USD"},{"account_size":10000,"fee":109,"currency":"USD"},{"account_size":25000,"fee":229,"currency":"USD"},{"account_size":50000,"fee":339,"currency":"USD"},{"account_size":100000,"fee":629,"currency":"USD"}],"pricing_note":"Current selector rechecked 2026-09-30 displays regular prices $39, $59, $109, $229, $339 and $629 without paired discounted amounts. Earlier captured discounted values are stale. Homepage promotion is separate; no coupon adjustment is inferred."} $$),
 ('instant-pro', $$ {"account_size_prices":[{"account_size":2500,"fee":49,"list_fee":60,"currency":"USD"},{"account_size":5000,"fee":79,"list_fee":85,"currency":"USD"},{"account_size":10000,"fee":102,"list_fee":115,"currency":"USD"},{"account_size":25000,"fee":199,"list_fee":232,"currency":"USD"},{"account_size":50000,"fee":299,"list_fee":345,"currency":"USD"},{"account_size":100000,"fee":499,"list_fee":562,"currency":"USD"}],"pricing_note":"Current public selector paired prices captured 2026-09-30. Confirm promotion eligibility and final payable amount at checkout."} $$),
 ('instant-standard', $$ {"account_size_prices":[{"account_size":2500,"fee":90,"list_fee":105,"currency":"USD"},{"account_size":5000,"fee":225,"list_fee":250,"currency":"USD"},{"account_size":10000,"fee":440,"list_fee":465,"currency":"USD"},{"account_size":25000,"fee":800,"list_fee":845,"currency":"USD"},{"account_size":50000,"fee":1800,"list_fee":1869,"currency":"USD"}],"pricing_note":"Current public selector paired prices captured 2026-09-30. Confirm promotion eligibility and final payable amount at checkout."} $$),
 ('power', $$ {"account_size_prices":[{"account_size":5000,"fee":9.99,"post_pass_fee":48,"currency":"USD"},{"account_size":10000,"fee":9.99,"post_pass_fee":76,"currency":"USD"},{"account_size":25000,"fee":9.99,"post_pass_fee":180,"currency":"USD"},{"account_size":50000,"fee":9.99,"post_pass_fee":340,"currency":"USD"},{"account_size":100000,"fee":9.99,"post_pass_fee":540,"currency":"USD"}],"pricing_note":"Power FAQ lists $9.99 initial fee and a separate size-specific funded-stage payment. Homepage offer promotion terms are not applied to these staged fees."} $$)
) as x(slug,details) on true
where p.firm_id = f.id and f.slug = 'wall-street-funded' and p.slug = x.slug;

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T14:08:00Z'::timestamptz,
  case when p.slug = 'elite'
    then 'Rechecked the current selector. Elite alone has the current $39/$59/$109/$229/$339/$629 regular-price matrix without paired discounts; prior discounted values are stale.'
    else 'Restored and rechecked this offer-specific size/price matrix against the current selector or Power FAQ. Prices for other Wall Street offers are recorded separately; no unrelated offer matrix or homepage coupon adjustment is applied.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'wall-street-funded'
  and p.slug in ('rapid','power','classic','ultra','elite','instant-pro','instant-standard')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T14:08:00Z'::timestamptz);

commit;
