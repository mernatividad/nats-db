-- The computed search_document expression in passer_search_index cannot use an
-- index while it remains a view. Keep the existing release-gating definition as
-- a refresh source and expose an indexed materialized copy to the API.

create extension if not exists unaccent;
create extension if not exists pg_trgm;

-- Supabase commonly installs extensions in the extensions schema. Include both
-- managed and self-hosted layouts when the source view is evaluated.
create or replace function board_pulse.normalize_search_name(value text)
returns text
language sql
immutable
parallel safe
set search_path = board_pulse, extensions, public, pg_catalog
as $$
  select trim(regexp_replace(lower(unaccent(coalesce(value, ''))), '[^a-z0-9]+', ' ', 'g'));
$$;

alter view board_pulse.passer_search_index rename to passer_search_index_refresh_source;

-- The source remains an implementation detail; callers use the indexed copy.
revoke all on board_pulse.passer_search_index_refresh_source from anon, authenticated, service_role;

create materialized view board_pulse.passer_search_index as
select * from board_pulse.passer_search_index_refresh_source;

create unique index passer_search_index_result_id_key
  on board_pulse.passer_search_index (result_id);

create index passer_search_index_search_document_trgm_idx
  on board_pulse.passer_search_index using gin (search_document gin_trgm_ops);

create index passer_search_index_exam_scope_idx
  on board_pulse.passer_search_index (exam_slug, is_topnotcher, result_release_date desc, full_name asc);

grant select on board_pulse.passer_search_index to anon, authenticated, service_role;

-- Refreshes are intentionally explicit: ingestion and any release-gating
-- correction must refresh the corpus after its transaction commits.
create or replace function board_pulse.refresh_passer_search_index()
returns void
language plpgsql
security definer
set search_path = board_pulse, pg_catalog
as $$
begin
  refresh materialized view board_pulse.passer_search_index;
end;
$$;

revoke all on function board_pulse.refresh_passer_search_index() from public;
grant execute on function board_pulse.refresh_passer_search_index() to service_role;

notify pgrst, 'reload schema';

comment on materialized view board_pulse.passer_search_index is
  'Indexed public search corpus refreshed after ingestion; source view retains release gating.';
