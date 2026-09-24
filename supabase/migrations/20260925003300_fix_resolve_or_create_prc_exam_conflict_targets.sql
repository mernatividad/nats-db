-- Avoid PL/pgSQL output-column shadowing in ON CONFLICT targets.
create or replace function board_pulse.resolve_or_create_prc_exam(
  p_canonical_article_url text, p_title text, p_slug text, p_scheduled_date date,
  p_track_key text, p_track_name text, p_parser_version text, p_source_version_hash text
)
returns table(exam_id uuid, release_id uuid)
language plpgsql security definer set search_path = board_pulse, pg_catalog, extensions
as $$
declare r board_pulse.prc_releases%rowtype; e board_pulse.exams%rowtype; canonical_url text;
begin
  if not board_pulse.is_official_prc_article_url(p_canonical_article_url) then
    raise exception using errcode = '22023', message = 'invalid_prc_exam_source_url';
  end if;
  canonical_url := board_pulse.canonicalize_prc_url(p_canonical_article_url);
  if canonical_url is null or btrim(p_title) = '' or btrim(p_slug) = '' or btrim(p_track_key) = '' or btrim(p_track_name) = ''
     or p_parser_version is null or p_source_version_hash !~ '^[0-9a-f]{64}$' then
    raise exception using errcode = '22023', message = 'invalid_prc_exam_identity';
  end if;
  insert into board_pulse.prc_releases(canonical_article_url, title, scheduled_date, latest_parser_version, source_version_hash)
  values(canonical_url, btrim(p_title), p_scheduled_date, btrim(p_parser_version), p_source_version_hash)
  on conflict (canonical_article_url) do nothing;
  select * into r from board_pulse.prc_releases where canonical_article_url = canonical_url for update;
  if r.latest_parser_version is distinct from btrim(p_parser_version) or r.source_version_hash is distinct from p_source_version_hash then
    raise exception using errcode = 'P0001', message = 'prc_release_provenance_conflict';
  end if;
  insert into board_pulse.release_batches(release_id, source_version_hash)
  values(r.id, p_source_version_hash)
  on conflict on constraint release_batches_release_hash_key do update set updated_at = now();
  if exists (
    select 1
    from board_pulse.exams ex
    where ex.source_article_url = canonical_url
      and ex.release_id is null
  ) then
    raise exception using errcode = '23514', message = 'parentless_exam_rejected';
  end if;
  insert into board_pulse.exams(release_id, name, slug, category, scheduled_date, source_article_url, track_key, track_name, track_status, validation_status, is_searchable)
  values(r.id, btrim(p_track_name), lower(btrim(p_slug)), btrim(p_track_name), coalesce(p_scheduled_date, r.scheduled_date, current_date), canonical_url, lower(btrim(p_track_key)), btrim(p_track_name), 'pending', 'unverified', false)
  on conflict on constraint exams_track_identity_key do update set name = excluded.name, track_name = excluded.track_name
  returning * into e;
  insert into board_pulse.exam_ingestion_states(release_id, track_key, parser_version, exam_id, expected_source_hash)
  values(r.id, lower(btrim(p_track_key)), btrim(p_parser_version), e.id, p_source_version_hash)
  on conflict on constraint exam_ingestion_states_pkey do update set exam_id = excluded.exam_id;
  return query select e.id, r.id;
end;
$$;

revoke all on function board_pulse.resolve_or_create_prc_exam(text, text, text, date, text, text, text, text) from public, anon, authenticated;
grant execute on function board_pulse.resolve_or_create_prc_exam(text, text, text, date, text, text, text, text) to service_role;

notify pgrst, 'reload schema';
