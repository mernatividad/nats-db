-- Centralized matcher scoring. This is SECURITY INVOKER by default, so RLS
-- still controls which published venue rows anonymous users can receive.
create or replace function wheretayo.match_venues(
  p_price_tier smallint,
  p_energy text,
  p_non_negotiable text,
  p_neighborhood_id uuid default null,
  p_limit integer default 3
)
returns table (
  id uuid,
  slug text,
  name text,
  price_tier smallint,
  is_verified boolean,
  sockets_status text,
  noise_level text,
  work_friendly_status text,
  outdoor_status text,
  parking_status text,
  wifi_status text,
  match_score integer
)
language sql
stable
set search_path = wheretayo, extensions, public
as $$
  with scored as (
    select
      v.id,
      v.slug,
      v.name,
      v.price_tier,
      v.is_verified,
      v.sockets_status,
      v.noise_level,
      v.work_friendly_status,
      v.outdoor_status,
      v.parking_status,
      v.wifi_status,
      least(99, 50
        + case when v.is_verified then 10 else 0 end
        + case when v.price_tier = p_price_tier then 20 when abs(v.price_tier - p_price_tier) = 1 then 5 else 0 end
        + case
            when p_energy = 'work' then (case when v.work_friendly_status = 'yes' then 12 else 0 end) + (case when v.sockets_status = 'yes' then 6 else 0 end) + (case when v.noise_level = 'quiet' then 5 else 0 end)
            when p_energy = 'slow' then (case when v.noise_level = 'quiet' then 10 else 0 end) + (case when v.outdoor_status = 'yes' then 5 else 0 end)
            when p_energy = 'night' then (case when v.noise_level = 'lively' then 10 else 0 end) + (case when v.price_tier >= 3 then 5 else 0 end)
            else 0
          end
        + case
            when p_non_negotiable = 'sockets' and v.sockets_status = 'yes' then 15
            when p_non_negotiable = 'outdoor' and v.outdoor_status = 'yes' then 15
            when p_non_negotiable = 'parking' and v.parking_status = 'yes' then 15
            else 0
          end
      )::integer as match_score
    from wheretayo.venues v
    where v.publication_status = 'published'
      and (p_neighborhood_id is null or v.neighborhood_id = p_neighborhood_id)
  )
  select *
  from scored
  order by match_score desc, is_verified desc, name asc
  limit greatest(1, least(coalesce(p_limit, 3), 20));
$$;

revoke all on function wheretayo.match_venues(smallint, text, text, uuid, integer) from public;
grant execute on function wheretayo.match_venues(smallint, text, text, uuid, integer) to anon, authenticated, service_role;
