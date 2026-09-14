-- Keep the public search corpus compatible with both legacy exams and the
-- canonical release/track identity introduced by the PRC track pipeline.

drop materialized view if exists board_pulse.passer_search_index;
drop view if exists board_pulse.passer_search_index_refresh_source;

create view board_pulse.passer_search_index_refresh_source
with (security_invoker = true)
as
with passer_rows as (
  select
    r.id as result_id,
    r.exam_id,
    r.full_name,
    r.school,
    coalesce(tn.rating, r.rating) as rating,
    coalesce(tn.rank, r.rank) as rank,
    r.remarks,
    tn.id is not null as is_topnotcher
  from board_pulse.results r
  left join board_pulse.top_notchers tn
    on tn.exam_id = r.exam_id
    and board_pulse.normalize_search_name(tn.full_name) = board_pulse.normalize_search_name(r.full_name)
    and board_pulse.normalize_search_name(tn.school) = board_pulse.normalize_search_name(r.school)
  union all
  select
    tn.id as result_id,
    tn.exam_id,
    tn.full_name,
    tn.school,
    tn.rating,
    tn.rank,
    'PASSED' as remarks,
    true as is_topnotcher
  from board_pulse.top_notchers tn
  where not exists (
    select 1 from board_pulse.results r
    where r.exam_id = tn.exam_id
      and board_pulse.normalize_search_name(r.full_name) = board_pulse.normalize_search_name(tn.full_name)
      and board_pulse.normalize_search_name(r.school) = board_pulse.normalize_search_name(tn.school)
  )
), prepared as (
  select
    p.result_id,
    p.exam_id,
    e.release_id,
    nullif(lower(btrim(e.track_key)), '') as track_key,
    e.slug as exam_slug,
    e.name as exam_name,
    e.category as profession,
    p.full_name,
    board_pulse.normalize_search_name(p.full_name) as normalized_name,
    board_pulse.normalize_search_name(p.school) as normalized_school,
    p.school,
    case when p.remarks = 'PASSED' then 'passed' else lower(p.remarks) end as result_status,
    p.rank,
    p.rating,
    e.scheduled_date as exam_date,
    e.results_released_at as result_release_date,
    coalesce(e.source_article_url, case when p.is_topnotcher then e.top_notchers_pdf_url else e.passers_pdf_url end) as source_url,
    case when p.is_topnotcher then e.top_notchers_pdf_url else e.passers_pdf_url end as official_source_url,
    p.is_topnotcher,
    e.validation_status,
    case when coalesce(e.source_article_url, e.passers_pdf_url, e.top_notchers_pdf_url) is null then 'incomplete' else 'complete' end as source_coverage_status,
    1 as normalization_version
  from passer_rows p
  join board_pulse.exams e on e.id = p.exam_id
  where (e.results_released_at is not null or exists (select 1 from board_pulse.results x where x.exam_id = e.id) or exists (select 1 from board_pulse.top_notchers x where x.exam_id = e.id))
    and e.validation_status in ('validated', 'verified')
    and e.is_searchable = true
    and e.completeness_status = 'complete'
    and (e.track_status is null or e.track_status = 'published')
    and (e.track_key is null or btrim(e.track_key) <> '')
)
select
  prepared.*,
  array_to_string(array(select token from unnest(regexp_split_to_array(prepared.normalized_name, '\s+')) token order by token), ' ') as normalized_tokens,
  array_to_string(array(select token from unnest(regexp_split_to_array(prepared.normalized_name, '\s+')) token order by token), ' ') as search_document
from prepared;

create materialized view board_pulse.passer_search_index as
select * from board_pulse.passer_search_index_refresh_source;

revoke all on board_pulse.passer_search_index_refresh_source from public, anon, authenticated, service_role;

create index if not exists passer_search_index_identity_idx
  on board_pulse.passer_search_index (exam_id, release_id, track_key, result_release_date desc, full_name asc);

create unique index if not exists passer_search_index_result_id_key
  on board_pulse.passer_search_index (result_id);

create index if not exists passer_search_index_search_document_trgm_idx
  on board_pulse.passer_search_index using gin (search_document gin_trgm_ops);

create index if not exists passer_search_index_exam_scope_idx
  on board_pulse.passer_search_index (exam_slug, is_topnotcher, result_release_date desc, full_name asc);

grant select on board_pulse.passer_search_index to anon, authenticated, service_role;

notify pgrst, 'reload schema';
