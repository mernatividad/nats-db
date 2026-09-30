begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'day_requirement_label', case
        when f.slug = 'tradeify-fx' and p.slug = 'daily-1-step'
          then 'No minimum trading days (current official Tradeify FX Daily marketing disclosure)'
        when f.slug = 'leveraged' and p.slug = 'sprint'
          then 'No minimum profitable days; minimum distinct trading days are not stated'
        else 'Minimum evaluation trading days are not stated in the current public phase rules'
      end,
      'day_requirement_note', case
        when f.slug = 'tradeify-fx' and p.slug = 'daily-1-step'
          then 'Tradeify FX states that its one-step evaluation has no minimum trading days. The rule applies to the Daily evaluation, not funded payout eligibility.'
        when f.slug = 'leveraged' and p.slug = 'sprint'
          then 'Leveraged lists zero minimum profitable days for Sprint simulation. That is distinct from a minimum count of distinct trading days, which the current public rules do not state.'
        when f.slug = 'leveraged' and p.slug = 'turbo'
          then 'Leveraged lists no minimum profitable-day threshold for Turbo simulation. The current public rules do not separately state a minimum count of distinct trading days.'
        else 'Current official challenge rules were reviewed. They do not publish an evaluation-phase minimum trading-day count; funded payout-day requirements are separate and are not applied to these challenge phases.'
      end,
      'day_requirement_reviewed_at', '2026-10-01'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and ((f.slug = 'tradeify-fx' and p.slug in ('classic-2-step', 'daily-1-step'))
    or (f.slug = 'top-one-trader' and p.slug = '2-step-standard')
    or (f.slug = 'leveraged' and p.slug in ('sprint', 'turbo')));

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, evidence.source_url, evidence.source_label, evidence.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
cross join lateral (values
  ('tradeify-fx', 'classic-2-step', 'https://help.tradeifyfx.co/en/articles/16976039-classic-2-step-guide', 'Tradeify FX Classic evaluation rules — 2026-10-01', 'Current official Classic guide specifies both phase targets, risk rules, and unlimited duration; it does not state an evaluation minimum trading-day requirement. Funded payout terms are documented separately.'),
  ('tradeify-fx', 'daily-1-step', 'https://help.tradeifyfx.co/en/articles/16975953-daily-1-step-guide', 'Tradeify FX Daily evaluation rules — 2026-10-01', 'Current official Daily evaluation guide details the one-phase target, consistency, risk and time limit. The provider’s current official marketing disclosure states this one-step evaluation has no minimum trading days; funded payout requirements are separate.'),
  ('tradeify-fx', 'daily-1-step', 'https://www.tradeifyfx.co/affiliate', 'Tradeify FX official Daily minimum-day marketing disclosure — 2026-10-01', 'The current official Tradeify FX affiliate page describes its one-step evaluation as having no minimum trading days or time limits. This records the marketed Daily evaluation condition; funded payout terms remain separate.'),
  ('top-one-trader', '2-step-standard', 'https://checkout.toponetrader.com/product/top-one-trader-challenges/', 'Top One Trader current 2 Step challenge selector — evaluation day disclosure — 2026-10-01', 'Current unified checkout lists the 2 Step family and its rules but does not state an evaluation minimum trading-day count in the captured public material. No minimum is inferred from funded payout terms.'),
  ('leveraged', 'sprint', 'https://getleveraged.com/sprint/', 'Leveraged Sprint public rules — evaluation day disclosure — 2026-10-01', 'Current official Sprint table lists zero minimum profitable days for simulation, which is distinct from a minimum number of distinct trading days; the latter is not stated.'),
  ('leveraged', 'turbo', 'https://getleveraged.com/turbo-trade/', 'Leveraged Turbo public rules — evaluation day disclosure — 2026-10-01', 'Current official Turbo table lists no minimum profitable-day threshold for simulation; its funded phase lists three minimum profitable days. Neither entry establishes a minimum number of distinct evaluation trading days.')
) as evidence(firm_slug, program_slug, source_url, source_label, notes)
where f.slug = evidence.firm_slug and p.slug = evidence.program_slug
  and p.market_type = 'forex' and p.status in ('published', 'in_review')
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = evidence.source_label);

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  'Rechecked current official evaluation rules. The challenge phase day requirement is recorded only at the scope supported by the cited source; funded payout requirements and minimum profitable days are kept distinct from minimum evaluation trading days.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where p.market_type = 'forex' and p.status in ('published', 'in_review')
  and ((f.slug = 'tradeify-fx' and p.slug in ('classic-2-step', 'daily-1-step'))
    or (f.slug = 'top-one-trader' and p.slug = '2-step-standard')
    or (f.slug = 'leveraged' and p.slug in ('sprint', 'turbo')))
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz
      and v.notes = 'Rechecked current official evaluation rules. The challenge phase day requirement is recorded only at the scope supported by the cited source; funded payout requirements and minimum profitable days are kept distinct from minimum evaluation trading days.');

commit;
