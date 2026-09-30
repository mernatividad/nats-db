begin;

-- Record current first-party legal disclosures and the observed selector caveats.
update bullish_banana.firm_profiles fp
set profile_details = coalesce(fp.profile_details, '{}'::jsonb) || jsonb_build_object(
      'service_model', 'Atmos describes its challenges and reward accounts as simulated trading using virtual funds. Its current legal disclosure says there is no live-market trading and no actual financial instruments are traded.',
      'service_model_note', 'The official site also uses promotional phrases such as “funded account” and promotes transfers to a Taurex live account. The legal disclosure expressly limits Atmos program activity to simulated evaluation; do not imply the Atmos account itself is a live brokerage account.',
      'platform_scope_note', 'The official site identifies MetaTrader 5, TradeLocker, and Match-Trader as platform options, but the reviewed current selector does not map a platform to each plan, account size, and country. Confirm the selected checkout configuration.',
      'publication_note', 'Published with disclosed limits: the official terms define Atmos activity as simulated with virtual funds and no live-market trades; challenge marketing uses funded-account language. Restricted jurisdictions are non-exhaustive; verify eligibility at checkout. Account platform mapping is not stated by plan.'
    ),
    updated_at = now()
from bullish_banana.firms f
where fp.firm_id = f.id and f.slug = 'atmos-funded';

update bullish_banana.firms f
set status = 'published', published_at = coalesce(f.published_at, now()), archived_at = null, updated_at = now()
where f.slug = 'atmos-funded' and f.status = 'in_review';

-- The current NOVA article was updated this week and lists five funded sizes.
update bullish_banana.programs p
set account_sizes = '[10000,25000,50000,100000,200000]'::jsonb,
    minimum_trading_days = 0,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'account_size_prices', jsonb_build_array(
        jsonb_build_object('fee',5,'currency','USD','fee_type','challenge_entry','account_size',10000),
        jsonb_build_object('fee',5,'currency','USD','fee_type','challenge_entry','account_size',25000),
        jsonb_build_object('fee',5,'currency','USD','fee_type','challenge_entry','account_size',50000),
        jsonb_build_object('fee',5,'currency','USD','fee_type','challenge_entry','account_size',100000),
        jsonb_build_object('fee',5,'currency','USD','fee_type','challenge_entry','account_size',200000)
      ),
      'funded_activation_fees', jsonb_build_array(
        jsonb_build_object('fee',79,'currency','USD','account_size',10000),
        jsonb_build_object('fee',184,'currency','USD','account_size',25000),
        jsonb_build_object('fee',345,'currency','USD','account_size',50000),
        jsonb_build_object('fee',569,'currency','USD','account_size',100000),
        jsonb_build_object('fee',1029,'currency','USD','account_size',200000)
      ),
      'publication_note', 'Current NOVA Help Center article, marked updated this week on 2026-09-30, lists $10K/$25K/$50K/$100K/$200K funded sizes, each with a $5 evaluation entry fee and a separate funded activation fee. The main homepage promotes up to $400K overall allocation; its exact NOVA allocation configuration is not stated in the selector. The NOVA challenge has no minimum evaluation days; funded withdrawals require seven qualifying profitable days and are on demand.',
      'review_note', 'Funded activation fees are separate from the $5 evaluation entry fee. The current article lists five funded sizes; confirm the selected size and fee again at checkout.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'atmos-funded' and p.slug = 'nova';

-- The current 2-Step Standard rule article now states a 14-day payout schedule.
update bullish_banana.programs p
set payout_frequency = 'Every 14 days after funding',
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'payout_rules', 'The current official 2-Step Standard article and current general payout schedule state a 14-day payout cycle. Recheck the purchased configuration for any variation.',
      'review_note', 'The current official 2-Step Standard rule article shows payouts every 14 days. Base prices are listed separately from promotional prices; homepage banners display more than one time-limited promotion, so do not combine discounts without checkout confirmation.'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'atmos-funded' and p.slug = '2-step-standard';

-- Preserve explicit unknown deadline disclosure for each evaluation phase; sources do not state a challenge time limit.
update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'No overall challenge time limit is stated in the current official plan article or rules page, checked 2026-09-30. This does not assert an unlimited guarantee beyond those published sources.'
    )
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'atmos-funded' and p.program_type = 'evaluation';

