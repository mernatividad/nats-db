begin;
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) ||
    case p.slug
      when 'one-phase-pro' then jsonb_build_object(
        'challenge_rules', 'One-Phase Pro is a single-phase simulated evaluation: 10% target, 3% daily loss, 8% static maximum loss, and 3 separate evaluation trading days. News trading requires the Swing add-on; weekend holding is allowed during the challenge and requires the Swing add-on after funding. FX leverage is 1:100 without Swing and 1:30 with Swing. The evaluation has no time limit. Funded payout requests are on demand after eligibility, including the 40% Best Day Rule and a minimum profit of 1.5% or $25, whichever is larger.',
        'payout_rules', 'Standard 80% profit split; payout requests are on demand when eligible. A 40% Best Day Rule and minimum profit of 1.5% of starting balance or $25, whichever is larger, apply. A 90% profit split add-on is offered at checkout.',
        'deadline_note', 'No evaluation time limit is stated for the current One-Phase Pro offer.',
        'rule_reviewed_at', '2026-10-01'
      )
      when 'one-phase-lite' then jsonb_build_object(
        'challenge_rules', 'One-Phase Lite is a single-phase simulated evaluation: 9% target, 4% daily loss and 6% trailing maximum loss. No minimum evaluation trading days are required. News trading and overnight/weekend holding are allowed. FX leverage is 1:30. The current official guide does not state an evaluation deadline, so none is confirmed in this record. Funded payouts begin on demand and then follow a 7-day cycle; the guide lists an 80% standard split, optional upgrade up to 90%, and minimum withdrawal of 1.5%.',
        'payout_rules', 'Standard profit split is 80%, with an optional add-on up to 90%. First payout is on demand with a 1.5% minimum withdrawal; later requests follow a 7-day cycle beginning from the first trade. The current rules page says no consistency rule applies.',
        'deadline_note', 'The current official One-Phase Lite rules page does not specify an evaluation deadline; no time limit has been confirmed.',
        'rule_reviewed_at', '2026-10-01'
      )
      else '{}'::jsonb
    end,
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'instant-funding'
  and p.slug in ('one-phase-pro','one-phase-lite') and p.market_type = 'forex';

update bullish_banana.program_phases ph
set time_limit_days = case when p.slug = 'one-phase-pro' then 0 else ph.time_limit_days end,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) ||
      case p.slug
        when 'one-phase-pro' then jsonb_build_object(
          'time_limit_days', 0,
          'time_limit_note', 'The current official One-Phase Pro rules page explicitly states that the evaluation has no time limit.',
          'time_limit_scope', 'One-Phase Pro evaluation',
          'time_limit_reviewed_at', '2026-10-01'
        )
        when 'one-phase-lite' then jsonb_build_object(
          'time_limit_note', 'The current official One-Phase Lite rules page does not state an evaluation deadline; no time limit has been confirmed.',
          'time_limit_scope', 'One-Phase Lite evaluation',
          'time_limit_reviewed_at', '2026-10-01'
        )
        else '{}'::jsonb
      end,
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'instant-funding'
  and p.slug in ('one-phase-pro','one-phase-lite') and p.market_type = 'forex'
  and ph.phase_number = 1;

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, x.source_url, x.source_label || ' — 2026-10-01', x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
join (values
  ('one-phase-pro', 'https://instantfunding.com/help/one-phase/', 'Instant Funding current One-Phase Pro rules', 'The official One-Phase Pro rules page identifies this as a one-phase evaluation and explicitly lists no time limit, 10% target, 3% daily loss, 8% static drawdown, three minimum days, payout eligibility, news restrictions and leverage options.'),
  ('one-phase-lite', 'https://instantfunding.com/help/one-phase-clarity/', 'Instant Funding current One-Phase Lite rules', 'The official One-Phase Clarity rules page says this is the product now called One-Phase Lite. It specifies the target, daily and trailing loss limits, no minimum trading days, payout schedule, split, news/weekend rules and leverage; it does not state an evaluation deadline.')
) as x(slug, source_url, source_label, notes) on x.slug = p.slug
where f.slug = 'instant-funding' and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.sources s
    where s.program_id = p.id and s.source_label = x.source_label || ' — 2026-10-01');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-10-01T00:00:00Z'::timestamptz,
  case p.slug
    when 'one-phase-pro' then 'Rechecked the current official One-Phase Pro rules. The page states a 10% target, 3% daily loss, 8% static maximum loss, three evaluation days, no time limit, and on-demand payout eligibility. Updated the challenge and payout disclosures and separated funded inactivity terms from evaluation duration.'
    when 'one-phase-lite' then 'Rechecked the current official One-Phase Lite (formerly One Phase Clarity) rules. Updated challenge and payout disclosures from the current guide. It does not state an evaluation deadline; that absence is recorded without inferring unlimited time.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'instant-funding' and p.slug in ('one-phase-pro','one-phase-lite')
  and p.market_type = 'forex'
  and not exists (select 1 from bullish_banana.data_verifications v
    where v.program_id = p.id and v.verified_at = '2026-10-01T00:00:00Z'::timestamptz);

commit;
