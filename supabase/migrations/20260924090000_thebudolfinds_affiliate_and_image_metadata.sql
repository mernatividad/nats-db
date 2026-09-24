-- Persist generated affiliate destinations and image provenance separately from
-- the canonical merchant URLs. This keeps the source link recoverable.
set search_path = thebudolfinds, extensions, public;

alter table thebudolfinds.merchant_listings
  add column if not exists affiliate_url text,
  add column if not exists affiliate_network text,
  add column if not exists affiliate_generated_at timestamptz,
  add column if not exists affiliate_status text not null default 'pending'
    check (affiliate_status in ('pending', 'generated', 'failed'));

alter table thebudolfinds.products
  add column if not exists image_source_url text,
  add column if not exists image_fetched_at timestamptz;

create index if not exists merchant_listings_affiliate_status_idx
  on thebudolfinds.merchant_listings (affiliate_status);

grant select on thebudolfinds.products, thebudolfinds.merchant_listings to anon, authenticated;
