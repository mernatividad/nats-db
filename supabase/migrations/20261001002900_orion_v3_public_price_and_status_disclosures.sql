begin;

-- Replace review-only wording with accurate public caveats, and surface the
-- current V3 fee facts without importing prices from the unmatched legacy checkout.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'source_conflicts', case p.slug
        when 'orion-zero' then 'The V3 homepage shows Orion Zero as an active instant-funding product with a size/currency selector. The linked generic checkout uses legacy offer labels and does not establish Zero V3 account sizes or fees. Current Zero pricing and full V3 order terms are not verified; do not use legacy prices.'
        when 'orion-nova' then 'Official V3 pages list Nova as a current 1-step Pay After You Pass offer and state a $7 USD / €7 registration fee; activation is due after passing. The linked generic checkout does not map Nova V3 to a matching product or confirm the activation amount by size. Do not treat the registration fee as the total program cost.'
        when 'orion-standard' then 'Official V3 pages list the Standard two-step mode. The linked generic checkout does not map its legacy offer labels to Standard V3 or establish a current size/fee matrix. No legacy fee or account size is inferred.'
        when 'orion-swing' then 'Official V3 Help Center describes Swing as a mode of the current two-step program. The linked generic checkout does not map its legacy offer labels to Swing V3 or establish a current size/fee matrix. No legacy fee or account size is inferred.'
        when 'orion-select' then 'Official V3 pages list Select as a current three-step offer. The linked generic checkout does not confirm V3 size/fee mapping; the homepage campaign example is not treated as the standard base-fee matrix.'
      end,
      'price_configuration', case p.slug
        when 'orion-zero' then 'A current V3 Zero account-size and fee matrix was not verified in the public offer sources. The linked generic checkout exposes unmatched legacy offers; no size or price has been inferred. Confirm the current V3 fee and account size in the provider order flow.'
        when 'orion-nova' then 'Current V3 offer: $7 USD / €7 registration fee to start; activation fee is due only after passing. The current public sources do not verify the activation amount or size-by-size activation matrix. The $7 registration fee is not the total program cost.'
        when 'orion-standard' then 'A current V3 Standard size and fee matrix was not verified in public offer sources. The linked generic checkout does not map its legacy labels to Standard V3. No account size or fee has been inferred.'
        when 'orion-swing' then 'A current V3 Swing size and fee matrix was not verified in public offer sources. The linked generic checkout does not map its legacy labels to Swing V3. No account size or fee has been inferred.'
        when 'orion-select' then 'The homepage displays a campaign example for a $100K Select account at $205 against a struck-through $409 regular price with code NEW50. It is labeled one-time, refundable, and for new users. This offer is not a complete V3 base-fee matrix; code eligibility, expiry, and other size prices remain unverified.'
      end,
      'promotion_note', case when p.slug = 'orion-select'
        then 'Homepage campaign example captured 2026-09-30: $100K Select at $205 (regular price shown as $409), code NEW50; labeled one-time, refundable, and for new users. Confirm eligibility and current terms at checkout.'
        else p.commercial_details ->> 'promotion_note'
      end
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'orion-funded'
  and p.slug in ('orion-zero', 'orion-nova', 'orion-standard', 'orion-swing', 'orion-select');

insert into bullish_banana.data_verifications (firm_id, verified_at, notes)
select f.id, '2026-09-30T13:18:00Z'::timestamptz,
  'Rechecked current V3 homepage, official program overview, and challenge comparison on 2026-09-30. The five listed programs remain current. Nova carries a USD 7 / EUR 7 registration fee, with an unverified post-pass activation amount; the homepage Select campaign example is preserved separately and not treated as a full base-fee matrix. The generic linked checkout remains unmatched to V3, and provider/contracting-entity discrepancies stay disclosed.'
from bullish_banana.firms f
where f.slug = 'orion-funded'
  and not exists (select 1 from bullish_banana.data_verifications v where v.firm_id = f.id and v.verified_at = '2026-09-30T13:18:00Z'::timestamptz);

commit;
