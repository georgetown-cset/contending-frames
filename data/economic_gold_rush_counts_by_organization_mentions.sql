  -- Getting counts of how many distinct articles mention different organizations for the economic gold rush frame.
  -- We use both company and organization here because the distinction here isn't always a clear line.
WITH
  orgs AS (
  SELECT
    -- Semantic.value contains the names of the organizations mentioned
    LOWER(temp_semantic.value) AS organization,
    -- Counting distinct articles containing mentions
    COUNT(DISTINCT duplicateGroupId) AS count
  FROM
    `gcp-cset-projects.rhetorical_frames.economic_gold_rush`,
    -- We want to unnest the semantic info array so we have every row of it and can get the row with the "value" name in it
    UNNEST(semantic_info) AS temp_semantic
    -- We also want to cross join so we can specifically pull in only the semantic info arrays that have "Organization" values
  CROSS JOIN
    UNNEST(semantic_info) AS semantic
  WHERE
    -- Using both company and organization
    (semantic.value = "Organization"
      OR semantic.value = "Company")
    AND temp_semantic.name = "value"
  GROUP BY
    1)
SELECT
  -- Adding in aliases from both high resolution organizations and grid
  CASE
    WHEN alias_tab.name IS NOT NULL THEN alias_tab.name
    WHEN grid_alias.alias IS NOT NULL
  AND api_grid.name IS NOT NULL THEN api_grid.name
  ELSE
  organization
END
  AS organization,
  -- Combining counts of all organizations with the same alias
  SUM(count) AS count
FROM
  orgs
  -- Pulling in aliases from high resolution entities
LEFT JOIN (
  SELECT
    DISTINCT name,
    alias_list.alias
  FROM
    high_resolution_entities.organizations
  CROSS JOIN
    UNNEST(aliases) AS alias_list) AS alias_tab
    -- Joining any organization name that matches an alias
ON
  (orgs.organization = alias_tab.alias)
  -- Adding in the grid aliases data
LEFT JOIN (
  SELECT
    grid_id,
    alias
  FROM
    gcp_cset_grid.grid_aliases) AS grid_alias
    -- Joining any organization name matching a grid alias
ON
  orgs.organization = grid_alias.alias
  -- Adding in the api_grid table so we can get the canonical names of the grid aliases
LEFT JOIN (
  SELECT
    id,
    name
  FROM
    gcp_cset_grid.api_grid) AS api_grid
ON
  api_grid.id = grid_alias.grid_id
GROUP BY
  1
ORDER BY
  2 DESC