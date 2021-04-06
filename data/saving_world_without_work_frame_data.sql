  -- Creating a new, smaller table with only world without work frame articles and the columns of interest
CREATE OR REPLACE TABLE
  rhetorical_frames.world_without_work AS
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
    REGEXP_CONTAINS(LOWER(text), r'(displace.{0,20}job.{0,20}\bai\b)') AS displace_job_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}displace.*job)') AS ai_displace_job,
    REGEXP_CONTAINS(LOWER(text), r'(replace.{0,20}job.{0,20}\bai\b)') AS replace_job_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}replace.{0,20}job)') AS ai_replace_job,
    REGEXP_CONTAINS(LOWER(text), r'(obsolete.{0,20}\bai\b)') AS obsolete_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}obsolete)') AS ai_obsolete,
    REGEXP_CONTAINS(LOWER(text), r'(automation.{0,20}job)') AS automation_job,
    REGEXP_CONTAINS(LOWER(text), r'(automate.{0,20}job)') AS automate_job,
    REGEXP_CONTAINS(LOWER(text), r'(job.{0,20}automation)') AS job_automation,
    REGEXP_CONTAINS(LOWER(text), r'(job.{0,20}automate)') AS job_automate,
    REGEXP_CONTAINS(LOWER(text), r'(global useless class)') AS global_useless_class,
    REGEXP_CONTAINS(LOWER(text), r'(employment.?polarization)') AS employment_polarization,
    REGEXP_CONTAINS(LOWER(text), r'(livelihoods)') AS livelihoods,
    REGEXP_CONTAINS(LOWER(text), r'(compensation)') AS compensation,
    REGEXP_CONTAINS(LOWER(text), r'(mass joblessness)') AS mass_joblessness,
    REGEXP_CONTAINS(LOWER(text), r'(out of a job)') AS out_of_job,
    REGEXP_CONTAINS(LOWER(text), r'(robot apocalypse)') AS robot_apocalypse,
    REGEXP_CONTAINS(LOWER(text), r'(unemploy)') AS unemploy,
    REGEXP_CONTAINS(LOWER(text), r'(fourth.?industrial.?revolution)') AS fourth_industrial_revolution,
    REGEXP_CONTAINS(LOWER(text), r'(unions?)') AS unions,
    REGEXP_CONTAINS(LOWER(text), r'(jobless.?recovery)') AS jobless_recovery,
    REGEXP_CONTAINS(LOWER(text), r'(reskill)') AS reskill,
    REGEXP_CONTAINS(LOWER(text), r'(winners and losers)') AS winners_losers,
    REGEXP_CONTAINS(LOWER(text), r'(blue.?collar)') AS blue_collar,
    REGEXP_CONTAINS(LOWER(text), r'(white.?collar)') AS white_collar,
    REGEXP_CONTAINS(LOWER(text), r'(jobs.?eliminated)') AS jobs_eliminated,
    REGEXP_CONTAINS(LOWER(text), r'(steal.?jobs?)') AS steal_jobs,
    REGEXP_CONTAINS(LOWER(text), r'(coming for y?our job)') AS coming_for_job,
    REGEXP_CONTAINS(LOWER(text), r'(take y?our job)') AS take_job,
    REGEXP_CONTAINS(LOWER(text), r'(job killer)') AS job_killer,
    REGEXP_CONTAINS(LOWER(text), r'(threaten.{0,20}jobs?)') AS threaten_jobs,
    REGEXP_CONTAINS(LOWER(text), r'(job.{0,20}extinct)') AS job_extinct,
    text
  FROM
    ln
    -- Require a mention of AI somewhere
  WHERE
    REGEXP_CONTAINS(LOWER(ln.text), r"\bai\b|artificial intelligence\b") ),
  hits AS (
    -- Select docs with matches from the analytic corpus
  SELECT
    *
  FROM
    keywords
  WHERE
    keywords.global_useless_class
    OR keywords.employment_polarization
    OR keywords.take_job
    OR keywords.job_killer
    OR (keywords.displace_job_ai
      OR keywords.ai_displace_job
      OR keywords.replace_job_ai
      OR keywords.ai_replace_job
      OR keywords.obsolete_ai
      OR keywords.ai_obsolete
      OR keywords.automation_job
      OR keywords.automate_job
      OR keywords.job_automation
      OR keywords.job_automate
      OR keywords.mass_joblessness
      OR keywords.out_of_job
      OR keywords.unemploy
      OR keywords.jobless_recovery
      OR keywords.jobs_eliminated
      OR keywords.steal_jobs
      OR keywords.threaten_jobs
      OR keywords.job_extinct
      OR keywords.coming_for_job)
    AND ( keywords.livelihoods
      OR keywords.compensation
      OR keywords.robot_apocalypse
      OR keywords.fourth_industrial_revolution
      OR keywords.reskill
      OR keywords.winners_losers
      OR keywords.blue_collar
      OR keywords.white_collar) )
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