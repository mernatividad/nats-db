begin;

update bullish_banana.firms
set status = 'in_review',
    published_at = null,
    updated_at = now()
where slug = 'atmos-funded'
  and market_type = 'forex'
  and status = 'published';

update bullish_banana.programs
set status = 'in_review',
    published_at = null,
    commercial_details = coalesce(commercial_details, '{}'::jsonb) || jsonb_build_object(
      'review_note', 'Keep this firm and its offers in review: the official legal disclosure says trading uses virtual funds in a simulated environment and no live-market trading occurs, while some Help Center marketing uses real-capital or live-account language. Confirm and reconcile the service description before publication.',
      'platform_availability_note', 'The firm profile lists MetaTrader 5, TradeLocker, and Match-Trader, but the official product selector does not map platform availability to each challenge, account size, and country. Do not infer a platform for this offer; confirm the selected configuration before publication.'
    ),
    updated_at = now()
where firm_id = (select id from bullish_banana.firms where slug = 'atmos-funded')
  and market_type = 'forex'
  and status <> 'archived';

commit;
