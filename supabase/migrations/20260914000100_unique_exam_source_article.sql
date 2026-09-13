create unique index if not exists exams_source_article_url_key
  on board_pulse.exams (source_article_url)
  where source_article_url is not null;
