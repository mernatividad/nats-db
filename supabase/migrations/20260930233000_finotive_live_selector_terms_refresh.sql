-- Finotive current selector and Terms refresh captured 2026-09-30.
-- Prices remain in review, preserve base fees, and record each currently
-- selectable denomination. Programs remain in_review; platform mapping by offer
-- is not established by public sources.
set search_path = bullish_banana, extensions, public;

update bullish_banana.firm_profiles fp
set profile_details = fp.profile_details || '{
  "restricted_locations_verified_at":"2026-09-30",
  "country_restrictions":"Current Terms §3.3 reviewed 2026-09-30 list Iran and North Korea, the Palestinian Territories, and the subnational or disputed territories named in restricted_locations_current_terms. Country-level rows are limited to IR, KP and PS; territory limits are preserved as text to avoid incorrectly blocking whole countries.",
  "restricted_locations_current_terms":["Iran / Islamic Republic of Iran (IR)","Crimea (territory of Ukraine)","Sevastopol (territory of Ukraine)","Luhansk People’s Republic (territory of Ukraine)","Donetsk People’s Republic (territory of Ukraine)","Zaporizhzhia (territory of Ukraine)","Kherson (territory of Ukraine)","Abkhazia (GE)","South Ossetia","Turkish Republic of Northern Cyprus","Somaliland","Transnistria (MD)","Nagorno-Karabakh Republic (AM)","North Korea / DPRK (KP)","Palestinian Territories"],
  "restricted_locations_note":"Current Terms §3.3 lists country and subnational-territory restrictions and may be updated without notice. Territory restrictions are preserved as text and must not be interpreted as a restriction on the full associated country.",
  "jurisdiction_notes":"Terms §3.3 reviewed 2026-09-30 lists Iran, North Korea and the Palestinian Territories, plus Crimea, Sevastopol, Luhansk, Donetsk, Zaporizhzhia, Kherson, Abkhazia, South Ossetia, Northern Cyprus, Somaliland, Transnistria and Nagorno-Karabakh. The territorial limits apply to the named locations, not automatically to the entire associated country. Finotive may change the list without notice.",
  "platforms":["MT5 (where offered; individual offer mapping not confirmed)","Match-Trader (where offered; individual offer mapping not confirmed)"],
  "assets_note":"Forex and other simulated trading markets are listed by Finotive. Tradable symbols and instrument conditions depend on the account platform; verify the current symbol list in the account.",
  "entity_scope_note":"Finotive Funding is a trading name of Finotive Funding Technologies Limited (DIFC, Dubai; company 11088). Finotive Markets LLC may facilitate platform access; Finotive Pay (CY) Limited processes payments as agent for Finotive One group entities. These are separate roles under current Terms.",
  "platform_mapping_note":"Current Terms §6.1 names MT5 and Match-Trader as examples of platforms that may be provided and allows other platforms; public sources reviewed 2026-09-30 do not confirm platform availability for each individual program. Treat program platform as not stated until an account-specific selector or contract identifies it.",
  "notional_exposure_note":"Current Terms §7.6 limits open notional exposure by size: $2,500 5,000%; $5,000 4,000%; $10,000 3,000%; $25,000 2,500%; $50,000 2,000%; $100,000 1,250%; $200,000 1,000%. These limits are separate from platform leverage. The rules page labels effective limits 100:1 for Challenge/Pro and 33:1 for Instant, but platform margin may vary by account and instrument.",
  "current_promotion":"The Accounts page showed new customers code FIRST25 for 25% off the first purchase on 2026-09-30. No expiry was displayed. Terms §13.2 say promotions may be withdrawn at any time and may not be combined unless expressly permitted; base selector fees are retained.",
  "current_selector_currencies":["USD","EUR","GBP"],
  "current_country_eligibility_note":"The current Terms list both countries and subnational territories as restricted. Only full country/jurisdiction entries supported by country-code rows should be placed in the restrictions table; preserve territorial exclusions in this profile detail."
}'::jsonb,
updated_at=now()
from bullish_banana.firms f
where fp.firm_id=f.id and f.slug='finotive-funding';

