  -- Getting percentage of AI articles by year for economic gold rush frame
  -- We want the year and the percentage of AI articles with the economic gold rush frame in that year
WITH
  economic_gold_rush_counter AS (-- Getting counts of articles by year for economic gold rush frame
  SELECT
    *
  FROM (
      -- We want the year and the count of every distinct article in that year
    SELECT
      year,
      COUNT(DISTINCT duplicateGroupId) AS economic_gold_rush_count
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
      0 AS economic_gold_rush_count
    FROM
      `gcp-cset-projects.rhetorical_frames.economic_gold_rush`)
  ORDER BY
    1 ASC),
  ai_counter AS (
    -- Get the count of all AI articles
  SELECT
    year,
    -- Want to count duplicateGroupIds to distinct articles correctly
    COUNT(DISTINCT duplicateGroupId) AS ai_count
  FROM
    `gcp-cset-projects.rhetorical_frames.artificial_intelligence`
  GROUP BY
    year
  ORDER BY
    year ASC)
SELECT
  economic_gold_rush_counter.year,
  -- We just divide rather than multiplying by 100 -- it's easier to manipulate later
  economic_gold_rush_count/ai_count AS percent
FROM
  economic_gold_rush_counter
INNER JOIN
  ai_counter
ON
  economic_gold_rush_counter.year = ai_counter.year
ORDER BY
  year