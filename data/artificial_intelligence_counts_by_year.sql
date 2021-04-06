  -- Getting counts of articles by year for all AI articles
  -- We want the year and the count of every distinct article in that year
SELECT
  year,
  COUNT(DISTINCT duplicateGroupId) AS count
FROM
  `gcp-cset-projects.rhetorical_frames.artificial_intelligence`
GROUP BY
  year
ORDER BY
  year ASC