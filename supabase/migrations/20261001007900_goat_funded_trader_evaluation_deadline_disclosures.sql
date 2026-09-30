begin;
set search_path = bullish_banana, extensions, public;

-- Keep an unpublished evaluation deadline distinct from a post-pass payment window.
update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', x.time_limit_note,
      'time_limit_scope', 'Evaluation phase; the official model article does not publish a maximum completion deadline',
      'time_limit_reviewed_at', '2026-10-01'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('pay-later', 'The current official Pay Later article does not state a deadline to complete the evaluation. Its separate 30-day activation-fee payment window starts after passing and is not the challenge deadline.'),
  ('goat-blitz', 'The current official GOAT Blitz model article does not state a maximum evaluation completion deadline. Its limited weekend availability describes when the challenge can be purchased, not the time allowed after purchase.')
) as x(program_slug, time_limit_note) on x.program_slug = p.slug
where ph.program_id = p.id and f.slug = 'goat-funded-trader'
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and ph.phase_number = 1;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label, x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('pay-later', 'https://help.goatfundedtrader.com/en/articles/12822025-pay-later-model', 'Goat Funded Trader Pay Later evaluation deadline — 2026-10-01', 'The current official model article describes the one-phase evaluation and separately gives 30 days to pay the activation fee after passing. It does not state a maximum evaluation completion deadline; the payment window is not recorded as the evaluation duration.'),
  ('goat-blitz', 'https://help.goatfundedtrader.com/en/articles/11111955-goat-blitz-model', 'Goat Funded Trader GOAT Blitz evaluation deadline — 2026-10-01', 'The current official model article describes the evaluation and limited weekend purchase availability but does not state a maximum evaluation completion deadline. Purchase availability is not treated as a post-purchase challenge duration.')
) as x(program_slug, source_url, source_label, notes) on x.program_slug = p.slug
where f.slug = 'goat-funded-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  x.verification_note
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('pay-later', 'Rechecked the current official Pay Later model article. It does not state an evaluation completion deadline. The published 30-day limit is for paying the activation fee after passing.'),
  ('goat-blitz', 'Rechecked the current official GOAT Blitz model article. It does not state a maximum evaluation completion deadline. Limited weekend availability refers to purchase availability.')
) as x(program_slug, verification_note) on x.program_slug = p.slug
where f.slug = 'goat-funded-trader' and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = x.verification_note);

commit;
