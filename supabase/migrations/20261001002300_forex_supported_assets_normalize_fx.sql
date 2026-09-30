begin;

update bullish_banana.firm_profiles fp
set supported_assets = array_append(coalesce(fp.supported_assets, '{}'::text[]), 'Forex'),
    updated_at = now()
where exists (
  select 1
  from unnest(coalesce(fp.supported_assets, '{}'::text[])) as asset
  where lower(asset) = 'fx'
)
and not exists (
  select 1
  from unnest(coalesce(fp.supported_assets, '{}'::text[])) as asset
  where lower(asset) = 'forex'
);

commit;