-- Encode only country/jurisdiction exclusions as country rows. Territorial
-- exclusions remain in profile_details to avoid blocking entire countries.
insert into bullish_banana.restrictions (firm_id,country_code,restriction_type,note)
select f.id,x.country_code,'restricted',x.note
from bullish_banana.firms f
join (values
 ('IR','Current Finotive Terms §3.3 reviewed 2026-09-30 list Iran / Islamic Republic of Iran as restricted.'),
 ('KP','Current Finotive Terms §3.3 reviewed 2026-09-30 list North Korea / DPRK as restricted.'),
 ('PS','Current Finotive Terms §3.3 reviewed 2026-09-30 list the Palestinian Territories as restricted.')
) as x(country_code,note) on true
where f.slug='finotive-funding'
on conflict (firm_id,country_code) do update
set restriction_type=excluded.restriction_type,note=excluded.note,updated_at=now();

update bullish_banana.programs p
set max_leverage=null,
    news_allowed=true,
    commercial_details = p.commercial_details || jsonb_build_object(
      'account_size_prices', coalesce((
        select jsonb_agg((base.price - 'currency') || jsonb_build_object('currency',cur.currency)
                         order by (base.price->>'account_size')::numeric,cur.currency)
        from (
          select distinct on ((entry.price->>'account_size')::numeric) entry.price
          from jsonb_array_elements(coalesce(p.commercial_details->'account_size_prices','[]'::jsonb)) entry(price)
          order by (entry.price->>'account_size')::numeric,entry.price->>'currency'
        ) base
        cross join (values ('USD'),('EUR'),('GBP')) cur(currency)
      ),'[]'::jsonb),
      'pricing_capture','Current public account selector rechecked 2026-09-30. USD size/fee schedules match the 2026-09-28 capture. EUR and GBP toggles show the same nominal size and fee numbers in their selected denomination. Current promotions are recorded separately; list fees do not include discounts.',
      'price_configuration','The public selector offers USD, EUR and GBP. At the 2026-09-30 capture, each of the six offer matrices displayed the same numeric fees across all three selected denominations. Fee rows retain denomination-specific entries for comparison.',
      'promotion_note','New customers: code FIRST25 displayed as 25% off the first purchase on 2026-09-30. No expiry was displayed. Current Terms §13.2 allow withdrawal at any time and restrict combining offers; verify the code at checkout. Base fees are shown before this discount.',
      'platforms_and_region','Current Terms §6.1 permit MT5, Match-Trader or other platforms, but public sources checked 2026-09-30 do not confirm availability for this individual offer. Confirm the assigned platform before purchase.',
      'asset_coverage','Forex is included in the firm’s current product offering. Check the account platform for the current tradable symbol list.',
      'account_limitations','Terms §7.6 size-tier open notional limits: $2,500 5,000%; $5,000 4,000%; $10,000 3,000%; $25,000 2,500%; $50,000 2,000%; $100,000 1,250%; $200,000 1,000%. The rules page shows effective notional leverage of 100:1 for Challenge/Pro and 33:1 for Instant; technical platform leverage and margin are separate and may vary.'
    ) || case p.slug
      when 'one-step' then '{
        "trading_conditions":"Current selector and Trading Rules checked 2026-09-30: 10% target, 4% daily drawdown based on previous trading-day close, 7.5% static max drawdown from initial balance, three profitable days at 0.5% each, and no selector trading-consistency requirement. High-impact news is permitted for genuine directional trading, but news straddling is restricted under Terms §7.9. Notional volume is tiered by account size under Terms §7.6.",
        "payout_rules":"Terms §8.3: first reward request on demand after funded status and eligibility. Following an approved first payment, 7-calendar-day cooldown. One-Step minimum request is the lower of 1% of initial balance or USD 100; open positions must be closed and KYC, compliance, trading rules and profitable-day conditions met.",
        "fee_refund_policy":"Terms §§8.5 and 14.2: fee is refunded automatically only if funded status is reached and the account remains in net profit on day 30 after funded status, subject to no disqualifying breach, fraud, prohibited conduct, false information or chargeback before the refund date.",
        "rule_source_capture":"Selector and Trading Rules reviewed 2026-09-30; current Terms §§7.6-7.7, 8.3-8.6 prevail over marketing and selector summaries."
      }'::jsonb
      when 'two-step' then '{
        "trading_conditions":"Current selector and Trading Rules checked 2026-09-30: Phase 1 target 7.5%, Phase 2 target 5%; 4.5% daily drawdown and 9% static maximum drawdown from initial balance; two profitable days at 0.5% per phase. Selector says no trading-consistency requirement. High-impact news is permitted for genuine directional trading, but news straddling is restricted under Terms §7.9. Notional volume is tiered by account size under Terms §7.6.",
        "payout_rules":"Terms §8.3: first reward request on demand after funded status and eligibility. Following an approved first payment, 7-calendar-day cooldown. No minimum request amount for 2-Step Challenge-Funded accounts; open positions must be closed and KYC, compliance, trading rules and applicable profitable-day conditions met.",
        "fee_refund_policy":"Terms §§8.5 and 14.2: fee is refunded automatically only if funded status is reached and the account remains in net profit on day 30 after funded status, subject to no disqualifying breach, fraud, prohibited conduct, false information or chargeback before the refund date.",
        "rule_source_capture":"Selector and Trading Rules reviewed 2026-09-30; current Terms §§7.6-7.7, 8.3-8.6 prevail over marketing and selector summaries."
      }'::jsonb
      when 'instant-standard' then '{
        "trading_conditions":"Current selector and Terms §§7.5-7.8, 9.2 and 9.3 checked 2026-09-30: no evaluation or target; 3.5% daily drawdown, 7% static maximum drawdown, zero profitable-day minimum, and 1.5% floating drawdown threshold per symbol (1.0% reminder; first confirmed breach warning, later confirmed breaches count as strikes). Notional volume is size-tiered; rules page shows 33:1 effective leverage, which is separate from platform margin leverage. High-impact news is permitted for genuine directional trading; news straddling is restricted. Non-crypto weekend holding requires the Weekend Holding add-on; otherwise close by 17:00 New York time Friday.",
        "payout_rules":"Terms §9.3: first request on demand when eligible; 7-calendar-day cooldown after the first approved payment. Minimum request is 1% of initial balance with no USD cap; close all positions and satisfy KYC, compliance and rules.",
        "fee_refund_policy":"Terms §§9.1 and 14.3-14.5: generally non-refundable, except a 14-calendar-day cooling-off request may qualify if no trades were placed, platform/dashboard use stayed within registration and reasonable cancellation steps, and KYC is completed; request must be emailed from the registered address. Mandatory-law rights also apply.",
        "rule_source_capture":"Selector and Trading Rules reviewed 2026-09-30; current Terms §§7.5-7.8, 9 and 14 govern. No actual platform leverage or offer-specific platform was verified."
      }'::jsonb
      when 'instant-lite' then '{
        "trading_conditions":"Current selector and Terms §§7.5-7.8, 9.2 and 9.3 checked 2026-09-30: no evaluation or target; 3% daily drawdown, 6% static maximum drawdown, five profitable days at 0.5% each, and 1.5% floating drawdown threshold per symbol (1.0% reminder; first confirmed breach warning, later confirmed breaches count as strikes). Notional volume is size-tiered; rules page shows 33:1 effective leverage, which is separate from platform margin leverage. High-impact news is permitted for genuine directional trading; news straddling is restricted. Non-crypto weekend holding requires the Weekend Holding add-on; otherwise close by 17:00 New York time Friday.",
        "payout_rules":"Terms §9.3: first request on demand when eligible; 14-calendar-day cooldown after the first approved payment. Minimum request is 1% of initial balance with no USD cap; five profitable days, closed positions, KYC, compliance and rule compliance are required.",
        "fee_refund_policy":"Terms §§9.1 and 14.3-14.5: generally non-refundable, except a 14-calendar-day cooling-off request may qualify if no trades were placed, platform/dashboard use stayed within registration and reasonable cancellation steps, and KYC is completed; request must be emailed from the registered address. Mandatory-law rights also apply.",
        "rule_source_capture":"Selector and Trading Rules reviewed 2026-09-30; current Terms §§7.5-7.8, 9 and 14 govern. No actual platform leverage or offer-specific platform was verified."
      }'::jsonb
      when 'pro-one-step' then '{
        "trading_conditions":"Current selector and Terms §§7.5-7.7, 10.2 and 10.6 checked 2026-09-30: 10% target, 4% daily drawdown, 8% static max drawdown, and three profitable days at 0.5%. Pro consistency and 5% rolling-90-day profitability rules begin from funded day 31; they are not an evaluation-stage progression rule. From day 31, weekly trade count and instrument volumes must stay within ±25% of averages from the Pro Challenge and first 30 funded days, including instrument allocation limits. High-impact news is permitted for genuine directional trading; news straddling is restricted.",
        "payout_rules":"Terms §§10.3-10.5: first reward request on demand after funded status and eligibility; 7-calendar-day cooldown after the first approved payment. Minimum request is the lower of 1% of initial balance or USD 100. Reward split starts at 80%, increases to 100% after 30 funded days if Pro status is retained, and salary accrues at 1% of purchased capital per rolling 30 days from funded status, paid monthly. Close positions and satisfy KYC, compliance and profitable-day conditions.",
        "profit_split":"80% initially; 100% after 30 funded days while Pro status is retained. Terms §10.4.",
        "salary_rule":"Terms §10.5: 1% of purchased capital per rolling 30-day period, accrued daily from funded status and paid monthly while Pro status is retained, subject to the stated compliance conditions.",
        "consistency_rule":"Terms §10.6: begins on funded day 31; includes ±25% trade-count/volume and instrument-allocation bands plus at least 5% combined realized/unrealized profit per rolling 90 days, counting rewards already paid. Breach downgrades the account and permanently removes Pro benefits.",
        "commission_details":"Terms §10.4 state Pro execution commission is 25% lower than equivalent standard settings; no absolute per-lot commission amount is stated in the reviewed sources.",
        "fee_refund_policy":"Terms §§10 and 14.2: fee is refunded automatically only if funded status is reached and the account remains in net profit on day 30 after funded status, subject to the stated breach and compliance exclusions.",
        "rule_source_capture":"Selector and Trading Rules reviewed 2026-09-30; current Terms §§7.5-7.7, 10.2-10.6 and 14.2 prevail. No offer-specific platform was verified."
      }'::jsonb
      else '{
        "trading_conditions":"Current selector and Terms §§7.5-7.7, 10.2 and 10.6 checked 2026-09-30: Phase 1 target 7.5%, Phase 2 target 5%; 5% daily drawdown, 10% static max drawdown, and two profitable days at 0.5% per phase. Pro consistency and 5% rolling-90-day profitability rules begin from funded day 31; they are not evaluation-stage progression rules. From day 31, weekly trade count and instrument volumes must stay within ±25% of averages from the Pro Challenge and first 30 funded days, including instrument allocation limits. High-impact news is permitted for genuine directional trading; news straddling is restricted.",
        "payout_rules":"Terms §§10.3-10.5: first reward request on demand after funded status and eligibility; 7-calendar-day cooldown after the first approved payment. No minimum request amount for 2-Step Pro. Reward split starts at 80%, increases to 100% after 30 funded days if Pro status is retained, and salary accrues at 1% of purchased capital per rolling 30 days from funded status, paid monthly. Close positions and satisfy KYC, compliance and profitable-day conditions.",
        "profit_split":"80% initially; 100% after 30 funded days while Pro status is retained. Terms §10.4.",
        "salary_rule":"Terms §10.5: 1% of purchased capital per rolling 30-day period, accrued daily from funded status and paid monthly while Pro status is retained, subject to the stated compliance conditions.",
        "consistency_rule":"Terms §10.6: begins on funded day 31; includes ±25% trade-count/volume and instrument-allocation bands plus at least 5% combined realized/unrealized profit per rolling 90 days, counting rewards already paid. Breach downgrades the account and permanently removes Pro benefits.",
        "commission_details":"Terms §10.4 state Pro execution commission is 25% lower than equivalent standard settings; no absolute per-lot commission amount is stated in the reviewed sources.",
        "fee_refund_policy":"Terms §§10 and 14.2: fee is refunded automatically only if funded status is reached and the account remains in net profit on day 30 after funded status, subject to the stated breach and compliance exclusions.",
        "rule_source_capture":"Selector and Trading Rules reviewed 2026-09-30; current Terms §§7.5-7.7, 10.2-10.6 and 14.2 prevail. No offer-specific platform was verified."
      }'::jsonb
    end,
    updated_at=now()
