set search_path = bullish_banana, extensions, public;

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(),
  case programs.slug
    when 'ftmo-2-step' then 'Verified against the official FTMO 2-Step Challenge, trading objectives, and program rules pages.'
    else 'Verified against the official FTMO 1-Step Challenge, trading objectives, and program rules pages.'
  end
from bullish_banana.programs
where programs.slug in ('ftmo-1-step', 'ftmo-2-step')
  and programs.firm_id = (select id from bullish_banana.firms where slug = 'ftmo')
  and not exists (
    select 1 from bullish_banana.data_verifications verification
    where verification.program_id = programs.id
  );
