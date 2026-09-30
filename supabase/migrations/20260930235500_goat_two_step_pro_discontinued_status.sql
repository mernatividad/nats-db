-- Goat Funded Trader confirms 2-Step PRO stopped being sold on 2026-06-13.
-- Keep the model record for historical/detail integrity, but remove it from
-- current challenge comparisons by archiving it.
set search_path = bullish_banana, extensions, public;

update bullish_banana.programs p
set status = 'archived',
    published_at = null,
    archived_at = coalesce(p.archived_at, now()),
    commercial_details = p.commercial_details || jsonb_build_object(
      'availability_note', 'Official Help Center states 2-Step PRO stopped being available for sale on 2026-06-13. Existing accounts remain active. Rechecked against the current public model selector on 2026-09-30; the offer is not selectable.',
      'availability_status', 'discontinued',
      'discontinued_since', '2026-06-13',
      'availability_source', 'https://help.goatfundedtrader.com/en/articles/13778401-2-step-pro-model'
    ),
    updated_at = now()
from bullish_banana.firms f
where p.firm_id = f.id
  and f.slug = 'goat-funded-trader'
  and p.slug = '2-step-pro';

update bullish_banana.sources s
set notes = 'Official Help Center states the 2-Step PRO model stopped being available for sale on 2026-06-13; existing accounts remain active. The current public model selector was rechecked on 2026-09-30 and does not expose the offer. Retained as an archived historical program, not a current challenge.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where s.program_id = p.id
  and f.slug = 'goat-funded-trader'
  and p.slug = '2-step-pro'
  and s.source_url = 'https://help.goatfundedtrader.com/en/articles/13778401-2-step-pro-model';

insert into bullish_banana.data_verifications (program_id, verified_at, notes)
select p.id, now(), 'Official Help Center states 2-Step PRO stopped being sold on 2026-06-13, while existing accounts remain active. Rechecked the current public model selector on 2026-09-30; it is not a selectable offer. Status archived to exclude it from current offer comparisons while preserving its historical record.'
from bullish_banana.programs p
join bullish_banana.firms f on f.id = p.firm_id
where f.slug = 'goat-funded-trader'
  and p.slug = '2-step-pro';