from bullish_banana.firms f
where p.firm_id=f.id and f.slug='finotive-funding'
  and p.slug in ('one-step','two-step','instant-standard','instant-lite','pro-one-step','pro-two-step');

-- Instant products have no evaluation stages. A named funded-account rule row
-- lets the existing detail route render the verified drawdown and day terms.
insert into bullish_banana.program_phases (
  program_id,phase_number,name,profit_target_percent,daily_drawdown_percent,
  maximum_drawdown_percent,drawdown_type,time_limit_days,minimum_trading_days,raw_rules
)
select p.id,1,'Funded account',null,x.daily,x.maximum,'static',null,x.days,x.rules::jsonb
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('instant-standard',3.5::numeric,7::numeric,0,'{"minimum_profitable_days":0,"day_requirement_label":"No profitable-day minimum","floating_drawdown_threshold_percent":1.5,"floating_drawdown_warning_percent":1.0,"first_floating_breach":"Warning only","later_floating_breaches":"Strike; reward reduced to 10% for that payout cycle","weekend_holding":"Non-crypto positions require the Weekend Holding add-on; otherwise close by Friday 17:00 New York time."}'),
 ('instant-lite',3::numeric,6::numeric,5,'{"minimum_profitable_days":5,"day_requirement_label":"5 profitable days at 0.5% each","floating_drawdown_threshold_percent":1.5,"floating_drawdown_warning_percent":1.0,"first_floating_breach":"Warning only","later_floating_breaches":"Strike; reward reduced to 10% for that payout cycle","weekend_holding":"Non-crypto positions require the Weekend Holding add-on; otherwise close by Friday 17:00 New York time."}')
) as x(program_slug,daily,maximum,days,rules) on x.program_slug=p.slug
where f.slug='finotive-funding'
on conflict (program_id,phase_number) do update
set name=excluded.name,profit_target_percent=excluded.profit_target_percent,
    daily_drawdown_percent=excluded.daily_drawdown_percent,
    maximum_drawdown_percent=excluded.maximum_drawdown_percent,
    drawdown_type=excluded.drawdown_type,time_limit_days=excluded.time_limit_days,
    minimum_trading_days=excluded.minimum_trading_days,raw_rules=excluded.raw_rules,updated_at=now();

