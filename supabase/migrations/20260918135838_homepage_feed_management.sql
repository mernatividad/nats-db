set search_path = thebudolfinds, extensions, public;

-- Admin mutations run through the server-side database connection. Browser
-- roles retain the public, active-only SELECT policy from the feed migration.
grant select, insert, update, delete on table thebudolfinds.homepage_feed_items to service_role;
grant select on table thebudolfinds.users to service_role;

-- Keep the management query path predictable as the feed grows.
create index if not exists homepage_feed_items_collection_sort_idx
  on thebudolfinds.homepage_feed_items (collection, sort_order, updated_at);
