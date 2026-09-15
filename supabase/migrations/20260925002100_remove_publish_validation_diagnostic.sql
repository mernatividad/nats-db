drop function if exists board_pulse.diagnose_publish_exam_track(uuid, uuid, text, jsonb);

notify pgrst, 'reload schema';
