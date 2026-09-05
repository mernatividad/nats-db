drop index if exists top_notchers_exam_rank_key;

create index if not exists top_notchers_exam_rank_idx
  on public.top_notchers (exam_id, rank);
