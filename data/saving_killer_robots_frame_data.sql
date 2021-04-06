  -- Creating a new, smaller table with only killer robots frame articles and the columns of interest
CREATE OR REPLACE TABLE
  rhetorical_frames.killer_robots AS
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
    source.name AS source_name,
    url,
    LOWER(coalesce(title,
        "") || " " || coalesce(subTitle,
        "") || " " || coalesce(content,
        "")) AS text
  FROM
    gcp_cset_lexisnexis.raw_news,
    UNNEST(semantics.entities) AS entities
  WHERE
    EXTRACT(year
    FROM
      publishedDate) >= 2012
    AND EXTRACT(year
    FROM
      publishedDate) <= 2020
    AND (source.category = 'Press Wire'
      OR source.category = 'National'
      OR source.category = 'Trade')
    -- I excluded rank 3 here in an attempt to cut down on low-quality hits
    AND source.editorialRank IN (1,
      2)
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
    REGEXP_CONTAINS(LOWER(text), r'(lethal.?autonomous.?weapons?)') AS lethal_aut_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(fully.?autonomous.?weapons?)') AS fully_aut_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(slaughterbots?)') AS slaughterbots,
    REGEXP_CONTAINS(LOWER(text), r'(international.?humanitarian.?law)') AS intl_human_law,
    REGEXP_CONTAINS(LOWER(text), r'(laws?.?of.?war)') AS laws_of_war,
    REGEXP_CONTAINS(LOWER(text), r'(killer.?robots?)') AS killer_robots,
    REGEXP_CONTAINS(LOWER(text), r'(meaningful.?human.?control)') AS meaningful_human_control,
    REGEXP_CONTAINS(LOWER(text), r'(retaining.?human.?control)') AS retaining_human_control,
    REGEXP_CONTAINS(LOWER(text), r'(campaign to stop killer robots?)') AS campaign_stop_killer_bots,
    REGEXP_CONTAINS(LOWER(text), r'(international committee for robot arms control)') AS intl_committee_robot_arms_cntl,
    REGEXP_CONTAINS(LOWER(text), r'(threat.?to.?humanity)') AS threat_to_human,
    REGEXP_CONTAINS(LOWER(text), r'(martens clause)') AS martens_clause,
    REGEXP_CONTAINS(LOWER(text), r'(convention on conventional weapons)') AS convent_con_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(autonomy)') AS autonomy,
    REGEXP_CONTAINS(LOWER(text), r'(semi.?autonomous weapons?.?systems)') AS semi_aut_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(autonomous.?weapons?)') AS aut_weapon,
    REGEXP_CONTAINS(LOWER(text), r'(dod directive 3000.?09)') AS dod_directive,
    REGEXP_CONTAINS(LOWER(text), r'(existential.?risk)') AS existential_risk,
    REGEXP_CONTAINS(LOWER(text), r'(prohibition.{0,20}\bai\b)') AS prohibition_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}prohibition)') AS ai_prohibition,
    REGEXP_CONTAINS(LOWER(text), r'(\bban\b.{0,20}\bai\b)') AS ban_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}\bban\b)') AS ai_ban,
    text
  FROM
    ln
    -- Require a mention of AI somewhere
  WHERE
    REGEXP_CONTAINS(ln.text, r"\bai\b|artificial intelligence\b") ),
  hits AS (
    -- Select docs with matches from the analytic corpus
  SELECT
    *
  FROM
    keywords
  WHERE
    lethal_aut_weapons
    OR fully_aut_weapons
    OR slaughterbots
    OR keywords.intl_human_law
    OR keywords.laws_of_war
    OR keywords.killer_robots
    OR keywords.meaningful_human_control
    OR keywords.retaining_human_control
    OR keywords.campaign_stop_killer_bots
    OR keywords.intl_committee_robot_arms_cntl
    OR keywords.threat_to_human
    OR keywords.martens_clause
    OR keywords.convent_con_weapons
    OR keywords.aut_weapon
    OR keywords.dod_directive
    OR keywords.existential_risk )
SELECT
  -- Summarize the results
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