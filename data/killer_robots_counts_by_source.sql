-- Getting counts of the articles by publishing source for the killer robots frame
SELECT
-- We want the publishing source and every distinct article published by that source
  source_name,
  COUNT(DISTINCT duplicateGroupId) AS count
FROM
  `gcp-cset-projects.rhetorical_frames.killer_robots`
GROUP BY
  1
ORDER BY
  2 DESC