-- Getting counts of how many distinct articles mention different people for the killer robots frame
SELECT
-- Semantic.value contains the names of the person mentioned
  temp_semantic.value,
  -- Counting distinct articles containing mentions
  COUNT(DISTINCT duplicateGroupId) AS count
FROM
  `gcp-cset-projects.rhetorical_frames.killer_robots`,
  -- We want to unnest the semantic info array so we have every row of it and can get the row with the "value" name in it
  UNNEST(semantic_info) AS temp_semantic
  -- We also want to cross join so we can specifically pull in only the semantic info arrays that have "Person" values
CROSS JOIN
  UNNEST(semantic_info) AS semantic
WHERE
  semantic.value = "Person"
  AND temp_semantic.name = "value"
GROUP BY
  temp_semantic.value
ORDER BY
  2 DESC