  -- Getting percentage of AI articles by year for killer robots frame
  -- We want the year and the percentage of AI articles with the killer robots frame in that year
WITH
  killer_robots_counter AS (
  -- Get the killer robots count
  SELECT
    year,
    -- Want to count duplicateGroupIds to distinct articles correctly
    COUNT(DISTINCT duplicateGroupId) AS killer_robot_count
  FROM
    `gcp-cset-projects.rhetorical_frames.killer_robots`
  GROUP BY
    year
  ORDER BY
    year ASC),
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
  killer_robots_counter.year,
  -- We just divide rather than multiplying by 100 -- it's easier to manipulate later
  killer_robot_count/ai_count as percent
FROM
  killer_robots_counter
INNER JOIN
  ai_counter
ON
  killer_robots_counter.year = ai_counter.year
  order by year