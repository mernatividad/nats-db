begin;

update bullish_banana.programs p
set status = 'in_review',
    published_at = null,
    commercial_details = coalesce(p.commercial_details, '{}'::jsonb) || jsonb_build_object(
      'review_note', 'This offer does not yet have a source-backed platform mapping. Keep it out of verified recommendations until platform availability is documented for the specific offer.',
      'platform_availability_note', 'The reviewed official sources do not state platform availability for this specific offer. Do not infer it from the firm-level platform list; confirm the selected account configuration before publication.'
    ),
    updated_at = now()
where p.market_type = 'forex'
  and p.status = 'published'
  and not exists (
    select 1 from bullish_banana.program_platforms pp where pp.program_id = p.id
  )
  and not (
    coalesce(jsonb_typeof(p.commercial_details->'platforms') = 'array' and jsonb_array_length(p.commercial_details->'platforms') > 0, false)
    or coalesce(jsonb_typeof(p.commercial_details->'trading_platforms') = 'array' and jsonb_array_length(p.commercial_details->'trading_platforms') > 0, false)
    or coalesce(jsonb_typeof(p.commercial_details->'supported_platforms_by_selector') = 'array' and jsonb_array_length(p.commercial_details->'supported_platforms_by_selector') > 0, false)
    or exists (
      select 1
      from jsonb_each(coalesce(p.commercial_details, '{}'::jsonb)) as detail(key, value)
      where detail.key = any(array[
        'platform_options', 'platforms_note', 'platforms_and_region', 'platform_availability_note',
        'platform_availability', 'platform_note', 'platform_details', 'platform_availability_by_market',
        'platform_operator_scope', 'platform_eligibility_note', 'platform_mapping',
        'selector_platform_observation_2026_09_30', 'platforms_observed_at_25000'
      ])
        and (
          (jsonb_typeof(detail.value) = 'string' and nullif(trim(detail.value #>> '{}'), '') is not null)
          or (jsonb_typeof(detail.value) = 'array' and jsonb_array_length(detail.value) > 0)
          or (jsonb_typeof(detail.value) = 'object' and detail.value <> '{}'::jsonb)
        )
    )
  );

commit;
