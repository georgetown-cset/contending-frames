-- Getting counts of articles by year for economic gold rush frame
SELECT
  *
FROM (
-- We want the year and the count of every distinct article in that year
  SELECT
    year,
    COUNT(DISTINCT duplicateGroupId) AS count
  FROM
    `gcp-cset-projects.rhetorical_frames.economic_gold_rush`
  GROUP BY
    year
  ORDER BY
    year ASC) AS DATA
UNION DISTINCT (
-- 2013 is blank, let's add it in for a clean list
  SELECT
    2013 AS year,
    0 AS count
  FROM
    `gcp-cset-projects.rhetorical_frames.economic_gold_rush`)
ORDER BY
  1 ASC