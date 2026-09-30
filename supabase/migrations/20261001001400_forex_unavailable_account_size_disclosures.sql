begin;

-- Empty normalized matrices remain empty. Record why an exact matrix is not
-- shown so detail pages and the release gate can distinguish unavailable data
-- from an accidentally omitted capture.
update bullish_banana.programs p
set commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
  'account_size_price_note',
  'No verified fixed account-size and matching fee matrix is available in the linked official source capture for this offer. See the offer-specific pricing, selector, or availability notes in this profile and confirm selectable options on the provider’s current order page. No size or price has been inferred.'
),
updated_at = now()
where p.market_type = 'forex'
  and p.status in ('published', 'in_review')
  and p.program_type in ('evaluation', 'instant_funding')
  and not coalesce(jsonb_typeof(p.account_sizes) = 'array' and jsonb_array_length(p.account_sizes) > 0, false)
  and not exists (
    select 1 from jsonb_each(coalesce(p.commercial_details, '{}'::jsonb)) as detail(key, value)
    where detail.key = any(array[
      'account_size_note', 'account_size_status', 'account_size_price_note',
      'account_size_disclosure', 'account_sizes'
    ])
      and jsonb_typeof(detail.value) = 'string'
      and nullif(trim(detail.value #>> '{}'), '') is not null
  );

commit;
