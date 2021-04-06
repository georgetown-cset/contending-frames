  -- Getting counts of articles by year for killer robots frame
  -- We want the year and the count of every distinct article in that year
SELECT
  year,
  COUNT(DISTINCT duplicateGroupId) AS count
FROM
  `gcp-cset-projects.rhetorical_frames.killer_robots`
GROUP BY
  year
ORDER BY
  year ASC