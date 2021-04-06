  -- Getting counts of articles by year for world without work frame
  -- We want the year and the count of every distinct article in that year
SELECT
  year,
  COUNT(DISTINCT duplicateGroupId) AS count
FROM
  `gcp-cset-projects.rhetorical_frames.world_without_work`
GROUP BY
  year
ORDER BY
  year ASC