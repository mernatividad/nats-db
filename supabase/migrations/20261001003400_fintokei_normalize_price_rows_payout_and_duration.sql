begin;

-- Normalize the four official USD fee maps into the shared price-row shape used
-- by profile cards, challenge details, comparisons and release verification.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'account_size', entry.key::numeric,
            'fee', entry.value::numeric,
            'currency', p.currency
          ) order by entry.key::numeric
        )
        from jsonb_each_text(p.commercial_details -> 'base_fees_by_account_size') as entry(key, value)
      ), '[]'::jsonb),
      'payout_rules', case when p.slug = 'fintokei-starttrader'
        then 'The Programs page lists a 50–100% performance reward ratio; the applicable ratio depends on provider terms. Standard withdrawals are at least 14 days apart/after the first trade, subject to KYC, minimum amounts and payout-method rules. Walletory may pay instantly after separate onboarding. Confirm exact thresholds and reward ratio for the purchased account.'
        else p.commercial_details ->> 'payout_rules'
      end
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing');

-- The live Programs catalog gives ProTrader and ProTrader Swing no maximum
-- phase duration while retaining three profitable/trading day minimums.
update bullish_banana.program_phases ph
set time_limit_days = 0,
    raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'no_time_limit', true,
      'time_limit', 'No maximum duration; the current Programs page lists a minimum of three profitable/trading days in each phase.',
      'time_limit_source_reviewed', '2026-09-30'
    ),
    updated_at = now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'fintokei'
  and p.slug in ('fintokei-protrader', 'fintokei-protrader-swing');

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, '2026-09-30T13:55:00Z'::timestamptz,
  case p.slug
    when 'fintokei-starttrader' then 'Rechecked the current Programs catalog and official payout references on 2026-09-30. All four current USD account-size/base-fee pairs are normalized for public display. Standard payout interval is at least 14 days, subject to KYC, payout threshold/method and reward-ratio conditions; StartTrader reward ratio varies 50–100% and the exact purchased-account tier is not stated.'
    when 'fintokei-protrader' then 'Rechecked the current Programs catalog on 2026-09-30. Seven current account-size/base-fee rows are normalized. Current page states a three-profitable-day minimum per phase with no maximum phase duration; the limit and minimum are preserved separately.'
    when 'fintokei-protrader-swing' then 'Rechecked the current Programs catalog on 2026-09-30. Six current account-size/base-fee rows are normalized. Current page states a three-trading-day minimum per phase with no maximum phase duration; the limit and minimum are preserved separately.'
    else 'Rechecked the current Programs catalog on 2026-09-30. Six current account-size/base-fee rows are normalized; the published minimum of three trading days and maximum 60 days remain represented.'
  end
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'fintokei'
  and p.slug in ('fintokei-starttrader', 'fintokei-swifttrader', 'fintokei-protrader', 'fintokei-protrader-swing')
  and not exists (select 1 from bullish_banana.data_verifications v where v.program_id = p.id and v.verified_at = '2026-09-30T13:55:00Z'::timestamptz);

commit;
