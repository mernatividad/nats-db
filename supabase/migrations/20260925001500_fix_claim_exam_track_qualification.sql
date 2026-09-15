create or replace function board_pulse.claim_exam_track(
  p_release_url text, p_track_key text, p_track_name text, p_slug text, p_scheduled_date date, p_parser_version text, p_batch_id uuid
)
returns table(release_id uuid, exam_id uuid, batch_id uuid, claim_status text, lease_owner uuid, lease_fencing_token bigint)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare r board_pulse.prc_releases%rowtype; e board_pulse.exams%rowtype; s board_pulse.exam_ingestion_states%rowtype; owner_id uuid; key text;
  batch_hash text; slug_value text; slug_suffix integer := 0;
begin
  key := lower(btrim(p_track_key));
  if key is null or key = '' or btrim(p_track_name) = '' or btrim(p_slug) = '' or p_parser_version is null then
    raise exception using errcode = '22023', message = 'invalid_claim_contract';
  end if;
  select * into r from board_pulse.prc_releases where canonical_article_url = board_pulse.canonicalize_prc_url(p_release_url) for update;
  if not found then raise exception using errcode = 'P0001', message = 'release_not_found'; end if;
  select source_version_hash into batch_hash from board_pulse.release_batches b
  where b.id = p_batch_id and b.release_id = r.id for update;
  if not found or batch_hash is distinct from r.source_version_hash then raise exception using errcode = 'P0001', message = 'batch_release_mismatch'; end if;
  select i.* into s from board_pulse.exam_ingestion_states i
  where i.release_id = r.id and i.track_key = key and i.parser_version = p_parser_version for update;
  if not found or not s.is_expected or r.latest_parser_version <> p_parser_version or s.expected_source_hash is distinct from batch_hash then
    raise exception using errcode = 'P0001', message = 'track_not_currently_expected';
  end if;
  slug_value := lower(btrim(p_slug));
  while exists (select 1 from board_pulse.exams x where x.slug = slug_value and not (x.release_id = r.id and x.track_key = key)) loop
    slug_suffix := slug_suffix + 1;
    slug_value := lower(btrim(p_slug)) || '-' || substr(md5(r.id::text || ':' || key), 1, 8) || case when slug_suffix = 1 then '' else '-' || slug_suffix::text end;
  end loop;
  insert into board_pulse.exams(release_id, name, slug, category, scheduled_date, source_article_url, track_key, track_name, track_status, validation_status, is_searchable)
  values(r.id, btrim(p_track_name), slug_value, btrim(p_track_name), coalesce(p_scheduled_date, r.scheduled_date, current_date), r.canonical_article_url, key, btrim(p_track_name), 'pending', 'validating', false)
  on conflict on constraint exams_track_identity_key do update set name = excluded.name, track_name = excluded.track_name
  returning * into e;
  if s.exam_id is not null and s.exam_id <> e.id then raise exception using errcode = '23514', message = 'track_exam_mismatch'; end if;
  update board_pulse.exam_ingestion_states i3 set exam_id = e.id where i3.release_id = r.id and i3.track_key = key and i3.parser_version = p_parser_version;
  if s.state = 'published' and s.expected_source_hash = batch_hash then
    return query select r.id as release_id, e.id as exam_id, p_batch_id as batch_id, 'already_published', null::uuid as lease_owner, s.lease_fencing_token as lease_fencing_token; return;
  end if;
  if s.state = 'processing' and s.lease_until > now() then
    return query select r.id as release_id, e.id as exam_id, p_batch_id as batch_id, 'already_processing', s.lease_owner as lease_owner, s.lease_fencing_token as lease_fencing_token; return;
  end if;
  owner_id := extensions.gen_random_uuid();
  update board_pulse.exam_ingestion_states i4 set state = 'processing', attempt_count = i4.attempt_count + 1, lease_owner = owner_id,
    lease_fencing_token = i4.lease_fencing_token + 1, lease_until = now() + interval '15 minutes', last_error = null, updated_at = now()
  where i4.release_id = r.id and i4.track_key = key and i4.parser_version = p_parser_version
  returning * into s;
  update board_pulse.exams set track_status = 'processing', validation_status = 'validating' where id = e.id;
  return query select r.id as release_id, e.id as exam_id, p_batch_id as batch_id, 'claimed', owner_id as lease_owner, s.lease_fencing_token as lease_fencing_token;
end;
$$;

revoke all on function board_pulse.claim_exam_track(text, text, text, text, date, text, uuid) from public, anon, authenticated;
grant execute on function board_pulse.claim_exam_track(text, text, text, text, date, text, uuid) to service_role;
notify pgrst, 'reload schema';
