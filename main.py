import datetime

import pandas as pd

from bq import make_table
from settings import DATASET_ID, PROJECT_ID, ANALYSIS_DIR

TODAY_STAMP = datetime.date.today().isoformat()


def main():
    table_name = "competition"
    make_table(table_name, clobber=True)
    summarize_by_year(table_name)
    summarize_percent_ai_by_year(table_name)
    summarize_by_source(table_name)
    summarize_by_person_mention(table_name)
    summarize_by_author(table_name)
    summarize_by_organization_mention(table_name)


def summarize_by_source(table_name):
    # Get counts of articles by publishing source
    sql = f"""\
        SELECT
        -- We want the publishing source and every distinct article published by that source
          source_name,
          COUNT(DISTINCT duplicateGroupId) AS count
        FROM
          `{PROJECT_ID}.{DATASET_ID}.{table_name}`
        GROUP BY
         source_name 
        ORDER BY
          count DESC
    """
    df = _query_and_save(sql, table_name, "by_source")
    return df


def summarize_by_year(table_name) -> pd.DataFrame:
    sql = f"""\
      SELECT
        year,
        COUNT(DISTINCT duplicateGroupId) AS count,
        COUNT(DISTINCT duplicateGroupId) / SUM(COUNT(DISTINCT duplicateGroupId)) OVER () AS percent
      FROM
        `{PROJECT_ID}.{DATASET_ID}.{table_name}`
      GROUP BY
        year
      ORDER BY
        year ASC
    """
    df = _query_and_save(sql, table_name, "by_year")
    return df


def summarize_percent_ai_by_year(table_name) -> pd.DataFrame:
    sql = """\
    -- We want the year and the percentage of AI articles with the competition frame in that year
    WITH
      counter AS (
      -- Get the frame-specific count
      SELECT
        year,
        -- Want to count duplicateGroupIds to distinct articles correctly
        COUNT(DISTINCT duplicateGroupId) AS n
      FROM
        `gcp-cset-projects.rhetorical_frames.competition`
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
      counter.year,
      -- We just divide rather than multiplying by 100 -- it's easier to manipulate later
      n/ai_count AS percent
    FROM
      counter
    INNER JOIN
      ai_counter
    ON
      counter.year = ai_counter.year
      ORDER BY year
    """
    df = _query_and_save(sql, table_name, "percent_ai_by_year")
    return df


def summarize_by_person_mention(table_name) -> pd.DataFrame:
    sql = f"""\
    -- Getting counts of how many distinct articles mention different people
    SELECT
    -- Semantic.value contains the names of the person mentioned
      temp_semantic.value,
      -- Counting distinct articles containing mentions
      COUNT(DISTINCT duplicateGroupId) AS count
    FROM
       `{PROJECT_ID}.{DATASET_ID}.{table_name}`,
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
      count DESC
    
    """
    df = _query_and_save(sql, table_name, "by_person_mention")
    return df


def summarize_by_author(table_name):
    sql = f"""\
    SELECT
      author,
      COUNT(DISTINCT duplicateGroupId) AS count
    FROM
       `{PROJECT_ID}.{DATASET_ID}.{table_name}`
    GROUP BY
      author
    ORDER BY
      count DESC
    """
    df = _query_and_save(sql, table_name, "by_author")
    return df


def summarize_by_organization_mention(table_name):
    # Getting counts of how many distinct articles mention different organizations
    # We use both company and organization here because the distinction here isn't always a clear line
    sql = f"""\
    WITH
      orgs AS (
      SELECT
        -- Semantic.value contains the names of the organizations mentioned
        LOWER(temp_semantic.value) AS organization,
        -- Counting distinct articles containing mentions
        COUNT(DISTINCT duplicateGroupId) AS count
      FROM
        `{PROJECT_ID}.{DATASET_ID}.{table_name}`,
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
        """
    df = _query_and_save(sql, table_name, "by_organization_mention")
    return df


def _query_and_save(sql, table_name, save_suffix):
    df = pd.read_gbq(sql, project_id=PROJECT_ID)
    df.to_csv(ANALYSIS_DIR / f"{table_name}_{save_suffix}_{TODAY_STAMP}.csv", index=False)
    return df


if __name__ == '__main__':
    main()
