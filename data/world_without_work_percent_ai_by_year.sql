  -- Getting percentage of AI articles by year for world without work frame
  -- We want the year and the percentage of AI articles with the world without work frame in that year
WITH
  world_without_work_counter AS (
  -- Get the world without work count
  SELECT
    year,
    -- Want to count duplicateGroupIds to distinct articles correctly
    COUNT(DISTINCT duplicateGroupId) AS world_without_work_count
  FROM
    `gcp-cset-projects.rhetorical_frames.world_without_work`
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
  world_without_work_counter.year,
  -- We just divide rather than multiplying by 100 -- it's easier to manipulate later
  world_without_work_count/ai_count as percent
FROM
  world_without_work_counter
INNER JOIN
  ai_counter
ON
  world_without_work_counter.year = ai_counter.year
  order by year