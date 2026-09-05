-- Fix top_notchers upsert conflict resolution
-- Remove the (exam_id, rank) unique index that conflicts with upsert on (exam_id, full_name)
-- Keep only (exam_id, full_name) constraint, allowing rank to update when the same person appears with different rank

drop index if exists board_pulse.top_notchers_exam_rank_key;

-- Optional: keep a non-unique index on rank for query performance
create index if not exists top_notchers_exam_rank_idx on board_pulse.top_notchers (exam_id, rank);