update bullish_banana.program_phases pp
set raw_rules=coalesce(pp.raw_rules,'{}'::jsonb) || x.rules::jsonb,updated_at=now()
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
  ('one-step',1,'{"minimum_profitable_days":3,"day_requirement_label":"3 profitable days at 0.5% each","daily_drawdown_reference":"Previous trading-day closing balance","maximum_drawdown_reference":"Initial account balance; static"}'),
  ('two-step',1,'{"minimum_profitable_days":2,"day_requirement_label":"2 profitable days at 0.5% each phase","daily_drawdown_reference":"Previous trading-day closing balance","maximum_drawdown_reference":"Initial account balance; static"}'),
  ('two-step',2,'{"minimum_profitable_days":2,"day_requirement_label":"2 profitable days at 0.5% each phase","daily_drawdown_reference":"Previous trading-day closing balance","maximum_drawdown_reference":"Initial account balance; static"}'),
  ('pro-one-step',1,'{"minimum_profitable_days":3,"day_requirement_label":"3 profitable days at 0.5% each","daily_drawdown_reference":"Previous trading-day closing balance","maximum_drawdown_reference":"Initial account balance; static","consistency_stage":"Pro funded consistency starts from funded day 31; it is not a challenge-phase progression rule."}'),
  ('pro-two-step',1,'{"minimum_profitable_days":2,"day_requirement_label":"2 profitable days at 0.5% each phase","daily_drawdown_reference":"Previous trading-day closing balance","maximum_drawdown_reference":"Initial account balance; static","consistency_stage":"Pro funded consistency starts from funded day 31; it is not a challenge-phase progression rule."}'),
  ('pro-two-step',2,'{"minimum_profitable_days":2,"day_requirement_label":"2 profitable days at 0.5% each phase","daily_drawdown_reference":"Previous trading-day closing balance","maximum_drawdown_reference":"Initial account balance; static","consistency_stage":"Pro funded consistency starts from funded day 31; it is not a challenge-phase progression rule."}')
) as x(program_slug,phase_number,rules) on x.program_slug=p.slug
where pp.program_id=p.id and pp.phase_number=x.phase_number
  and f.slug='finotive-funding';

