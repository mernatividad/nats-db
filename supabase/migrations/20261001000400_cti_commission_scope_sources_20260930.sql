-- Preserve the current first-party evidence boundary for CTI's program commissions.
-- No unverified fee amount is added; 2-Step, Instant and Direct remain unknown.
set search_path = bullish_banana, extensions, public;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select programs.id, evidence.url, evidence.label, evidence.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('1-step-challenge','https://helpcenter.citytradersimperium.com/en/articles/12877932-platforms-symbols-commissions-spreads-swaps','CTI platforms, symbols, commissions, spreads and swaps guidance','Reviewed 2026-09-30. The Help Center says to consult Symbol Specification for per-instrument costs but provides no fee amount or evaluation-vs-funded scope. Separate official 1-Step payout guidance states $5/lot on standard Forex pairs for 1-Step funded accounts only; it does not resolve evaluation commissions or non-standard symbols.'),
  ('1-step-challenge','https://citytradersimperium.com/symbols-specifications-trading-hours/','CTI live symbol and trading-hours table','Reviewed 2026-09-30. The public page describes a live spread feed; its displayed columns are symbol, bid, ask, spread and market status. No commission amount or instrument specification was rendered, so this page does not expand the published $5/lot funded 1-Step statement.'),
  ('2-step-challenge','https://helpcenter.citytradersimperium.com/en/articles/12877932-platforms-symbols-commissions-spreads-swaps','CTI platforms, symbols, commissions, spreads and swaps guidance','Reviewed 2026-09-30. The Help Center points to Symbol Specification for per-instrument costs but supplies no rate and does not map commissions to 2-Step evaluation or funded phases.'),
  ('2-step-challenge','https://citytradersimperium.com/symbols-specifications-trading-hours/','CTI live symbol and trading-hours table','Reviewed 2026-09-30. The public page renders a live spread feed with symbol, bid, ask, spread and market status; no commission amount or instrument specification was available.'),
  ('instant-funding','https://helpcenter.citytradersimperium.com/en/articles/12877932-platforms-symbols-commissions-spreads-swaps','CTI platforms, symbols, commissions, spreads and swaps guidance','Reviewed 2026-09-30. The Help Center points to Symbol Specification for per-instrument costs but supplies no rate and does not map a commission to Instant Funding.'),
  ('instant-funding','https://citytradersimperium.com/symbols-specifications-trading-hours/','CTI live symbol and trading-hours table','Reviewed 2026-09-30. The public page renders a live spread feed with symbol, bid, ask, spread and market status; no commission amount or instrument specification was available.'),
  ('direct-funding','https://helpcenter.citytradersimperium.com/en/articles/12877932-platforms-symbols-commissions-spreads-swaps','CTI platforms, symbols, commissions, spreads and swaps guidance','Reviewed 2026-09-30. The Help Center points to Symbol Specification for per-instrument costs but supplies no rate and does not map a commission to Direct Funding.'),
  ('direct-funding','https://citytradersimperium.com/symbols-specifications-trading-hours/','CTI live symbol and trading-hours table','Reviewed 2026-09-30. The public page renders a live spread feed with symbol, bid, ask, spread and market status; no commission amount or instrument specification was available.')
) as evidence(program_slug, url, label, notes) on evidence.program_slug = programs.slug
where firms.slug = 'city-traders-imperium'
  and not exists (
    select 1 from bullish_banana.sources existing
    where existing.program_id = programs.id and existing.source_url = evidence.url
  );

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select programs.id, now(), evidence.notes
from bullish_banana.programs
join bullish_banana.firms on firms.id = programs.firm_id
join (values
  ('1-step-challenge','2026-09-30 source recheck: official guidance supports $5/lot on standard Forex pairs for funded 1-Step accounts only. Evaluation-phase and non-standard-symbol costs remain unstated; no unsupported extension was made.'),
  ('2-step-challenge','2026-09-30 source recheck: reviewed the official commission Help Center article and linked live symbol feed; neither states a fee or maps one to 2-Step. Keep the commission amount unknown.'),
  ('instant-funding','2026-09-30 source recheck: reviewed the official commission Help Center article and linked live symbol feed; neither states a fee or maps one to Instant Funding. Keep the commission amount unknown.'),
  ('direct-funding','2026-09-30 source recheck: reviewed the official commission Help Center article and linked live symbol feed; neither states a fee or maps one to Direct Funding. Keep the commission amount unknown.')
) as evidence(program_slug, notes) on evidence.program_slug = programs.slug
where firms.slug = 'city-traders-imperium';
