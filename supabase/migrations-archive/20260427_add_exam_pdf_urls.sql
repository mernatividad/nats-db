alter table board_pulse.exams
  add column if not exists passers_pdf_url text,
  add column if not exists top_notchers_pdf_url text;