insert into bullish_banana.sources (firm_id,source_url,source_label,notes)
select f.id,x.url,x.label,x.notes
from bullish_banana.firms f
join (values
 ('https://finotivefunding.com/accounts','Live account selector refresh','All six USD size/fee matrices rechecked 2026-09-30 and match the 2026-09-28 baseline. USD, EUR and GBP toggles show identical nominal amounts in the selected denomination. New-customer FIRST25 25% first-purchase offer displayed; no expiry shown.'),
 ('https://finotivefunding.com/rules','Trading Rules & Objectives refresh','Interactive Challenge, Instant and Pro rule panels reviewed 2026-09-30. Includes model drawdowns, profitable days, notional-volume limits, Instant floating-drawdown and weekend rules, and Pro funded consistency rules.'),
 ('https://finotivefunding.com/terms-and-conditions','Current Terms and Conditions refresh','Current Terms §§3, 6-10, 13-14 reviewed 2026-09-30. Primary source for restrictions, platform disclosure, payout cadence/minimums, Pro benefits, conditional refunds and promotion conditions.'),
 ('https://finotivefunding.com/challenge','Challenge selector','Current one-step and two-step products, pricing selector and overview rules reviewed 2026-09-30.'),
 ('https://finotivefunding.com/instant-funding','Instant Funding selector','Current Standard and Lite models, fees, instant-account rules and Weekend Holding add-on selector reviewed 2026-09-30.'),
 ('https://finotivefunding.com/finotive-pro','Finotive Pro selector and benefits','Current Pro one-step/two-step selector, salary, 100% split, lower-commission and conditional fee-refund marketing reviewed 2026-09-30; Terms control where marketing differs.')
) as x(url,label,notes) on true
where f.slug='finotive-funding'
and not exists(select 1 from bullish_banana.sources s where s.firm_id=f.id and s.source_url=x.url);

