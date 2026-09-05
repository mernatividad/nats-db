create or replace function board_pulse.moderate_review_center(
  p_entity text, p_entity_id uuid, p_action text, p_expected_updated_at timestamptz default null,
  p_payload jsonb default '{}'::jsonb, p_actor text default 'system', p_comment text default null
) returns jsonb language plpgsql set search_path = board_pulse, public as $$
declare current_center board_pulse.review_centers%rowtype; current_status text; next_status text; audit_details jsonb; audit_center_id uuid;
begin
  if p_entity = 'center' then
    select * into current_center from board_pulse.review_centers where id = p_entity_id for update;
    if not found then raise exception using errcode = 'P0002', message = 'center_not_found'; end if;
    if p_expected_updated_at is not null and current_center.updated_at <> p_expected_updated_at then raise exception using errcode = 'P0009', message = 'concurrent_update'; end if;
    if p_action = 'save' then
      update board_pulse.review_centers set name = p_payload->>'name', slug = p_payload->>'slug', description = p_payload->>'description', website_url = nullif(p_payload->>'websiteUrl', ''), enrollment_url = nullif(p_payload->>'enrollmentUrl', ''), email = nullif(p_payload->>'email', ''), phone = nullif(p_payload->>'phone', ''), social_links = coalesce(p_payload->'socialLinks', '{}'::jsonb), claim_state = p_payload->>'claimState', last_confirmed_at = nullif(p_payload->>'lastConfirmedAt', '')::timestamptz where id = p_entity_id;
      delete from board_pulse.review_center_professions where review_center_id = p_entity_id;
      insert into board_pulse.review_center_professions (review_center_id, profession) select p_entity_id, value from jsonb_array_elements_text(coalesce(p_payload->'professions', '[]'::jsonb));
      delete from board_pulse.review_center_locations where review_center_id = p_entity_id;
      insert into board_pulse.review_center_locations (review_center_id, city, area, format) select p_entity_id, item->>'city', nullif(item->>'area', ''), item->>'format' from jsonb_array_elements(coalesce(p_payload->'locations', '[]'::jsonb)) item;
    else
      next_status := p_action;
      if next_status not in ('draft', 'pending_review', 'published', 'needs_update', 'archived') then raise exception using errcode = 'P0001', message = 'invalid_status'; end if;
      if not ((current_center.status = 'draft' and next_status = 'pending_review') or (current_center.status = 'pending_review' and next_status in ('published','needs_update','archived')) or (current_center.status = 'published' and next_status in ('needs_update','archived')) or (current_center.status = 'needs_update' and next_status in ('pending_review','archived')) or (current_center.status = 'archived' and next_status = 'draft')) then raise exception using errcode = 'P0001', message = 'invalid_transition'; end if;
      if next_status = 'published' and (length(trim(current_center.name)) < 2 or length(trim(current_center.slug)) < 2 or length(trim(current_center.description)) < 20 or (nullif(trim(current_center.website_url), '') is null and nullif(trim(current_center.email), '') is null and nullif(trim(current_center.phone), '') is null) or not exists (select 1 from board_pulse.review_center_professions where review_center_id = p_entity_id) or not exists (select 1 from board_pulse.review_center_locations where review_center_id = p_entity_id)) then raise exception using errcode = 'P0010', message = 'publish_gate_failed'; end if;
      update board_pulse.review_centers set status = next_status where id = p_entity_id;
    end if;
    audit_center_id := p_entity_id;
    select status into current_status from board_pulse.review_centers where id = p_entity_id;
  elsif p_entity = 'claim' then
    select status, review_center_id into current_status, audit_center_id from board_pulse.review_center_claims where id = p_entity_id for update;
    if not found then raise exception using errcode = 'P0002', message = 'claim_not_found'; end if;
    if not ((current_status = 'submitted' and p_action = 'under_review') or (current_status = 'under_review' and p_action in ('approved','rejected'))) then raise exception using errcode = 'P0001', message = 'invalid_transition'; end if;
    update board_pulse.review_center_claims set status = p_action, reviewed_at = now() where id = p_entity_id;
  elsif p_entity = 'submission' then
    select status into current_status from board_pulse.review_center_submissions where id = p_entity_id for update;
    if not found then raise exception using errcode = 'P0002', message = 'submission_not_found'; end if;
    if not ((current_status = 'submitted' and p_action = 'under_review') or (current_status = 'under_review' and p_action in ('approved','rejected'))) then raise exception using errcode = 'P0001', message = 'invalid_transition'; end if;
    update board_pulse.review_center_submissions set status = p_action, reviewed_at = now() where id = p_entity_id;
  elsif p_entity = 'report' then
    select status, review_center_id into current_status, audit_center_id from board_pulse.review_center_reports where id = p_entity_id for update;
    if not found then raise exception using errcode = 'P0002', message = 'report_not_found'; end if;
    if not ((current_status = 'open' and p_action = 'under_review') or (current_status = 'under_review' and p_action in ('resolved','dismissed'))) then raise exception using errcode = 'P0001', message = 'invalid_transition'; end if;
    update board_pulse.review_center_reports set status = p_action, resolved_at = case when p_action in ('resolved','dismissed') then now() else null end where id = p_entity_id;
  else raise exception using errcode = 'P0001', message = 'invalid_entity'; end if;
  audit_details := jsonb_build_object('action', p_action, 'previous_status', current_status, 'new_status', case when p_action = 'save' then current_status else p_action end);
  if p_comment is not null and length(trim(p_comment)) > 0 then audit_details := audit_details || jsonb_build_object('comment', trim(p_comment)); end if;
  insert into board_pulse.review_center_audit_events (review_center_id, entity_type, entity_id, action, actor, details) values (audit_center_id, p_entity, p_entity_id, p_action, p_actor, audit_details);
  return jsonb_build_object('ok', true, 'entity', p_entity, 'id', p_entity_id);
end; $$;

revoke all on function board_pulse.moderate_review_center(text, uuid, text, timestamptz, jsonb, text, text) from public, anon, authenticated;
grant execute on function board_pulse.moderate_review_center(text, uuid, text, timestamptz, jsonb, text, text) to service_role;
