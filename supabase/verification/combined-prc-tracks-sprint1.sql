-- Run after applying the Sprint 1 migration against a representative database.
-- Every query should return zero rows unless noted otherwise.

-- Legacy identities are complete and unique.
select id, source_article_url, release_id, track_key
from board_pulse.exams
where release_id is null or track_key is null or track_key = '';

select release_id, track_key, count(*)
from board_pulse.exams
group by release_id, track_key
having count(*) > 1;

-- Track keys and slugs are collision-free, including case/whitespace variants.
select lower(btrim(track_key)) as track_key, release_id, count(*)
from board_pulse.exams
group by lower(btrim(track_key)), release_id
having count(*) > 1;

select lower(btrim(slug)) as slug, count(*)
from board_pulse.exams
group by lower(btrim(slug))
having count(*) > 1;

-- All ingestion states point at existing release/track identities.
select s.release_id, s.track_key, s.exam_id
from board_pulse.exam_ingestion_states s
left join board_pulse.prc_releases r on r.id = s.release_id
left join board_pulse.exams e on e.id = s.exam_id
where r.id is null or (s.exam_id is not null and e.id is null);

select s.release_id, s.track_key, s.exam_id
from board_pulse.exam_ingestion_states s
left join board_pulse.exams e on e.id = s.exam_id and e.release_id = s.release_id and e.track_key = s.track_key
where s.exam_id is not null and e.id is null;

-- Batches and outbox rows must carry the release's source hash.
select b.id, b.release_id, b.source_version_hash, r.source_version_hash
from board_pulse.release_batches b
join board_pulse.prc_releases r on r.id = b.release_id
where b.source_version_hash is distinct from r.source_version_hash;

select o.id, o.batch_id, o.release_id, o.exam_id, o.source_version_hash
from board_pulse.release_outbox o
left join board_pulse.release_batches b on b.id = o.batch_id and b.release_id = o.release_id and b.source_version_hash = o.source_version_hash
left join board_pulse.exams e on e.id = o.exam_id and e.release_id = o.release_id
where b.id is null or e.id is null;

-- Documents must reference an exam in the same release when exam-scoped.
select d.id, d.release_id, d.exam_id
from board_pulse.prc_release_documents d
left join board_pulse.exams e on e.id = d.exam_id and e.release_id = d.release_id
where d.exam_id is not null and e.id is null;

-- Only expected tracks can be publishable; history is never expected.
select *
from board_pulse.exam_ingestion_states
where (state = 'history' and is_expected)
   or (state in ('published', 'processing') and not is_expected);

-- Public aliases have both table grants and explicit RLS policies.
select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'board_pulse' and table_name = 'exam_route_aliases'
  and grantee in ('anon', 'authenticated') and privilege_type <> 'SELECT';

select polname, roles, cmd
from pg_policies
where schemaname = 'board_pulse' and tablename = 'exam_route_aliases'
  and ('anon' = any(roles) or 'authenticated' = any(roles)) and cmd = 'SELECT';

-- Restrict the public surface to read-only release/document/alias objects.
select grantee, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'board_pulse'
  and table_name in ('prc_releases', 'prc_release_documents', 'release_batches', 'exam_ingestion_states', 'release_outbox', 'exam_route_aliases', 'migration_manifests')
  and grantee in ('anon', 'authenticated')
  and privilege_type <> 'SELECT';

-- RPCs are present and executable only by service_role (PUBLIC/anon/authenticated
-- should return no rows).
select routine_schema, routine_name, specific_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_schema = 'board_pulse'
  and routine_name in ('upsert_prc_release', 'sync_expected_tracks', 'claim_exam_track', 'publish_exam_track')
  and grantee in ('PUBLIC', 'anon', 'authenticated');

-- The incompatible old identity index must stay absent.
select indexname
from pg_indexes
where schemaname = 'board_pulse' and indexname = 'exams_source_article_url_key';

-- Manifest is retained and records the staged backfill.
select migration_key, status, payload->>'exam_count' as exam_count
from board_pulse.migration_manifests
where migration_key = '20260914173053_combined_prc_tracks_sprint1';

select migration_key
from board_pulse.migration_manifests
where migration_key = '20260914173053_combined_prc_tracks_sprint1'
  and (status <> 'verified' or not (payload ? 'releases') or not (payload ? 'exams') or not (payload ? 'documents')
       or not (payload ? 'batches') or not (payload ? 'ingestion_states'));

-- Legacy notification history is untouched; unrelated event types must remain.
select event_type, count(*)
from board_pulse.notification_events
group by event_type
order by event_type;

-- Mark the manifest verified only after the invariant checks above are clean.
do $$
declare
  invalid_count bigint;
begin
  select count(*) into invalid_count from board_pulse.exams where release_id is null or track_key is null or track_key = '';
  if invalid_count > 0 then raise exception 'verification failed: incomplete exam identities'; end if;
  select count(*) into invalid_count from (
    select release_id, track_key from board_pulse.exams group by release_id, track_key having count(*) > 1
  ) duplicates;
  if invalid_count > 0 then raise exception 'verification failed: duplicate release track identities'; end if;
  select count(*) into invalid_count from board_pulse.exam_ingestion_states
    where (state = 'history' and is_expected) or (state in ('published', 'processing') and not is_expected);
  if invalid_count > 0 then raise exception 'verification failed: invalid ingestion state'; end if;
  select count(*) into invalid_count
  from board_pulse.release_outbox o
  left join board_pulse.release_batches b on b.id = o.batch_id and b.release_id = o.release_id and b.source_version_hash = o.source_version_hash
  left join board_pulse.exams e on e.id = o.exam_id and e.release_id = o.release_id
  where b.id is null or e.id is null;
  if invalid_count > 0 then raise exception 'verification failed: invalid outbox identity'; end if;
  select count(*) into invalid_count
  from board_pulse.prc_release_documents d
  left join board_pulse.exams e on e.id = d.exam_id and e.release_id = d.release_id
  where d.exam_id is not null and e.id is null;
  if invalid_count > 0 then raise exception 'verification failed: invalid document identity'; end if;
  if exists (select 1 from pg_indexes where schemaname = 'board_pulse' and indexname = 'exams_source_article_url_key') then
    raise exception 'verification failed: legacy source URL index remains';
  end if;
  if exists (
    select 1 from information_schema.role_table_grants
    where table_schema = 'board_pulse' and table_name in ('prc_releases', 'prc_release_documents', 'release_batches', 'exam_ingestion_states', 'release_outbox', 'release_artifacts', 'exam_route_aliases', 'migration_manifests')
      and grantee in ('anon', 'authenticated') and privilege_type <> 'SELECT'
  ) then raise exception 'verification failed: public write grant remains'; end if;
  update board_pulse.migration_manifests
  set status = 'verified', updated_at = now()
  where migration_key = '20260914173053_combined_prc_tracks_sprint1'
    and payload ? 'releases' and payload ? 'exams' and payload ? 'documents'
    and payload ? 'batches' and payload ? 'ingestion_states';
  if not found then raise exception 'verification failed: migration manifest payload incomplete'; end if;
end;
$$;

notify pgrst, 'reload schema';