insert into bullish_banana.sources (program_id,source_url,source_label,notes)
select p.id,x.url,x.label,x.notes
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
join (values
 ('one-step','https://finotivefunding.com/accounts','1-Step selector and price matrix','Current selector size/fee matrix and headline rules; currency choices and first-purchase promotion captured separately.'),
 ('one-step','https://finotivefunding.com/rules','1-Step rules panel','Current risk, notional exposure and profitable-day panel; current Terms govern.'),
 ('one-step','https://finotivefunding.com/terms-and-conditions','1-Step payout and refund terms','Current Terms §§7.6-7.7, 8.3-8.6, 14.2: payout minimum and cooldown, conditional day-30 fee refund and scaling.'),
 ('two-step','https://finotivefunding.com/accounts','2-Step selector and price matrix','Current selector size/fee matrix and headline rules; currency choices and first-purchase promotion captured separately.'),
 ('two-step','https://finotivefunding.com/rules','2-Step rules panel','Current phase risk, notional exposure and profitable-day panel; current Terms govern.'),
 ('two-step','https://finotivefunding.com/terms-and-conditions','2-Step payout and refund terms','Current Terms §§7.6-7.7, 8.3-8.6, 14.2: no minimum payout amount, seven-day cooldown, conditional day-30 fee refund and scaling.'),
 ('instant-standard','https://finotivefunding.com/accounts','Instant Standard selector and price matrix','Current selector size/fee matrix, account rules and denominations.'),
 ('instant-standard','https://finotivefunding.com/rules','Instant Standard rules panel','Current drawdown, notional-exposure, floating-drawdown and weekend-add-on rules.'),
 ('instant-standard','https://finotivefunding.com/terms-and-conditions','Instant Standard reward and cancellation terms','Current Terms §§7.5-7.8, 9.1-9.5 and 14.3-14.5: payout cooldown/minimum, no profitable-day minimum and conditional cooling-off cancellation.'),
 ('instant-lite','https://finotivefunding.com/accounts','Instant Lite selector and price matrix','Current selector size/fee matrix, account rules and denominations.'),
 ('instant-lite','https://finotivefunding.com/rules','Instant Lite rules panel','Current drawdown, notional-exposure, floating-drawdown, profitable-day and weekend-add-on rules.'),
 ('instant-lite','https://finotivefunding.com/terms-and-conditions','Instant Lite reward and cancellation terms','Current Terms §§7.5-7.8, 9.1-9.5 and 14.3-14.5: fourteen-day cooldown, minimum request, five profitable days and conditional cooling-off cancellation.'),
 ('pro-one-step','https://finotivefunding.com/finotive-pro','Pro 1-Step selector and benefits','Current Pro selector, salary, split, commission discount and refund marketing; current Terms prevail.'),
 ('pro-one-step','https://finotivefunding.com/rules','Pro 1-Step rules panel','Current evaluation drawdown and profitable-day rules and funded Pro consistency panel.'),
 ('pro-one-step','https://finotivefunding.com/terms-and-conditions','Pro 1-Step payout, salary and consistency terms','Current Terms §§7.5-7.7, 10.2-10.6 and 14.2: funded-day-31 Pro consistency, split, salary, payout minimum, commission reduction and conditional fee refund.'),
 ('pro-two-step','https://finotivefunding.com/finotive-pro','Pro 2-Step selector and benefits','Current Pro selector, salary, split, commission discount and refund marketing; current Terms prevail.'),
 ('pro-two-step','https://finotivefunding.com/rules','Pro 2-Step rules panel','Current evaluation drawdown and profitable-day rules and funded Pro consistency panel.'),
 ('pro-two-step','https://finotivefunding.com/terms-and-conditions','Pro 2-Step payout, salary and consistency terms','Current Terms §§7.5-7.7, 10.2-10.6 and 14.2: funded-day-31 Pro consistency, split, salary, no minimum payout request and conditional fee refund.')
) as x(program_slug,url,label,notes) on x.program_slug=p.slug
where f.slug='finotive-funding'
and not exists(select 1 from bullish_banana.sources s where s.program_id=p.id and s.source_url=x.url);

