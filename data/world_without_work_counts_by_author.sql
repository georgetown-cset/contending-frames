  -- Counting authors in world without work frame by how many distinct articles they've written. We're not bothering to try to split authors using SQL,
  -- because the data is too messy. There are authors split by semicolons, authors split by commas, authors with commas separating
  -- their last and first names, authors with commas separating their first names and affiliations, authors with "by" before their
  -- names, "authors" that are actually affiliations, "authors" that are actually email addresses, etc. We'll handle in Python.
  -- Also, we aren't removing nulls because we want to know how many articles are missing author information.
SELECT
  LOWER(author) AS author,
  COUNT(DISTINCT duplicateGroupId) AS count
FROM
  `gcp-cset-projects.rhetorical_frames.world_without_work`
GROUP BY
  author
ORDER BY
  2 DESC