update bullish_banana.program_phases ph
set raw_rules = coalesce(ph.raw_rules, '{}'::jsonb) || jsonb_build_object('no_minimum_trading_days', true)
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where ph.program_id = p.id and f.slug = 'atmos-funded' and p.slug = 'nova';

update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'time_limit_note', 'No overall challenge time limit is stated in the current official plan article or rules page, checked 2026-09-30.',
      'platform_availability_note', 'Atmos lists MetaTrader 5, TradeLocker, and Match-Trader at firm level; the current public selector does not map these platforms to individual offer, size, or country. Confirm at checkout.',
      'publication_note', 'Published with dated source disclosures. Official rules define Atmos account activity as simulated using virtual funds. Entry fees below are official base prices; current homepage promotions are time-limited and their displayed selector discounts do not consistently match the promotion banner. Confirm the fee and configuration at checkout.'
    ),
    status = 'published', published_at = coalesce(p.published_at, now()), archived_at = null, updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id and f.slug = 'atmos-funded' and p.status = 'in_review';

-- The firm-level destination is a direct official-site link; program destinations remain their plan pages.
insert into bullish_banana.affiliate_destinations (firm_id, program_id, kind, label, destination_url, is_primary, status)
select f.id, null, 'official_site', 'Visit Atmos Funded official site', 'https://atmosfunded.com/', true, 'active'
from bullish_banana.firms f
where f.slug = 'atmos-funded'
  and not exists (
    select 1 from bullish_banana.affiliate_destinations d
    where d.firm_id = f.id and d.program_id is null and d.destination_url = 'https://atmosfunded.com/'
  );

update bullish_banana.sources s
set notes = 'Official homepage and selector checked 2026-09-30. Selected $5K Standard shows $37.84 promotional price against $43 base; 12% SEPT promotion states September 1–30, while a separate banner promotes 35% off selected 1-Step, 2-Step, and Instant Funding offers for September 30–October 2. Do not assume stacking or replace base price with a promotion. Homepage currently highlights the $5 NOVA challenge.'
from bullish_banana.firms f
where s.firm_id = f.id and s.program_id is null and f.slug = 'atmos-funded' and s.source_url = 'https://atmosfunded.com/';

insert into bullish_banana.sources (firm_id, source_url, source_label, notes)
select f.id, 'https://atmosfunded.com/rules/', 'Atmos official rules and legal disclosure',
  'Current official rules and footer checked 2026-09-30: program activity is simulated with virtual funds, no live-market orders or real financial instruments are traded; Atmos Global Ltd is the site operator and AtmosFunded Ltd provides challenge and payment services. Restrictions are non-exhaustive. The general rules page lists Forex leverage 1:50 and does not state a challenge deadline.'
from bullish_banana.firms f
where f.slug = 'atmos-funded'
  and not exists (select 1 from bullish_banana.sources s where s.firm_id=f.id and s.program_id is null and s.source_url='https://atmosfunded.com/rules/');

insert into bullish_banana.sources (program_id, source_url, source_label, notes)
select p.id, 'https://help.atmosfunded.com/en/articles/12380567-compare-challenges-which-one-is-right-for-me', 'Atmos current challenge comparison',
  'Current official comparison article checked 2026-09-30. Confirms the six currently represented product families, challenge targets, drawdown, minimum-day and payout summaries; the 2-Step Standard payout schedule is shown as 14 days. The article does not state an overall evaluation deadline.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='atmos-funded'
  and not exists (select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url='https://help.atmosfunded.com/en/articles/12380567-compare-challenges-which-one-is-right-for-me');

update bullish_banana.data_verifications v
set verified_at = '2026-09-30T12:45:00Z',
    notes = concat_ws(' ', v.notes, 'Rechecked current official homepage, rules/footer, challenge comparison, general payout schedule, and NOVA article on 2026-09-30. Formal terms expressly describe simulated virtual-fund activity with no live-market trades; challenge-family statuses are published with platform, promotion, jurisdiction, and offer-specific caveats retained.')
from bullish_banana.firms f
where v.firm_id=f.id and v.program_id is null and f.slug='atmos-funded';

update bullish_banana.data_verifications v
set verified_at = '2026-09-30T12:45:00Z',
    notes = concat_ws(' ', v.notes, 'Rechecked the current official plan article and challenge comparison on 2026-09-30. Current plan comparison lists payout and risk terms; public sources do not state an overall evaluation deadline, so this is explicitly marked unstated. Current promotions are recorded separately from base fees.')
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where v.program_id=p.id and f.slug='atmos-funded';

commit;