insert into bullish_banana.data_verifications (firm_id,verified_at,notes)
select f.id,now(),'Current USD/EUR/GBP selector values, active first-purchase offer, interactive rules panels and current Terms §§3, 6-10, 13-14 reviewed 2026-09-30. Current restricted countries and territorial exclusions recorded with distinction; offer-specific platform choices remain unverified.'
from bullish_banana.firms f where f.slug='finotive-funding';

insert into bullish_banana.data_verifications (program_id,verified_at,notes)
select p.id,now(),case p.slug
  when 'one-step' then 'USD, EUR and GBP fee selector rechecked 2026-09-30. Current selector/rules and Terms confirm 10% target, 4% daily, 7.5% static max, 3 profitable days, payout minimum/cooldown and conditional day-30 refund. Platform mapping remains unverified.'
  when 'two-step' then 'USD, EUR and GBP fee selector rechecked 2026-09-30. Current selector/rules and Terms confirm 7.5%/5% targets, 4.5% daily, 9% static max, 2 profitable days each phase, no minimum payout request and conditional day-30 refund. Platform mapping remains unverified.'
  when 'instant-standard' then 'USD, EUR and GBP fee selector rechecked 2026-09-30. Current Terms confirm 3.5% daily, 7% max, zero profitable-day minimum, seven-day payout cooldown and 14-day conditional cooling-off cancellation. Platform mapping remains unverified.'
  when 'instant-lite' then 'USD, EUR and GBP fee selector rechecked 2026-09-30. Current Terms confirm 3% daily, 6% max, five profitable days, fourteen-day payout cooldown and 14-day conditional cooling-off cancellation. Platform mapping remains unverified.'
  when 'pro-one-step' then 'USD, EUR and GBP fee selector rechecked 2026-09-30. Current Terms confirm 10% target, 4% daily, 8% max, day-31 funded consistency, salary, split, payout and conditional day-30 refund. Platform mapping remains unverified.'
  else 'USD, EUR and GBP fee selector rechecked 2026-09-30. Current Terms confirm 7.5%/5% targets, 5% daily, 10% max, day-31 funded consistency, salary, split, no minimum payout request and conditional day-30 refund. Platform mapping remains unverified.'
end
from bullish_banana.programs p
join bullish_banana.firms f on f.id=p.firm_id
where f.slug='finotive-funding'
  and p.slug in ('one-step','two-step','instant-standard','instant-lite','pro-one-step','pro-two-step');
