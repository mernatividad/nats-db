begin;

update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'platform_scope_note', 'Axi Select supports eligible MT4 and MT5 accounts. The Axi Select Help Center scopes program availability to clients under AxiTrader LLC; country availability remains incomplete in reviewed public sources.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'axi-select';

update bullish_banana.data_verifications v
set notes = concat_ws(' ', v.notes, 'Aligned the platform availability note with current Axi Select Help Center entity scope: AxiTrader LLC clients. MT4/MT5 support is recorded separately from regional eligibility.')
from bullish_banana.firms f
where v.firm_id = f.id and f.slug = 'axi-select' and v.verified_at::date = '2026-09-30';

commit;
