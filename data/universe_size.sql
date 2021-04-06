-- This query supports "we searched more than seven million articles on LexisNexis over the 2012 to 2020 period."
-- The count is 7,888,837.
select
  count(*) as n_records,
  count(distinct duplicateGroupId) as n_unique_articles,
from rhetorical_frames.lexisnexis_raw_news_2021_02_11
where
  extract(year from publishedDate) >= 2012
  and extract(year from publishedDate) <= 2020
  and (source.category = 'Press Wire'
     or source.category = 'National'
     or source.category = 'Trade')
  -- Exclude rank 3 here in an attempt to cut down on low-quality hits
  and source.editorialRank in (1, 2)
  and language = 'English'
  and source.location.country = 'United States'
