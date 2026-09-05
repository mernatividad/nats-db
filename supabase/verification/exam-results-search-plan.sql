-- Run against a production-like/staging database with the same schema and data volume
-- as the deployed search API. Do not run ANALYZE on production during peak traffic.
-- Replace the exam slug and tokens with representative exact, prefix, and punctuation queries.

explain (analyze, buffers, format json)
select *
from board_pulse.passer_search_index
where search_document ilike '%juan%'
  and search_document ilike '%cruz%'
  and exam_slug = 'replace-with-exam-slug'
  and is_topnotcher = false
order by result_release_date desc, full_name asc
limit 25 offset 0;

-- Acceptance evidence: capture planning time, execution time, rows removed by filter,
-- shared/local buffer usage, and whether the plan is index-backed rather than a broad scan.
