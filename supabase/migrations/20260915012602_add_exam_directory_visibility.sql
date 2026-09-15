-- Aggregate/legacy exam rows remain useful for release coordination, but they
-- are not user-facing records once a release has canonical track rows.
alter table board_pulse.exams
  add column if not exists display_in_directory boolean not null default true;

-- Hide only aggregate rows that have no published result rows of their own and
-- share a release with a sibling that does. This is deliberately data-driven
-- so ordinary single-track legacy records remain visible.
update board_pulse.exams e
set display_in_directory = false,
    updated_at = now()
where e.display_in_directory
  and exists (
    select 1
    from board_pulse.exams sibling
    where sibling.release_id = e.release_id
      and sibling.id <> e.id
      and exists (select 1 from board_pulse.results r where r.exam_id = sibling.id)
  )
  and not exists (select 1 from board_pulse.results r where r.exam_id = e.id);

create index if not exists exams_directory_visibility_idx
  on board_pulse.exams (display_in_directory, scheduled_date desc);
