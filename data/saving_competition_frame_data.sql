 -- Creating a new, smaller table with only competition frame articles and the columns of interest
CREATE OR REPLACE TABLE
  rhetorical_frames.competition AS
WITH
  ln AS (
    -- Select analytic corpus
  SELECT
    id,
    -- This lets us deduplicate articles that are almost identical but published multiple places etc.
    duplicateGroupId,
    title,
    subTitle,
    content,
    matchingKeywords,
    -- NER info
    entities.properties AS semantic_info,
    -- Author data
    author.name AS author,
    EXTRACT(year
    FROM
      publishedDate) AS year,
    -- The publisher/source
    source.name AS source_name,
    url,
    LOWER(coalesce(title, "") || " " || coalesce(subTitle, "") || " " || coalesce(content, "")) AS text
  FROM
    gcp_cset_lexisnexis.raw_news
  CROSS JOIN
    UNNEST(semantics.entities) AS entities
  WHERE
    EXTRACT(year FROM publishedDate) >= 2012
    AND EXTRACT(year FROM publishedDate) <= 2020
    AND (source.category = 'Press Wire'
      OR source.category = 'National'
      OR source.category = 'Trade')
    -- I excluded rank 3 here in an attempt to cut down on low-quality hits
    AND source.editorialRank IN (1, 2)
    AND
    LANGUAGE = 'English'
    AND source.location.country = 'United States' ),
  keywords AS (
    -- Add columns indicating whether text matched various patterns
  SELECT
    id,
    duplicateGroupId,
    title,
    url,
    author,
    matchingKeywords,
    semantic_info,
    year,
    source_name,
    -- We'll require a mention of AI *somewhere* in the text for these keywords, but it can be anywhere
    REGEXP_CONTAINS(ln.text, r"\bsputnik\b") AS sputnik,
    REGEXP_CONTAINS(ln.text, r"\bforeign adversar\w*\b") AS foreign_adversary,
    -- These keywords can follow or precede a mention of AI within a given number of characters
    REGEXP_CONTAINS(ln.text, r"\b(ai|artificial intelligence).{0,20}arms race\b") AS ai_arms_race,
    REGEXP_CONTAINS(ln.text, r"\barms race.{0,20}(ai|artificial intelligence)\b") AS arms_race_ai,
    REGEXP_CONTAINS(ln.text, r"\b(ai|artificial intelligence).{0,20}(battl\w*|compet\w*|conflict|rival\w*|war)\b") AS ai_conflict,
    REGEXP_CONTAINS(ln.text, r"\b(battl\w*|compet\w*|conflict|rival\w*|war).{0,20}(ai|artificial intelligence)\b") AS conflict_ai,
    REGEXP_CONTAINS(ln.text, r"\b(ai|artificial intelligence).{0,20}(dominance|domination|supremacy|superiority|leadership|leading)\b") AS ai_dominance,
    REGEXP_CONTAINS(ln.text, r"\b(dominance|domination|supremacy|superiority|leadership|leading).{0,20}(ai|artificial intelligence)\b") AS dominance_ai,
    REGEXP_CONTAINS(ln.text, r"\b(ai|artificial intelligence).{0,20}strategic advantage\b") AS ai_strategic_advantage,
    REGEXP_CONTAINS(ln.text, r"\bstrategic advantage.{0,20}(ai|artificial intelligence)\b") AS strategic_advantage_ai,
    REGEXP_CONTAINS(ln.text, r"\b(ai|artificial intelligence).{0,20}(outpac\w*|overtak\w*)\b") AS ai_outpace,
    REGEXP_CONTAINS(ln.text, r"\b(outpac\w*|overtak\w*).{0,20}(ai|artificial intelligence)\b") AS outpace_ai,
    text
  FROM
    ln
    -- Require a mention of AI somewhere
  WHERE
    REGEXP_CONTAINS(ln.text, r"\b(ai|artificial intelligence)\b") ),
  hits AS (
    -- Select docs with matches from the analytic corpus
  SELECT
    *
  FROM
    keywords
  WHERE
    sputnik
    OR foreign_adversary
    OR (ai_arms_race
      OR arms_race_ai)
    OR (ai_conflict
      OR conflict_ai)
    OR (ai_dominance
      OR dominance_ai)
    OR (ai_strategic_advantage
      OR strategic_advantage_ai)
    OR (ai_outpace
      OR outpace_ai) )
SELECT
  -- Save off the results
  id,
  duplicateGroupId,
  title,
  url,
  year,
  source_name,
  author,
  semantic_info
FROM
  hits